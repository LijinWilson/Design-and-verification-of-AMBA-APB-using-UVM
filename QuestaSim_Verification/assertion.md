# SystemVerilog Assertion (SVA) Test Plan for AMBA APB Slave

This document outlines the concurrent SystemVerilog Assertions (SVA) implemented in the `interface.sv` file to continuously monitor and verify the AMBA APB slave protocol compliance at the clock-cycle level.

## Coverage Summary
* **Assertion Coverage:** 100.00%
* **Failures:** 0

## Assertion Rules Verified

*   **`A_SETUP_TO_ACCESS` (Phase Transition Rule):** 
    Verifies that the bus strictly follows the APB state machine. Ensures that when Slave Select (`PSEL`) goes high, the Enable signal (`PENABLE`) asserts exactly one clock cycle later to transition from the SETUP phase to the ACCESS phase.

*   **`A_STABLE_CTRL` (Control Signal Stability):** 
    Verifies wait-state compliance. Ensures that the address (`PADDR`) and control signal (`PWRITE`) remain perfectly locked and stable during the ACCESS phase while waiting for the slave to assert `PREADY`.

*   **`A_STABLE_PWDATA` (Data Signal Stability):** 
    Ensures data integrity during stalled write transfers. Guarantees that `PWDATA` does not fluctuate or change while `PSEL` and `PENABLE` are high but `PREADY` is low.

*   **`A_PENABLE_FALL` (Transfer Completion):** 
    Verifies a clean bus release. Ensures that exactly one cycle after a transfer completes (indicated by `PREADY` going high), the `PENABLE` signal drops back to `0`.

*   **`A_PSLVERR_VALID` (Error Legality):** 
    Prevents false error flagging. Ensures the slave error signal (`PSLVERR`) is only ever asserted during the exact, legal cycle of transfer completion (when `PSEL`, `PENABLE`, and `PREADY` are all high).

*   **`A_NO_X_Z` (Unknown State Checking):** 
    Continuously monitors the physical bus to guarantee that critical control signals never float to unknown (`X`) or high-impedance (`Z`) states while the reset is inactive.

*   **`A_RESET_CLEAR` (Asynchronous Reset Behavior):** 
    Verifies hardware reset propagation. Guarantees that the moment `PRESETn` drops (asserts), the active bus control signals (`PSEL`, `PENABLE`) are immediately scrubbed to `0` on the very next clock edge, regardless of what state the bus was in.


<img width="1651" height="511" alt="image" src="https://github.com/user-attachments/assets/4bc4edaf-00bf-468e-940f-8b1c1ad2715c" />
