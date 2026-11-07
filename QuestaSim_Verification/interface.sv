interface intf(input PCLK);
    logic        PRESETn;   // Active Low Reset
    logic        PSEL;      // Slave Select
    logic        PENABLE;   // Enable Signal
    logic        PWRITE;    // Write (1) / Read (0)
    logic [`ADDR_WIDTH-1:0]  PADDR;     // Address of Slave
    logic [`DATA_WIDTH-1:0]    PWDATA;    // Write Data, DUT is 8 Bit
    logic [`DATA_WIDTH-1:0]    PRDATA; // Read Data, DUT is 8 Bit
    logic        PREADY;  
    logic        PSLVERR;  
  
  clocking drv_cb @(posedge PCLK);
    default input #1 output #0;
    output PRESETn,PSEL,PENABLE,PWRITE,PADDR,PWDATA;
    input PRDATA,PREADY,PSLVERR;
  endclocking
  
   clocking mon_cb @(posedge PCLK);
    default input #1 output #0;
    input PRESETn,PSEL,PENABLE,PWRITE,PADDR,PWDATA;
    input PRDATA,PREADY,PSLVERR;
  endclocking
	
	// =========================================================
  // SYSTEMVERILOG ASSERTIONS (SVA) - APB PROTOCOL CHECKER
  // =========================================================

  default clocking cb_assert @(posedge PCLK); endclocking

  // 1. SETUP to ACCESS Transition Rule
  property p_setup_to_access;
    disable iff (PRESETn !== 1'b1)
    (PSEL && !PENABLE) |=> (PSEL && PENABLE);
  endproperty
  A_SETUP_TO_ACCESS: assert property(p_setup_to_access)
    else $error("SVA FATAL: PENABLE did not assert 1 cycle after PSEL.");

  // 2. Control Signal Stability During Wait States
  property p_stable_ctrl;
    disable iff (PRESETn !== 1'b1)
    (PSEL && PENABLE && !PREADY) |=> (PSEL && PENABLE && $stable(PWRITE) && $stable(PADDR));
  endproperty
  A_STABLE_CTRL: assert property(p_stable_ctrl)
    else $error("SVA FATAL: Control signals changed during ACCESS phase before PREADY.");

  // 3. Write Data Stability During Wait States
  property p_stable_pwdata;
    disable iff (PRESETn !== 1'b1)
    (PSEL && PENABLE && PWRITE && !PREADY) |=> $stable(PWDATA);
  endproperty
  A_STABLE_PWDATA: assert property(p_stable_pwdata)
    else $error("SVA FATAL: PWDATA changed during ACCESS phase before PREADY.");

  // 4. PENABLE Fall on Transfer Completion
  property p_penable_fall;
    disable iff (PRESETn !== 1'b1)
    (PSEL && PENABLE && PREADY) |=> (!PENABLE);
  endproperty
  A_PENABLE_FALL: assert property(p_penable_fall)
    else $error("SVA FATAL: PENABLE did not deassert after PREADY transfer completion.");

  // 5. PSLVERR Legality
  property p_pslverr_valid;
    disable iff (PRESETn !== 1'b1)
    PSLVERR |-> (PSEL && PENABLE && PREADY);
  endproperty
  A_PSLVERR_VALID: assert property(p_pslverr_valid)
    else $error("SVA FATAL: PSLVERR asserted illegally without PREADY/PENABLE/PSEL.");

  // 6. Unknown (X/Z) State Checking
  property p_no_x_z;
    // FIX: Using an implication operator ensures we only evaluate this when reset is definitively high
    PRESETn === 1'b1 |-> !$isunknown({PSEL, PENABLE, PWRITE});
  endproperty
  A_NO_X_Z: assert property(p_no_x_z)
    else $error("SVA FATAL: Core control signals went to X or Z.");

  // 7. Reset Behavior 
  property p_reset_clear;
    // FIX: $fell explicitly triggers only when reset drops from 1 to 0
    $fell(PRESETn) |=> (!PSEL && !PENABLE);
  endproperty
  A_RESET_CLEAR: assert property(p_reset_clear)
    else $error("SVA FATAL: Signals did not clear after PRESETn asserted.");
		
		
endinterface

 
