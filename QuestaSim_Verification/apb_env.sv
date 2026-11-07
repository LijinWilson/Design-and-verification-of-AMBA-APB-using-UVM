class apb_env extends uvm_env;
  `uvm_component_utils(apb_env)
  
	function new(string name = "apb_env", uvm_component parent);
		super.new(name, parent);
	endfunction
	
  apb_scoreboard scb;
  apb_agent agt;
	apb_coverage cov; // coverage handle
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    scb=apb_scoreboard::type_id::create("scb",this);
    agt=apb_agent::type_id::create("agt",this);	      	      
		cov=apb_coverage::type_id::create("cov",this); // creating the instance of coverage handle
  endfunction
  
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    agt.mon.ap_mon.connect(scb.ap_scb);
		agt.mon.ap_mon.connect(cov.analysis_export); // connecting the monitor with coverage
  endfunction
  
 
  
endclass

