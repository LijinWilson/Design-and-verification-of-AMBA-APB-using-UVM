/* class apb_monitor extends uvm_monitor;
  `uvm_component_utils(apb_monitor)
	
	function new(string name = "apb_monitor", uvm_component parent);
		super.new(name, parent);
	endfunction
	
  apb_trans tx;
  virtual intf inf;
	
  uvm_analysis_port #(apb_trans) ap_mon; // analysis port implementation
	
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    uvm_config_db #(virtual intf)::get(this," ","inf",inf);
    ap_mon=new("ap_mon",this); 
  endfunction
  
  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    forever begin
      tx=apb_trans::type_id::create("tx");
      @(inf.mon_cb.PSEL && inf.mon_cb.PENABLE && inf.mon_cb.PREADY);
      tx.PADDR=inf.mon_cb.PADDR;
      tx.PWRITE=inf.mon_cb.PWRITE;
      if(tx.PWRITE)
     	 tx.PWDATA=inf.mon_cb.PWDATA;
      else
         tx.PRDATA=inf.mon_cb.PRDATA;

      ap_mon.write(tx);
      
    end
  endtask
endclass
  


 */
 
 class apb_monitor extends uvm_monitor;
  `uvm_component_utils(apb_monitor)
	
  function new(string name = "apb_monitor", uvm_component parent);
    super.new(name, parent);
  endfunction
	
  virtual intf inf;
  uvm_analysis_port #(apb_trans) ap_mon; 
	
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    assert(uvm_config_db #(virtual intf)::get(this,"","inf",inf)) else `uvm_fatal(get_type_name(), "virtual interface 'inf' not found in config_db");
    ap_mon = new("ap_mon",this); 
  endfunction
  
  task run_phase(uvm_phase phase);
    super.run_phase(phase);
		
    forever begin
      // FIX 1: Safe asynchronous reset handling
      fork
        get_txn();
        begin
          wait(inf.PRESETn == 0);
        end
      join_any
      disable fork; // Instantly kill get_txn if reset occurs

      // If we dropped out of the fork because of a reset, report it
      if (inf.PRESETn == 0) begin
        report_reset();
      end
    end
  endtask
	
  task get_txn();
    apb_trans tx;
    forever begin
      @(inf.mon_cb);
			
      if(inf.mon_cb.PRESETn == 1 && inf.mon_cb.PSEL && inf.mon_cb.PENABLE) begin
        if(inf.mon_cb.PREADY) begin
          tx = apb_trans::type_id::create("tx");
          tx.PRESETn     = 1'b1; 
          tx.PADDR       = inf.mon_cb.PADDR;
          tx.PWRITE      = inf.mon_cb.PWRITE;
          tx.PSLVERR     = inf.mon_cb.PSLVERR;
          tx.PREADY      = 1'b1;
          
          // FIX 3: Only capture the valid data field based on PWRITE
          if (tx.PWRITE) begin
            tx.PWDATA = inf.mon_cb.PWDATA;
            tx.PRDATA = '0; 
          end else begin
            tx.PWDATA = '0;
            tx.PRDATA = inf.mon_cb.PRDATA;
          end
          
          ap_mon.write(tx);
        end
      end
    end
  endtask
	
  task report_reset();
    apb_trans rst_tx;
    
    // Report reset assertion
    rst_tx         = apb_trans::type_id::create("rst_tx");
    rst_tx.PRESETn = 1'b0;
    ap_mon.write(rst_tx);
    
    // FIX 2: Wait for reset release and report it
    wait(inf.PRESETn == 1);
    rst_tx         = apb_trans::type_id::create("rst_tx");
    rst_tx.PRESETn = 1'b1;
    ap_mon.write(rst_tx);
  endtask
  
endclass