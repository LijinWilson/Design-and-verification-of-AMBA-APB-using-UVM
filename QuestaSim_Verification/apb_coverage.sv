// apb_coverage.sv - functional + control coverage for APB slave
// Gets every transaction from the monitor through the analysis port

class apb_coverage extends uvm_subscriber #(apb_trans);
  `uvm_component_utils(apb_coverage)

  apb_trans tx;                          // transaction being sampled

  // history used for control scenarios
  bit                   prev_wr_ok;      // previous transfer was a good write
  bit [`ADDR_WIDTH-1:0] prev_addr;       // address of previous transfer
  bit                   data_in_mem;     // a write happened since last reset
  bit                   first_after_rst; // next transfer is first after reset
  bit                   b2b_wr_rd;       // read right after write, same address
  bit                   rd_after_rst;    // first transfer after reset is a read
  bit                   rst_after_wr;    // reset came when memory had data

  // ---------------- data coverage: one coverpoint per signal ----------------
  covergroup cg_data;
    option.per_instance = 1;

    // PADDR: 8 valid locations (one bin each) + reserved range
    cp_addr : coverpoint tx.PADDR {
      bins valid[]  = {[0:`MEM_DEPTH-1]};
      bins reserved = {[`MEM_DEPTH:255]};
    }

    // PADDR inside reserved range: low half and high half
    cp_rsv : coverpoint tx.PADDR iff (tx.PADDR >= `MEM_DEPTH) {
      bins rsv_low  = {[`MEM_DEPTH:127]};
      bins rsv_high = {[128:255]};
    }

    // PWRITE: read / write
    cp_rw : coverpoint tx.PWRITE {
      bins rd_op = {0};
      bins wr_op = {1};
    }

    // PWDATA: only for good writes
    cp_wdata : coverpoint tx.PWDATA iff (tx.PWRITE && !tx.PSLVERR) {
      bins low  = {[0:85]};
      bins mid  = {[86:170]};
      bins high = {[171:255]};
    }

    // PRDATA: only for good reads
    cp_rdata : coverpoint tx.PRDATA iff (!tx.PWRITE && !tx.PSLVERR) {
      bins zero = {0};
      bins low  = {[1:127]};
      bins high = {[128:255]};
    }

    // PSLVERR: error response
    cp_err : coverpoint tx.PSLVERR {
      bins no_err = {0};
      bins err    = {1};
    }

    // PREADY: monitor only publishes completed transfers, so only 1
    cp_ready : coverpoint tx.PREADY {
      bins ready = {1};
    }

    // every address with read and write (18 bins)
    addr_x_rw : cross cp_addr, cp_rw;

    // read/write with and without error (4 bins)
    rw_x_err : cross cp_rw, cp_err;

    // legal combinations only: valid -> no error, reserved -> error
    addr_x_err : cross cp_addr, cp_err {
      illegal_bins valid_with_err  = binsof(cp_addr.valid)    && binsof(cp_err.err);
      illegal_bins rsv_without_err = binsof(cp_addr.reserved) && binsof(cp_err.no_err);
    }
  endgroup

  // ---------------- control coverage: transitions and scenarios ----------------
  covergroup cg_ctrl;
    option.per_instance = 1;

    // operation sequence: all four transitions
    cp_rw_trans : coverpoint tx.PWRITE {
      bins wr_to_wr = (1 => 1);
      bins wr_to_rd = (1 => 0);
      bins rd_to_wr = (0 => 1);
      bins rd_to_rd = (0 => 0);
    }

    // error sequence: error then valid shows the slave recovers
    cp_err_trans : coverpoint tx.PSLVERR {
      bins ok_to_err  = (0 => 1);
      bins err_to_err = (1 => 1);
      bins err_to_ok  = (1 => 0);
    }

    // back-to-back write then read to the same address
    cp_b2b : coverpoint b2b_wr_rd {
      bins hit = {1};
    }

    // read as first transfer after reset (checks memory cleared)
    cp_rd_after_rst : coverpoint rd_after_rst {
      bins hit = {1};
    }
  endgroup

  // ---------------- reset coverage ----------------
  covergroup cg_reset;
    option.per_instance = 1;

    // PRESETn: both reset assert and release seen
    cp_presetn : coverpoint tx.PRESETn {
      bins rst_assert  = {0};
      bins rst_release = {1};
    }

    // reset on empty memory (start) and reset after writes (mid-test)
    cp_rst_ctx : coverpoint rst_after_wr {
      bins empty_mem = {0};
      bins with_data = {1};
    }
  endgroup

  function new(string name = "apb_coverage", uvm_component parent = null);
    super.new(name, parent);
    cg_data  = new();
    cg_ctrl  = new();
    cg_reset = new();
  endfunction

  function void write(apb_trans t);
    tx = t;

    // reset assert record (PRESETn = 0)
    if (!t.PRESETn) begin
      rst_after_wr = data_in_mem;
      cg_reset.sample();
      data_in_mem     = 0;      // reset clears memory
      prev_wr_ok      = 0;
      first_after_rst = 1;
      return;
    end

    // reset release record (PREADY = 0), not a real transfer
    if (!t.PREADY) begin
      cg_reset.sample();
      return;
    end

    // real transfer: work out control scenarios
    b2b_wr_rd    = (!t.PWRITE && prev_wr_ok && (t.PADDR == prev_addr));
    rd_after_rst = (first_after_rst && !t.PWRITE);

    cg_data.sample();
    cg_ctrl.sample();

    // update history for next transfer
    prev_wr_ok      = (t.PWRITE && !t.PSLVERR);
    prev_addr       = t.PADDR;
    if (t.PWRITE && !t.PSLVERR) data_in_mem = 1;
    first_after_rst = 0;
  endfunction

  function void report_phase(uvm_phase phase);
    `uvm_info("COV", $sformatf("data=%0.2f%%  ctrl=%0.2f%%  reset=%0.2f%%",
              cg_data.get_inst_coverage(),
              cg_ctrl.get_inst_coverage(),
              cg_reset.get_inst_coverage()), UVM_NONE)
  endfunction

endclass