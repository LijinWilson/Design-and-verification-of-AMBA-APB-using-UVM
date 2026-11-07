/* class apb_neg_seq extends uvm_sequence #(apb_trans);

  `uvm_object_utils(apb_neg_seq)
  
	function new(string name = "apb_neg_seq");
		super.new(name);
	endfunction
	
  apb_trans tx;
	
  task body();
    repeat(5)
      begin
        tx=apb_trans::type_id::create("tx");
        start_item(tx);
        tx.valid_address_range.constraint_mode(0);
        tx.invalid_address_range.constraint_mode(1);
				
        if (!tx.randomize() with { PRESETn == 1; }) begin
					`uvm_fatal(get_type_name(), "Randomization failed for negative transaction")
				end
				
        finish_item(tx);
      end
  endtask
endclass


 */
 
 class apb_neg_seq extends uvm_sequence #(apb_trans);

  `uvm_object_utils(apb_neg_seq)
  
  function new(string name = "apb_neg_seq");
    super.new(name);
  endfunction
	
  apb_trans tx;
	
  task body();
    // 1. Guarantee explicitly testing invalid WRITES
    repeat(3) begin
      tx=apb_trans::type_id::create("tx");
      start_item(tx);
      tx.valid_address_range.constraint_mode(0);
      tx.invalid_address_range.constraint_mode(1);
				
      if (!tx.randomize() with { PRESETn == 1; PWRITE == 1; }) begin
        `uvm_fatal(get_type_name(), "Randomization failed for negative write transaction")
      end
				
      finish_item(tx);
    end

    // 2. Guarantee explicitly testing invalid READS
    repeat(3) begin
      tx=apb_trans::type_id::create("tx");
      start_item(tx);
      tx.valid_address_range.constraint_mode(0);
      tx.invalid_address_range.constraint_mode(1);
				
      if (!tx.randomize() with { PRESETn == 1; PWRITE == 0; }) begin
        `uvm_fatal(get_type_name(), "Randomization failed for negative read transaction")
      end
				
      finish_item(tx);
    end
  endtask
endclass