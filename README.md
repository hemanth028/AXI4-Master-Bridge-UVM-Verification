# AXI4 Master Bridge RTL & UVM Verification Environment

This repository contains a parameterizable, high-performance **AXI4 Master Bridge** designed in RTL Verilog, paired with a complete, transaction-level **UVM (Universal Verification Methodology) Verification Environment** and formal **SystemVerilog Assertions (SVA)**.

The design acts as a lightweight bridge translating a simplified, user-side streaming interface into fully compliant, burst-based AXI4 transactions.

---

## Key Design Features (RTL)

* **Unaligned Address Handling & Dynamic Strobes:** Supports starting transfers at arbitrary byte boundaries (e.g., lower bits of `start_addr` are non-zero). The write data driver dynamically shifts and applies the correct write strobe (`WSTRB`) on the first beat of a transfer to safely protect adjacent memory locations from corruption.
* **Transaction Splitting:** Mathematically calculates burst lengths using ceiling division. Carves up large user-side byte transfer requests into AXI-compliant bursts, ensuring no transaction crosses the AXI-mandated 4KB page boundary.
* **Read-After-Write (RAW) Hazard Protection:** Features an internal address comparator and write state tracker. It temporarily stalls the Read Address (AR) channel's `m_axi_arvalid` when a read request conflicts with an active or queued write transaction, cleanly releasing it once the write response completes.
* **Outstanding Transaction Throttling:** Integrates up/down trackers to monitor outstanding read and write address handshakes versus completion responses. Stalls address issuances once the count reaches a parameterized limit (`MAX_OUTSTANDING`) to prevent buffer overruns on the interconnect.
* **Dynamic Burst Sizing:** Supports `INCR` (incrementing address), `FIXED` (constant FIFO address), and `WRAP` (cache wrapping) AXI4 burst types.
* **First-Word Fall-Through (FWFT) Queues:** Converted internal storage buffers to an FWFT combinational design to eliminate the 1-cycle pipeline latency of standard registered FIFOs, aligning data, addresses, and control flags on their respective handshake clock cycles.

---

## UVM Verification Architecture

The testbench is implemented in SystemVerilog using a fully modular UVM structure to verify the design under high bus latency and randomized stimulus:

* **Sequences and Transactions (`m_axi_tx`):** Outfitted with dynamic arrays (`user_tx_data[]`, `user_rx_data[]`) to handle variable-length, multi-beat bursts. Sizing and value constraints are dynamically evaluated by the solver in a single step.
* **Accellera-Compliant Utility Methods:** To avoid the simulation overhead and compiler-limiting behavior of standard `uvm_field_*` macros, the transaction class manually implements highly optimized `do_copy`, `do_compare`, and `do_print` methods.
* **Driver (`m_axi_driver`):** Features clock-synchronized `while` loops mapped to virtual interface clocking blocks (`drv_cb`) to prevent delta-cycle race conditions. It sequentially processes user-side transfers and emulates physical AXI4 slave responses (AW, W, B, AR, R channels) in the background.
* **Monitor (`m_axi_mon`):** Passively monitors both the user-side and the physical AXI-side handshakes concurrently on clocking block edges (`mon_cb`), assembling complete transactions before broadcasting them via an Analysis Port.
* **Scoreboard (`m_axi_sbd`):** Implements an event-driven, non-blocking checker. It mathematically predicts expected AXI parameters (e.g., ARLEN, AWLEN, start strobes, data alignment) based on user-side stimulus, and performs cycle-accurate assertions against the DUT's captured outputs.

---

## SystemVerilog Assertions (SVA)

A dedicated assertions module (`m_axi_sva`) is bound dynamically inside the DUT (`master_top`) to monitor protocol compliance and safety invariants:

* **Protocol Handshake Stability:** Asserts that once `AWVALID`, `ARVALID`, `WVALID`, `BVALID`, or `RVALID` goes high, it stays asserted and stable along with its payload until its corresponding `READY` signal handshakes.
* **FIFO Safety:** Asserts that internal command FIFOs never overflow (pushed when full) or underflow (popped when empty).
* **Memory Boundary Protection:** Verifies that no AXI burst crosses a 4KB boundary by calculating the exact end address of each burst.
* **Strobe Masking:** Verifies that the DUT successfully applies the starting offset mask to `m_axi_wstrb` on the first beat of unaligned transfers.
* **RAW Hazard Blocking:** Asserts that the AR channel remains stalled during active address hazards.

---

## Functional Coverage Model

The verification suite includes a dedicated UVM Subscriber class (`m_axi_cov`) containing a comprehensive `covergroup` to measure and prove test completeness:

* **Target Coverpoints:**
  * Read vs. Write direction.
  * Burst types (`FIXED`, `INCR`, `WRAP`).
  * Unaligned address starting offsets (`0`, `1`, `2`, `3`).
  * Transfer payload size ranges (tiny, small, medium, large).
  * Physical AXI burst lengths (`AWLEN` ranges).
  * AXI bus write/read response codes (`OKAY`, `SLVERR`, `DECERR`).
  * DUT sticky error outputs (`write_error`, `read_error`).
* **Cross Coverage Pairs:**
  * Direction crossed with burst type.
  * Direction crossed with address starting offsets (verifying unaligned reads and writes).
  * AXI response codes crossed with DUT sticky error outputs to formally prove that the design successfully detects and flags every bus error.