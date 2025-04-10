# Explanation of ReLU.v Verilog Module

This document explains the Verilog code for the `ReLU` module found in `ReLU.v` in detail. It also provides additional background on why certain coding styles and constructs (such as wires, parameters, inputs, registered signals, and signed data) are used in Verilog.

## Module Definition and Ports

```verilog
// filepath: c:\Users\jagme\Downloads\Image-Classification-using-CNN-on-FPGA\Verilog Codes\ReLU.v
module ReLU #(
    parameter In_d_W = 18 // Input Data Width parameter
) (
    // --- Inputs ---
    input clk,                     // Clock signal: Drives synchronous updates.
    input clr,                     // Clear signal: Synchronous reset; active high.
    input en_act,                  // Enable signal for calculating the ReLU function.
    input en_act_out,              // Enable signal for updating the output.
    input signed [In_d_W-1:0] A,   // Data input. 'signed' ensures negative numbers are interpreted properly.
    // --- Output ---
    output reg signed [In_d_W-1:0] Y // Data output. Declared as reg because it is updated in an always block.
);
```

**Explanation:**

- **Parameters:**
  - `parameter In_d_W = 18` sets the bit width for all data signals. Using a parameter makes the module reusable and configurable for different bit widths.
- **Input Ports:**
  - `clk`, `clr`, `en_act`, `en_act_out` are control signals provided from outside. They are declared as `input` (implicitly wires) because they carry signal values into the module.
  - `A` is declared as `signed` to correctly compare and process negative values in the ReLU function.
- **Output Port:**
  - `Y` is declared as `output reg` because it holds its value across clock cycles and is updated in a synchronous always block.

---

## Internal Register Declaration

```verilog
    reg signed [In_d_W-1:0] X; // Internal register to store the intermediate ReLU result.
```

**Explanation:**

- `X` is an internal state element where the result of the computation (max(0, A)) is stored.
- It is declared as `reg` because its value is updated inside the `always @(posedge clk)` block, and as `signed` to match the signed arithmetic of `A`.

---

## Synchronous Always Block and Reset Logic

```verilog
    always@(posedge clk)
    begin
        if(clr==1)
        begin
            Y <= 0; // Reset output register using non-blocking assignment.
            X <= 0; // Reset internal register.
        end
        else if(clr==0)
        begin
            case({en_act, en_act_out})
            // ...existing case code...
            endcase
        end
    end
```

**Explanation:**

- The `always @(posedge clk)` block ensures that updates to `X` and `Y` occur synchronously with the clock.
- A synchronous reset is implemented: When `clr` is high, both registers are reset to 0 on the next rising clock edge.
- Non-blocking assignments (`<=`) are used to avoid race conditions by scheduling simultaneous updates at the end of the clock period.

---

## Operational Logic (Case Statement)

```verilog
            case({en_act, en_act_out})
                2'b00: Y <= Y;              // Neither calculation nor output update: Maintain current value.
                2'b01: Y <= X;              // Only output enable: Update Y from the stored value in X.
                2'b10: begin                // Only calculation enable: Compute ReLU and store the result in X.
                    if(A < 0)
                        X <= 'd0;
                    else
                        X <= A;
                end
                2'b11: begin                // Both enables: Compute ReLU and update Y in the same cycle.
                    if(A < 0)
                        X <= 'd0;
                    else
                        X <= A;
                    Y <= X;
                end
            endcase
```

**Explanation:**

- The concatenated enable signals (`{en_act, en_act_out}`) control the module's behavior:
  - **2'b00:** No change.
  - **2'b01:** Updates the output `Y` with the stored value from `X`.
  - **2'b10:** Computes the ReLU of input `A` and stores the result in `X` without updating `Y`.
  - **2'b11:** Both computes the result and updates `Y` simultaneously.
- This structure allows flexibility in data flow control, useful in pipelining or managing computation delays.

---

## Additional Explanation: Need for the Case Statement

The use of the case statement in the `always @(posedge clk)` block is critical for fine-grained control over the module’s operation. Rather than performing a single update, the design splits the behavior into multiple modes determined by the two enable signals (`en_act` and `en_act_out`). This allows:

- **Holding Values:**  
  When both enables are low (2'b00), neither the internal register `X` nor the output `Y` changes. This efficiently retains the current state.

- **Separate Phases:**  
  When only output enable is high (2'b01), the module updates `Y` from `X` (which holds the previous computation result) without recomputing the ReLU function.

- **Isolated Computation:**  
  When only the calculation enable is high (2'b10), the module computes the ReLU value and stores it in `X` without immediately affecting `Y`.

- **Combined Operation:**  
  When both signals are high (2'b11), the module both computes the new result (updating `X`) and updates `Y` in the same clock cycle. This offers flexibility for designs where immediate propagation of the computed value is desired.

A single updation would not afford this level of control. It would force the module to perform all operations at once, eliminating the possibility of pipelining, stage separation, or holding intermediate results that may be needed for timing or data flow control.

In summary, the case statement enables distinct operational modes, providing the necessary granularity to manage computation and output update independently and reliably, which is essential for ensuring correct data flow and timing in the design.

---

## Basic Verilog Concepts Applied

1. **Parameters vs. Wires vs. Inputs vs. Registers:**

   - **Parameters:**  
     Used for constants like data width. They help make the module configurable.
   - **Inputs:**  
     Declared as inputs to bring signals from other modules. By default, these are of type `wire`, meaning they do not store state.
   - **Outputs:**  
     When outputs are driven by internal sequential logic (like in an always block), they are declared as `output reg` so that they can hold state between clock cycles.
   - **Internal Registers:**  
     `reg` variables (like `X`) are used to store values that change over time, especially in synchronous designs.

2. **Signed Data:**

   - Signals declared as `signed` indicate that they are two's complement numbers. This is essential for operations like checking if a number is negative (e.g., `if(A < 0)`).

3. **Wires:**

   - Although not explicitly declared for inputs/outputs here, wires are the default for ports. They represent continuous connections between modules.

4. **Synchronous Logic and Clocks:**

   - The design uses an `always @(posedge clk)` block to ensure that state updates only occur in sync with the clock edges, which is crucial for reliable digital circuit behavior.

5. **Non-blocking Assignments:**
   - Using `<=` inside clocked always blocks ensures that all right-hand side expressions are evaluated before any assignments are updated, preventing race conditions.

---

# Summary

This document explains in detail the reasoning behind:

- The use of parameters to allow configurability.
- Why certain signals are declared as inputs (and hence wires by default) or outputs (`reg`) based on their role in the design.
- The importance of using signed values to properly handle negative numbers.
- The synchronous design practices of using clock edges and non-blocking assignments to create predictable and reliable hardware behavior.

These explanations should help someone with basic knowledge of Verilog understand the design decisions in the `ReLU` module.
