/* class apb_test extends uvm_test;
  `uvm_component_utils(apb_test)
  
	function new(string name = "apb_test", uvm_component parent);
		super.new(name, parent);
	endfunction

  apb_env env;

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = apb_env::type_id::create("env", this);
  endfunction

  task run_phase(uvm_phase phase);
	
    apb_write_seq write_seq; // sequence simple write operation
		apb_read_seq read_seq; // sequence simple read operation
		apb_b2b_wr b2b_seq; // sequence write and read operation will happen back to back
    apb_neg_seq neg_seq; // sequence hard coding the memory location to invalid address
    reset_seq rst_seq; // sequence for reset operation
		
		phase.phase_done.set_drain_time(this, 100);   // let monitor/scoreboard finish last transfer
		
    phase.raise_objection(this);

    rst_seq   = reset_seq::type_id::create("rst_seq");
    write_seq = apb_write_seq::type_id::create("write_seq");
    read_seq  = apb_read_seq::type_id::create("read_seq");
    b2b_seq   = apb_b2b_wr::type_id::create("b2b_seq");
    neg_seq   = apb_neg_seq::type_id::create("neg_seq");

		rst_seq.start(env.agt.sqr);          // reset
    write_seq.start(env.agt.sqr);        // fill memory
    read_seq.start(env.agt.sqr);         // read back
    b2b_seq.start(env.agt.sqr);          // write->read, no idle between
    neg_seq.start(env.agt.sqr);          // reserved addresses -> PSLVERR
    
		
    phase.drop_objection(this);
  endtask
  

endclass

 */
 
class apb_test extends uvm_test;
  `uvm_component_utils(apb_test)
  
  function new(string name = "apb_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  apb_env env;

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = apb_env::type_id::create("env", this);
  endfunction

  task run_phase(uvm_phase phase);
	
    apb_write_seq write_seq; 
    apb_read_seq  read_seq; 
    apb_b2b_wr    b2b_seq; 
    apb_neg_seq   neg_seq; 
    reset_seq     rst_seq; 
		
    phase.phase_done.set_drain_time(this, 100);   
		
    phase.raise_objection(this);

    rst_seq   = reset_seq::type_id::create("rst_seq");
    write_seq = apb_write_seq::type_id::create("write_seq");
    read_seq  = apb_read_seq::type_id::create("read_seq");
    b2b_seq   = apb_b2b_wr::type_id::create("b2b_seq");
    neg_seq   = apb_neg_seq::type_id::create("neg_seq");

    // 1. Initialize DUT
    rst_seq.start(env.agt.sqr);          
    
    // 2. Standard Traffic (Fill & Verify)
    write_seq.start(env.agt.sqr);        
    read_seq.start(env.agt.sqr);         
    
    // 3. Back-to-Back Traffic
    b2b_seq.start(env.agt.sqr);          
    
    // 4. Error Traffic
    neg_seq.start(env.agt.sqr);          
    
    // FIX: Verify memory was untouched by the invalid writes
    read_seq.start(env.agt.sqr);         
    
    // FIX: Mid-test reset to prove reset clears populated memory
    rst_seq.start(env.agt.sqr);          
    
    // FIX: Verify memory is actually 0x00 after reset
    read_seq.start(env.agt.sqr);         
		
    phase.drop_objection(this);
  endtask
  
endclass