class apb_driver extends uvm_driver#(apb_trans);
  `uvm_component_utils(apb_driver)
  
	
	function new(string name = "apb_driver", uvm_component parent);
		super.new(name, parent);
	endfunction
	
  apb_trans tx;
  virtual intf inf;
	
	localparam int unsigned TIMEOUT_CYCLES = 20; // timeout logic - 1
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    assert(uvm_config_db #(virtual intf)::get(this,"","inf",inf)) else `uvm_fatal(get_type_name(), "Virtual interface 'inf' not found in config_db");
  endfunction
  
  task run_phase(uvm_phase phase);
    super.run_phase(phase);
		
		do_reset(); // resetting the tx components
		
    forever begin
      // tx=apb_trans::type_id::create("tx");
      seq_item_port.get_next_item(tx);
      send_to_dut(tx);
      seq_item_port.item_done();
    end
  endtask
	
	// RESET
	// Hold reset for 2 cycles with an idle bus, then release
  task do_reset();
    // @(inf.drv_cb);
    inf.drv_cb.PRESETn <= 1'b0;
    inf.drv_cb.PSEL    <= 1'b0;
    inf.drv_cb.PENABLE <= 1'b0;
    inf.drv_cb.PWRITE  <= 1'b0;
    inf.drv_cb.PADDR   <= '0;
    inf.drv_cb.PWDATA  <= '0;
    repeat (2) @(inf.drv_cb);
    inf.drv_cb.PRESETn <= 1'b1;
    @(inf.drv_cb);
  endtask
  
  task send_to_dut(apb_trans tx);
		
		int unsigned count;
	
    // @(inf.drv_cb);
		
    if(!tx.PRESETn)
      begin
        do_reset();
				return;

      end
    
    else
      begin
			
				// SETUP Phase
				
       inf.drv_cb.PADDR<=tx.PADDR; 
       inf.drv_cb.PWRITE<=tx.PWRITE; 
       inf.drv_cb.PRESETn<=tx.PRESETn; 
       inf.drv_cb.PSEL<=1'b1;
       inf.drv_cb.PENABLE<=1'b0; 
       inf.drv_cb.PWDATA<=tx.PWDATA; 
       @(inf.drv_cb);
			 
			 // ACCESS Phase
			 
        inf.drv_cb.PENABLE<=1'b1; 
				
         // wait(inf.drv_cb.PREADY);
				 
				 // - instead of waiting for PREADY, we will use an timerconcept, timer or wait process will continue for certain time if time limit crosses this will throw an error'
				 // - It has a timeout, so a stuck DUT gives an error instead of a hang.
				 // - If your APB slave has a bug and forgets to assert PREADY, that wait statement will cause your simulation to hang infinitely, stalling the server and giving you no useful debug log.
				  
				// TIME OUT LOGIC
				count = 0;
					do begin
						@(inf.drv_cb); // loop pauses and wait for the clock derived by drv_cb;
						count++;
						if(count >= TIMEOUT_CYCLES) begin
							`uvm_error(get_type_name(), $sformatf("TIME OUT ERROR, PREADY Time out exceed more than %0d cycle", TIMEOUT_CYCLES));
							break; // forcefully exit out from the loop
						end
					end while(!inf.drv_cb.PREADY);
				 
        if(!tx.PWRITE)
          begin
           tx.PRDATA = inf.drv_cb.PRDATA; 
          end
					
				 // capture response (blocking assignments)
				tx.PREADY  = inf.drv_cb.PREADY;
				tx.PSLVERR = inf.drv_cb.PSLVERR;
				
				// ---- end of transfer: go IDLE ----
				// For back-to-back traffic the next item drives SETUP in this same time
				// step and overrides these (last drive wins, no glitch).
				inf.drv_cb.PSEL    <= 1'b0;
				inf.drv_cb.PENABLE <= 1'b0;
				
      end
  endtask
  
  
endclass

