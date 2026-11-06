class reset_seq extends uvm_sequence #(apb_trans);
  `uvm_object_utils(reset_seq)
  
	function new(string name = "reset_seq");
		super.new(name);
	endfunction
	
  apb_trans tx;
  task body();
		tx=apb_trans::type_id::create("tx");
		start_item(tx);
		tx.valid_address_range.constraint_mode(1);
		tx.invalid_address_range.constraint_mode(0);
		
		if (!tx.randomize() with { PRESETn == 0; }) begin
			`uvm_fatal(get_type_name(), "Randomization failed for reset transaction")
		end
		
		finish_item(tx);
  endtask
endclass



