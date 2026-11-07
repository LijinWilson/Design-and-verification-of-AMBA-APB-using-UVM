<img width="1919" height="1079" alt="image" src="https://github.com/user-attachments/assets/0a2ec045-64f9-4fb3-a982-22a301f65ae5" />


# APB Functional Coverage

The APB UVM coverage component contains three covergroups: `cg_data`, `cg_ctrl`, and `cg_reset`.

## 1. Data Coverage (`cg_data`)

| Coverpoint / Cross | Purpose | Bins / Scenarios |
|---|---|---|
| `cp_addr` | Checks address coverage. | `valid[]`: Individual valid addresses (0 to `MEM_DEPTH-1`); `reserved`: Reserved addresses (`MEM_DEPTH` to 255). |
| `cp_rsv` | Checks reserved-address ranges. | `rsv_low`: `MEM_DEPTH` to 127; `rsv_high`: 128 to 255. |
| `cp_rw` | Covers APB operation types. | `rd_op`: Read (`PWRITE=0`); `wr_op`: Write (`PWRITE=1`). |
| `cp_wdata` | Checks successful write-data ranges. | `low`: 0–85; `mid`: 86–170; `high`: 171–255. |
| `cp_rdata` | Checks successful read-data ranges. | `zero`: 0; `low`: 1–127; `high`: 128–255. |
| `cp_err` | Covers APB error responses. | `no_err`: `PSLVERR=0`; `err`: `PSLVERR=1`. |
| `cp_ready` | Covers the ready condition. | `ready`: `PREADY=1`. |
| `addr_x_rw` | Crosses address category with operation type. | Valid/reserved address × read/write. |
| `rw_x_err` | Crosses operation type with error response. | Read/write × no-error/error. |
| `addr_x_err` | Checks address category against error response. | Illegal bins: Valid address with error; reserved address without error. |

## 2. Control Coverage (`cg_ctrl`)

| Coverpoint | Purpose | Bins / Scenarios |
|---|---|---|
| `cp_rw_trans` | Covers consecutive read/write operation sequences. | `wr_to_wr`, `wr_to_rd`, `rd_to_wr`, `rd_to_rd`. |
| `cp_err_trans` | Covers consecutive error-response transitions. | `ok_to_err`, `err_to_err`, `err_to_ok`. |
| `cp_b2b` | Checks a successful write followed by a read to the same address. | `hit`. |
| `cp_rd_after_rst` | Checks whether the first transfer after reset is a read. | `hit`. |

## 3. Reset Coverage (`cg_reset`)

| Coverpoint | Purpose | Bins / Scenarios |
|---|---|---|
| `cp_presetn` | Covers reset assertion and release. | `rst_assert`: `PRESETn=0`; `rst_release`: `PRESETn=1`. |
| `cp_rst_ctx` | Checks whether a successful write occurred since the previous reset when reset is asserted. | `empty_mem`: No successful write recorded; `with_data`: At least one successful write recorded. |

## Coverage Results

The QuestaSim functional coverage report shows **100% coverage** for the displayed covergroups and coverage items in the simulation run.

This indicates that all the defined coverage items shown in the report were hit. It does not imply exhaustive verification of every possible APB scenario.
