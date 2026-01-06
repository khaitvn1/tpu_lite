# Tensor Processing Unit Lite

Google’s **Tensor Processing Unit (TPU)** is an application-specific integrated circuit (ASIC) built to accelerate machine learning workloads by doing the “heavy math” of deep learning efficiently — especially **matrix multiplies/tensor operations** that dominate AI training and inference.

This design is a **TPU-Lite**: a small, TPU-inspired accelerator that computes **2×2 matrix multiply** using a **systolic array** of signed **MAC (multiply-accumulate) processing elements**. It’s intentionally sized so you can still reason about it cycle-by-cycle, bring it up on real FPGA hardware, and verify it like a real design.

---

## Overview

This repository implements a simplified version of a TPU-style **GEMM (General Matrix Multiplication)** kernel for 2×2 matrices:

- **`tpu_lite.sv` (main DUT)**  
  Verification-friendly top with a small operand write port, `start`, optional `transpose_b`, `busy/done`, and 4 results.

- **`tpu_lite_basys3.sv` (FPGA wrapper)**  
  Switch/button/LED wrapper for Basys3 bring-up and demo on the actual hardware.

---

## Key Features

### RTL Building Blocks
- **Processing Element — `processing_element.sv`**
  - Signed MAC: `c <= c + (a*b)`
  - `clear` = **“load first product”** for a new dot product (keeps scheduling clean)
  - Forwards `a` (east) and `b` (south) for systolic propagation

- **2×2 Systolic Array — `systolic_array.sv`**
  - 4 PEs wired in a grid:
    - `A` streams left→right
    - `B` streams top→bottom
  - Produces `C00, C01, C10, C11`

- **Memory Management Unit — `mmu.sv`**
  - Generates the wavefront schedule for injecting `A/B` each cycle
  - Asserts per-PE clear pulses aligned to the first valid multiply in each PE
  - Adds **flush cycles** so the bottom-right PE (PE11) always finishes before `done`

- **Operand Memory — `memory.sv`**
  - 8 entries total:
    - addr `0..3`: `A` (a00, a01, a10, a11)
    - addr `4..7`: `B` (b00, b01, b10, b11)

- **Optional `transpose_b`**
  - Transposes B in the feeder to support alternate storage/layout assumptions

---

## Architecture Details

### How the Systolic Compute Works (high level)
Each PE holds a running partial sum `c`. Every cycle it:
1. multiplies current `a*b`
2. accumulates into `c`
3. forwards `a` to the right and `b` downward

The feeder controls *when* the correct `A/B` values enter the array so each PE sees the right pairings.

### Wavefront Scheduling (why the feeder matters)
The array doesn’t compute all four outputs simultaneously — valid data arrives staggered:
- PE00 receives operands first
- PE01 and PE10 receive valid products one cycle later
- PE11 is “deepest” and finishes last

That’s why the MMU includes **flush cycles** before `done`. Without them, it’s easy to latch results too early (a classic systolic timing issue).

---

## Functional Verification

> Note: UVM verifies the **core DUT (`tpu_lite`)**, not the Basys3 wrapper (`tpu_lite_basys3`).

### UVM Environment
- **Interface (`tpu_if`)** with clocking blocks + drv/mon modports
- **Driver**
  - writes 8 operand registers (A and B)
  - sets `transpose_b`
  - pulses `start`
  - waits for `done`
- **Monitor**
  - snapshots operands at `start`
  - captures outputs at `done`
  - publishes transactions to the scoreboard
- **Scoreboard**
  - golden model computes `C = A×B` (including transpose option)
  - compares `C00/01/10/11`
  - prints stats in `report_phase` (total/correct/incorrect)

### Sequences
The testbench starts with simple “known answer” tests and scales into random stress.  
(Achieved **99%+ DUT code coverage** in Cadence Xcelium.)

- **`simple_tpu_seq` (smoke / compile check)**
  - `A = I`, `B = [[3,4],[5,6]]` → expects `C = B`
  - Quick proof that wiring, `done` timing, and the scoreboard are working

- **`tpu_directed_seq` (corner patterns)**
  - Zero-matrix cases (all outputs should be 0)
  - All-ones cases (ensures both MAC terms contribute)
  - Sparse matrices (isolates individual output paths like C01 vs C10)
  - Signed cases (positive/negative mixes to validate two’s complement MAC)

- **`tpu_transpose_seq` (transpose validation)**
  - Runs the same operands with `transpose_b=0` then `transpose_b=1`
  - Uses asymmetric matrices so transpose must change outputs

- **`tpu_random_seq` (constrained-random)**
  - Randomizes signed int8 operands + `transpose_b`
  - Repeats for `N` transactions (set via plusarg)
  - Scoreboard acts as the golden reference and logs pass/fail stats

---

## Performance Metrics

Implemented on **Digilent Basys 3 (Xilinx Artix-7)** at **100 MHz**.

- **Throughput:** one 2×2 op per run (fixed schedule + flush)
- **Core compute:** 4 MAC PEs with systolic propagation
- **Resources:** small (4 MACs + control), varies by `DATA_WIDTH` settings

---

## Practical Applications
Google’s original TPU is an **AI accelerator**: it’s designed to run the heavy math behind deep learning, especially **matrix multiply/GEMM** used in fully-connected layers and convolution backends. This design is a **TPU-Lite**, but it uses the same core pattern:

- **Systolic arrays (GEMM kernels)**  
  A grid of MACs that streams operands through the fabric and accumulates partial sums — the same compute structure used in larger AI accelerators.

- **Deterministic cycle scheduling**  
  The feeder enforces a predictable wavefront schedule (plus flush cycles) so each PE sees the right operand pairs at the right time.

Scaling up is mostly repeating the same concepts:
- parameterize the array to **NxN**
- replace the tiny regfile with a real memory/streaming interface (AXI-stream / ready-valid)
- add tiling/reuse so larger matrices can be fed efficiently (where the real “accelerator” speedup shows up)

---

## Known Limitations
- This is a **2×2** kernel (intentionally small so the timing is easy to reason about)
- No tiling / no external memory bus yet (operands are loaded via a tiny regfile interface)
- No saturation/rounding features (straight signed arithmetic)

---

## Future Improvements
- Parameterize array size (NxN) with generate loops
- Add a streaming ready/valid input path instead of a regfile write port
- Add saturation/rounding options
- Add SystemVerilog Assertions + formal checks for control/timing properties