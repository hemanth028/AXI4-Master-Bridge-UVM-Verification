# AXI4 Master Bridge — RTL & UVM Verification Environment

A parameterizable, high-performance **AXI4 Master Bridge** implemented in RTL Verilog, verified using a complete transaction-level **UVM (Universal Verification Methodology)** testbench and formal **SystemVerilog Assertions (SVA)**.

The design bridges a simplified, user-side streaming interface to fully compliant, burst-based AXI4 transactions.

---

## Table of Contents

- [Key Design Features (RTL)](#key-design-features-rtl)
- [SystemVerilog Assertions (SVA)](#systemverilog-assertions-sva)
- [Functional Coverage Model](#functional-coverage-model)

---

## Key Design Features (RTL)

- **Unaligned Address Handling & Dynamic Strobes** — Supports transfers starting at arbitrary byte boundaries (i.e., non-zero lower bits of `start_addr`). The write data driver dynamically shifts data and applies the correct write strobe (`WSTRB`) on the first beat of a transfer to protect adjacent memory locations from corruption.
- **Transaction Splitting** — Uses ceiling division to calculate burst lengths, carving large user-side byte transfer requests into AXI-compliant bursts while ensuring no transaction crosses the AXI-mandated 4KB page boundary.
- **Read-After-Write (RAW) Hazard Protection** — An internal address comparator and write state tracker stall the Read Address (AR) channel's `m_axi_arvalid` when a read request conflicts with an active or queued write transaction, releasing it once the write response completes.
- **Outstanding Transaction Throttling** — Up/down trackers monitor outstanding read and write address handshakes against completion responses, stalling address issuance once a parameterized limit (`MAX_OUTSTANDING`) is reached, preventing buffer overruns on the interconnect.
- **Dynamic Burst Sizing** — Supports `INCR` (incrementing address), `FIXED` (constant FIFO address), and `WRAP` (cache wrapping) AXI4 burst types.
- **First-Word Fall-Through (FWFT) Queues** — Internal storage buffers use an FWFT combinational design to eliminate the 1-cycle pipeline latency of standard registered FIFOs, aligning data, addresses, and control flags on their respective handshake clock cycles.


## SystemVerilog Assertions (SVA)

A dedicated assertions module (`m_axi_sva`) is bound dynamically inside the DUT (`master_top`) to monitor protocol compliance and safety invariants:

- **Protocol Handshake Stability** — Once `AWVALID`, `ARVALID`, `WVALID`, `BVALID`, or `RVALID` goes high, it (and its payload) remains asserted and stable until the corresponding `READY` signal handshakes.
- **FIFO Safety** — Internal command FIFOs never overflow (pushed when full) or underflow (popped when empty).
- **Memory Boundary Protection** — No AXI burst crosses a 4KB boundary, verified by calculating the exact end address of each burst.
- **Strobe Masking** — The DUT correctly applies the starting offset mask to `m_axi_wstrb` on the first beat of unaligned transfers.
- **RAW Hazard Blocking** — The AR channel remains stalled during active address hazards.

**Additional checks added during coverage closure:**

- **W-Channel Stability** — `WDATA`, `WSTRB` and `WLAST` stay stable while `WVALID && !WREADY`.
- **AR 4KB Boundary Check** — The 4KB end-address check is now applied to the read address channel as well as the write address channel.
- **WLAST Checking** — `WLAST` must be asserted on the last beat of a burst (including single-beat bursts), must not be asserted on any earlier beat, and the W beat counter must clear after the last beat is accepted.
- **BREADY Intent Check** — Confirms the master never back-pressures the B channel, which is the design intent.
- **RAW Hazard Antecedent Refined** — A hazard must block a *new* `ARVALID`. Once `ARVALID` has already been presented it has to be held until `ARREADY` (AXI rule), so a hazard that appears while an AR is already pending is not treated as a violation.
- **Cover Directives** — A `cover property` was added for each key scenario (AW/AR/W/R stall, RAW hazard, AW command FIFO full, single-beat `WLAST`). If an assertion shows zero attempts, its matching cover tells you whether the stimulus never created the scenario or the assertion itself needs review.

**Vacuous assertions (intentional):** Two assertions, the **B-channel stability** and **R-channel stability** checks, are reported as vacuous (zero attempts). Their antecedents (`BVALID && !BREADY`, `RVALID && !RREADY`) can never occur in this testbench because the ready signals are hardwired and no `r_stall` ever happens. These conditions were deliberately **left in the SVA module** because they are required to catch real violations in a real system where the interconnect can back-pressure these channels.

---

## Functional Coverage Model

A dedicated UVM Subscriber class (`m_axi_cov`) contains a comprehensive `covergroup` to measure and prove test completeness.

**Target Coverpoints:**
- Read vs. write direction
- Burst types (`FIXED`, `INCR`, `WRAP`)
- Unaligned address starting offsets (`0`, `1`, `2`, `3`)
- Transfer payload size ranges (tiny, small, medium, large)
- Physical AXI burst lengths (`AWLEN` ranges)
- AXI bus write/read response codes (`OKAY`, `SLVERR`, `DECERR`)
- DUT sticky error outputs (`write_error`, `read_error`)

**Additions made during coverage closure:**
- **Extended payload ranges** — Added `xl` (129–1024 bytes, up to the 256-beat AXI limit), `huge` (1025–4096 bytes, multi-burst) and `jumbo` (4097–8192 bytes, multi-burst with 4KB splits) bins on top of tiny/small/medium/large.
- **4KB boundary crossing** — New coverpoint on `(start_addr[11:0] + total_bytes) > 4096` with `no_cross` / `crosses` bins, exercising the transaction splitter.
- **Write strobe patterns** — New coverpoint (write transactions only) with `all_bytes` (`4'hF`), `partial` and `none` bins.
- **Direction-qualified responses** — `cp_bresp` is sampled only for writes and `cp_rresp` only for reads (`iff` guards). Previously every read sampled `bresp == 0` and every write sampled `rresp == 0`, so the `OKAY` bins were being hit by the wrong transaction type.
- **Crosses** — `direction × burst type`, `direction × payload size`, `direction × 4KB-crossing`, `burst type × 4KB-crossing`, `write × bresp` and `read × rresp` (the response crosses ignore the opposite direction).
- **Per-instance coverage** — `option.per_instance = 1` and a report-phase print of the instance coverage.

<img width="1664" height="639" alt="{7BF8DFDD-92CD-4308-944F-CA2D53D7F5EF}" src="https://github.com/user-attachments/assets/0afb3766-f126-4147-b02a-104188024a89" />

**Note on the report image:** The misses shown are expected, not missing stimulus. There is no `r_stall` scenario because the corresponding ready signal is hardwired in the testbench, so the `r_stall` cover directive can never be hit, and the two stability assertions tied to those hardwired signals stay vacuous. The checks are kept in the design because they are needed for real-system scenarios, so these items are documented as waived rather than removed.
