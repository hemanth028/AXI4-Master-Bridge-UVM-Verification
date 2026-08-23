# AXI4 Master Bridge — RTL & UVM Verification Environment

A parameterizable, high-performance **AXI4 Master Bridge** implemented in RTL Verilog, verified using a complete transaction-level **UVM (Universal Verification Methodology)** testbench and formal **SystemVerilog Assertions (SVA)**.

The design bridges a simplified, user-side streaming interface to fully compliant, burst-based AXI4 transactions.

---

## Table of Contents

- [Key Design Features (RTL)](#key-design-features-rtl)
- [UVM Verification Architecture](#uvm-verification-architecture)
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

---

## UVM Verification Architecture

The testbench is implemented in SystemVerilog using a fully modular UVM structure to verify the design under high bus latency and randomized stimulus:

- **Sequences and Transactions (`m_axi_tx`)** — Uses dynamic arrays (`user_tx_data[]`, `user_rx_data[]`) to handle variable-length, multi-beat bursts, with sizing and value constraints resolved by the solver in a single step.
- **Accellera-Compliant Utility Methods** — Rather than relying on `uvm_field_*` macros, the transaction class manually implements optimized `do_copy`, `do_compare`, and `do_print` methods to reduce simulation overhead.
- **Driver (`m_axi_driver`)** — Uses clock-synchronized `while` loops mapped to virtual interface clocking blocks (`drv_cb`) to avoid delta-cycle race conditions. Sequentially processes user-side transfers and emulates physical AXI4 slave responses (AW, W, B, AR, R channels) in the background.
- **Monitor (`m_axi_mon`)** — Passively monitors both the user-side and physical AXI-side handshakes concurrently on clocking block edges (`mon_cb`), assembling complete transactions before broadcasting them via an Analysis Port.
- **Scoreboard (`m_axi_sbd`)** — An event-driven, non-blocking checker that mathematically predicts expected AXI parameters (e.g., `ARLEN`, `AWLEN`, start strobes, data alignment) based on user-side stimulus and performs cycle-accurate assertions against the DUT's captured outputs.

---

## SystemVerilog Assertions (SVA)

A dedicated assertions module (`m_axi_sva`) is bound dynamically inside the DUT (`master_top`) to monitor protocol compliance and safety invariants:

- **Protocol Handshake Stability** — Once `AWVALID`, `ARVALID`, `WVALID`, `BVALID`, or `RVALID` goes high, it (and its payload) remains asserted and stable until the corresponding `READY` signal handshakes.
- **FIFO Safety** — Internal command FIFOs never overflow (pushed when full) or underflow (popped when empty).
- **Memory Boundary Protection** — No AXI burst crosses a 4KB boundary, verified by calculating the exact end address of each burst.
- **Strobe Masking** — The DUT correctly applies the starting offset mask to `m_axi_wstrb` on the first beat of unaligned transfers.
- **RAW Hazard Blocking** — The AR channel remains stalled during active address hazards.

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

**Cross Coverage Pairs:**
- Direction × burst type
- Direction × address starting offsets (verifying unaligned reads and writes)
- AXI response codes × DUT sticky error outputs, formally proving the design detects and flags every bus error
