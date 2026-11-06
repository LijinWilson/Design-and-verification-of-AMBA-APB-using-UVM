/* class apb_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(apb_scoreboard)
	
	function new(string name = "apb_scoreboard", uvm_component parent);
		super.new(name, parent);
	endfunction
	
  apb_trans exp_tx;
	
  uvm_analysis_imp #(apb_trans,apb_scoreboard) ap_scb;
	
  bit [`DATA_WIDTH-1:0] memory [int];
		
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    ap_scb=new("ap_scb",this); 
  endfunction
  
	function void write(apb_trans act_tx);
	
	bit exp_err;
 
  exp_tx = apb_trans::type_id::create("exp_tx");

  // Print ACTUAL transaction
  `uvm_info(get_type_name(),
            $sformatf("ACT_TX :: PADDR=%0d PWRITE=%0b PWDATA=%0d PRDATA=%0d",
                      act_tx.PADDR,
                      act_tx.PWRITE,
                      act_tx.PWDATA,
                      act_tx.PRDATA),
            UVM_LOW)
	
	if(!act_tx.PRESETn) begin
		if(!act_tx.PRESETn) begin
      for (int i = 0; i < `MEM_DEPTH; i++) begin
        memory[i] = 8'h00; 
      end
      `uvm_info(get_type_name(), "RESET: Reference memory initialized to 0", UVM_MEDIUM)
      return;
	end
	
  if (act_tx.PWRITE && !act_tx.PSLVERR) begin
    memory[act_tx.PADDR] = act_tx.PWDATA;

    `uvm_info(get_type_name(),
              $sformatf("WRITE :: Stored EXP_DATA=%0d at ADDR=%0d",
                        act_tx.PWDATA, act_tx.PADDR),
              UVM_LOW)
  end
  else begin
		
		exp_err = (act_tx.PADDR >= `MEM_DEPTH);
		
		// 1) error-response check: Verify PSLVERR matches expectation
    if (act_tx.PSLVERR !== exp_err) begin
      `uvm_error(get_type_name(),
        $sformatf("PSLVERR MISMATCH addr=0x%0h wr=%0b exp_err=%0b act_err=%0b",
                  act_tx.PADDR, act_tx.PWRITE, exp_err, act_tx.PSLVERR))
    end
		
	
    if (memory.exists(act_tx.PADDR)) begin

      // Expected value from memory
      `uvm_info(get_type_name(),
                $sformatf("EXP_TX :: PADDR=%0d EXP_PRDATA=%0d",
                          act_tx.PADDR,
                          memory[act_tx.PADDR]),
                UVM_LOW)

      if (act_tx.PRDATA == memory[act_tx.PADDR]) begin
        `uvm_info(get_type_name(),
                  "READ PASS :: ACT == EXP",
                  UVM_LOW)
      end
      else begin
        `uvm_error(get_type_name(),
                   $sformatf("READ FAIL :: ACT=%0d EXP=%0d",
                             act_tx.PRDATA,
                             memory[act_tx.PADDR]))
      end
    end
    else begin
      `uvm_warning(get_type_name(),
                   $sformatf("READ :: Address %0d does not exist in memory",
                             act_tx.PADDR))
    end
    
  end
endfunction

  
endclass

 
 
  */
	
class apb_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(apb_scoreboard)
  
  function new(string name = "apb_scoreboard", uvm_component parent);
    super.new(name, parent);
  endfunction
	
  uvm_analysis_imp #(apb_trans,apb_scoreboard) ap_scb;
  bit [`DATA_WIDTH-1:0] memory [int];
	
  // FIX 1: Add counters to track test activity
  int total_writes = 0;
  int total_reads  = 0;
  int total_errors = 0;
	
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    ap_scb = new("ap_scb", this); 
  endfunction
  
  function void write(apb_trans act_tx);
    bit exp_err;
 
    // FIX 3: Removed dead 'exp_tx' code

    `uvm_info(get_type_name(),
              $sformatf("ACT_TX :: PADDR=%0d PWRITE=%0b PWDATA=%0d PRDATA=%0d PSLVERR=%0b",
                        act_tx.PADDR, act_tx.PWRITE, act_tx.PWDATA, act_tx.PRDATA, act_tx.PSLVERR),
              UVM_LOW)
	
    // Reset handling: clear memory map
    if(!act_tx.PRESETn) begin
      for (int i = 0; i < `MEM_DEPTH; i++) begin
        memory[i] = 8'h00; 
      end
      `uvm_info(get_type_name(), "RESET: Reference memory initialized to 0", UVM_MEDIUM)
      return;
    end
	
    // Error-response check for ALL transactions
    exp_err = (act_tx.PADDR >= `MEM_DEPTH);
		
    if (act_tx.PSLVERR !== exp_err) begin
      `uvm_error(get_type_name(),
        $sformatf("PSLVERR MISMATCH addr=0x%0h wr=%0b exp_err=%0b act_err=%0b",
                  act_tx.PADDR, act_tx.PWRITE, exp_err, act_tx.PSLVERR))
    end
		
    if (exp_err) begin
      total_errors++;
      // FIX 2: Ensure DUT drives 0 on read errors
      if (!act_tx.PWRITE && act_tx.PRDATA !== '0) begin
        `uvm_error(get_type_name(), 
          $sformatf("ERROR READ FAIL :: PRDATA must be 0 on error, got %0d", act_tx.PRDATA))
      end
    end 
    else begin
      // Functional Data Checks
      if (act_tx.PWRITE) begin
        total_writes++;
        memory[act_tx.PADDR] = act_tx.PWDATA;
        `uvm_info(get_type_name(),
                  $sformatf("WRITE :: Stored EXP_DATA=%0d at ADDR=%0d", act_tx.PWDATA, act_tx.PADDR), UVM_LOW)
      end 
      else begin
        total_reads++;
        // FIX 4: Removed dead warning block since valid memory is pre-filled on reset
        if (act_tx.PRDATA === memory[act_tx.PADDR]) begin
          `uvm_info(get_type_name(), "READ PASS :: ACT == EXP", UVM_LOW)
        end else begin
          `uvm_error(get_type_name(),
                     $sformatf("READ FAIL :: ACT=%0d EXP=%0d", act_tx.PRDATA, memory[act_tx.PADDR]))
        end
      end
    end
  endfunction

  // FIX 1 (cont.): End-of-test verification
  function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info(get_type_name(), "---------------------------------------", UVM_NONE)
    `uvm_info(get_type_name(), $sformatf("SCOREBOARD SUMMARY: WRITES=%0d, READS=%0d, ERRORS=%0d", 
                                         total_writes, total_reads, total_errors), UVM_NONE)
    `uvm_info(get_type_name(), "---------------------------------------", UVM_NONE)
    
    if (total_writes == 0 && total_reads == 0 && total_errors == 0) begin
      `uvm_fatal(get_type_name(), "ZERO transactions captured! Monitor wiring or stimulus is broken.")
    end
  endfunction

endclass