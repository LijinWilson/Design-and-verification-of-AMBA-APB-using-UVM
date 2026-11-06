class apb_write_seq extends uvm_sequence #(apb_trans);

  `uvm_object_utils(apb_write_seq)
  
	function new(string name = "apb_write_seq");
		super.new(name);
	endfunction
	
  apb_trans tx;
	
  task body();
    for(integer i = 0; i < `MEM_DEPTH; i++)
      begin
        tx=apb_trans::type_id::create("tx");
        start_item(tx);
        tx.valid_address_range.constraint_mode(1);
        tx.invalid_address_range.constraint_mode(0);
        if (!tx.randomize() with { PWRITE == 1; PRESETn == 1; PADDR == i;}) begin
					`uvm_fatal(get_type_name(), "Randomization failed for write transaction")
				end
        finish_item(tx);
      end
  endtask
endclass


