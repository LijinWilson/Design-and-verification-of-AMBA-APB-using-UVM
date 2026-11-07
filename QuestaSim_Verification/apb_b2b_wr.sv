

class apb_b2b_wr extends uvm_sequence #(apb_trans);
  `uvm_object_utils(apb_b2b_wr)
  
  function new(string name = "apb_b2b_wr");
    super.new(name);
  endfunction

  apb_trans tx;
  bit [`ADDR_WIDTH-1:0] saved_addr;

  task body();
    repeat (5) begin
      // 1. Generate a single Write
      tx = apb_trans::type_id::create("tx");
      start_item(tx);
      tx.valid_address_range.constraint_mode(1);
      tx.invalid_address_range.constraint_mode(0);
      if (!tx.randomize() with { PWRITE == 1; PRESETn == 1; }) begin
        `uvm_fatal(get_type_name(), "Randomization failed for B2B write")
      end
      saved_addr = tx.PADDR; // Save the random address we just wrote to
      finish_item(tx);

      // 2. Generate a single Read to the EXACT SAME address immediately after
      tx = apb_trans::type_id::create("tx");
      start_item(tx);
      tx.valid_address_range.constraint_mode(1);
      tx.invalid_address_range.constraint_mode(0);
      if (!tx.randomize() with { PWRITE == 0; PRESETn == 1; PADDR == saved_addr; }) begin
        `uvm_fatal(get_type_name(), "Randomization failed for B2B read")
      end
      finish_item(tx);
    end
  endtask
endclass