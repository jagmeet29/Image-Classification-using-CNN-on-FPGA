// `timescale directive defines the simulation time unit and precision.
// 1ns / 1ps means the time unit is 1 nanosecond, and the precision is 1 picosecond.
`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 12/23/2019 12:38:00 PM
// Design Name: ReLU Activation Function
// Module Name: ReLU
// Project Name: Image Classification using CNN on FPGA
// Target Devices: FPGA
// Tool Versions:
// Description: This module implements the Rectified Linear Unit (ReLU) activation function.
//              ReLU is defined as f(x) = max(0, x).
//              If the input 'A' is negative, the output 'Y' is 0.
//              If the input 'A' is non-negative, the output 'Y' is equal to 'A'.
//              The module uses a registered input 'X' to store the intermediate result
//              and a registered output 'Y'.
//              Control signals 'en_act' and 'en_act_out' manage the data flow.
//              'en_act' enables the calculation of the ReLU function based on input 'A'.
//              'en_act_out' enables the output 'Y' to be updated with the calculated value 'X'.
//              A synchronous clear signal 'clr' resets the internal register 'X' and output 'Y'.
//
// Dependencies: None
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
// --- Detailed Explanation ---
//
// Why `parameter` for In_d_W?
//   - Parameters (`parameter`) are used for constants that define the configuration of the module,
//     like data width. They make the module reusable and flexible. You can change the data width
//     (e.g., from 18 bits to 16 bits) when you *instantiate* (use) this module elsewhere,
//     without modifying the internal logic of the ReLU module itself.
//
// Why `input` for clk, clr, en_act, en_act_out, A?
//   - `input` ports define signals that come *into* this module from an external source
//     (like a higher-level module that uses this ReLU).
//   - `clk`: The clock signal drives the synchronous elements (registers) and determines when
//     state changes occur. It must be an input as it's provided by the system.
//   - `clr`: The clear signal is used to reset the module's state. It's an input control signal.
//   - `en_act`, `en_act_out`: These are enable signals controlling the module's operation phases.
//     They are inputs because the controlling logic resides outside this module.
//   - `A`: This is the data input on which the ReLU function operates. It must be an input
//     to receive the value to be processed.
//
// Why `output` for Y?
//   - `output` ports define signals that go *out* of this module to be used by other parts
//     of the system. `Y` is the result of the ReLU calculation.
//
// Why `reg` for Y and X?
//   - `reg` is used for variables that store a value and are assigned within an `always` block
//     (or an `initial` block).
//   - `Y`: The output `Y` needs to hold its value between clock cycles, especially when the
//     enable signals dictate holding (`2'b00`) or updating based on the *previous* value of `X` (`2'b01`).
//     Assigning `Y` inside the `always @(posedge clk)` block requires it to be declared as `reg`.
//     Declaring an output as `reg` means the module internally drives a register whose output is connected
//     to the port `Y`.
//   - `X`: This is an internal state register. It holds the intermediate result of the ReLU
//     calculation (`max(0, A)`). It needs to store this value so that `Y` can be updated with it
//     in a subsequent clock cycle (or the same cycle, depending on enables). Being assigned
//     within the `always` block necessitates it being a `reg`. It's not an output port, just an
//     internal variable.
//
// Why `signed` for A, X, Y?
//   - `signed` indicates that the variable (input, output, or internal reg) should be treated
//     as a signed number (using two's complement representation).
//   - The ReLU function definition `f(x) = max(0, x)` explicitly involves checking if the input
//     is negative (`A < 0`). This comparison requires `A` to be interpreted as a signed number.
//   - Since `X` stores the result based on `A`, and `Y` stores the value from `X`, they also
//     need to be `signed` to correctly represent potential negative inputs and the comparison result.
//     Although the *output* of ReLU is always non-negative, the intermediate comparison requires
//     signed interpretation.
//
// Why `wire` is not explicitly used for inputs/outputs?
//   - In Verilog, ports (`input`, `output`, `inout`) are implicitly `wire` type by default unless
//     you explicitly declare them as `reg` (which is only allowed for `output` or `inout` when
//     assigned procedurally, like in an `always` block).
//   - `clk`, `clr`, `en_act`, `en_act_out`, `A` are inputs, so they behave like wires, carrying
//     signals from outside into the module.
//   - `Y` is declared as `output reg`, so it's driven by an internal register. If it were
//     `output Y` (without `reg`) and assigned using an `assign` statement (combinational logic),
//     it would be an output wire.
//
// `always @(posedge clk)` block:
//   - This defines a block of code that executes only on the rising edge of the `clk` signal.
//   - This creates *synchronous* logic, meaning the state of the registers (`X`, `Y`) only
//     changes at discrete points in time defined by the clock edge. This is crucial for
//     predictable behavior in digital circuits (FPGAs).
//
// Non-blocking assignment (`<=`):
//   - Inside synchronous `always` blocks, non-blocking assignments (`<=`) should be used.
//   - They schedule the assignment to happen *after* all right-hand sides in the block have
//     been evaluated for the current clock edge. This prevents race conditions and ensures
//     that registers update based on the values from the *start* of the clock cycle.
//
//////////////////////////////////////////////////////////////////////////////////

// 'module' keyword starts the definition of a Verilog module.
// 'ReLU' is the name of the module.
// '#()' defines parameters for the module. Parameters make the module reusable and configurable.
// '(...) ' defines the ports (inputs and outputs) of the module.
module ReLU #(
    // 'parameter' keyword defines a constant value that can be overridden when the module is instantiated.
    parameter In_d_W = 18 // 'In_d_W' (Input Data Width) defines the bit width of the data signals (A, X, Y).
                          // Default is 18 bits. Using a parameter allows easy modification.
) (
    // --- Inputs ---
    input clk,                     // Clock signal: Drives the synchronous logic.
    input clr,                     // Clear signal: Synchronous reset (active high).
    input en_act,                  // Enable Activation Calculation: Controls when ReLU logic computes.
    input en_act_out,              // Enable Activation Output: Controls when output Y is updated.
    input signed [In_d_W-1:0] A,   // Input Data: The value to apply ReLU to. 'signed' allows negative checks.

    // --- Output ---
    // 'output reg': Y is an output port driven by an internal register.
    // 'signed': Y holds values derived from signed input A.
    output reg signed [In_d_W-1:0] Y // Output Data: Result of max(0, A).
);
    // Internal register to store the intermediate ReLU result
    // 'reg': Needed because it's assigned in an always block.
    // 'signed': Matches the type of A for comparison and storage.
    reg signed [In_d_W-1:0] X;

    // Synchronous logic block: Executes on the rising edge of the clock.
    always@(posedge clk)
    begin
        // Reset condition: If 'clr' is high, reset registers to 0.
        // This is a synchronous reset because it only happens on a clock edge when clr is high.
        if(clr==1)
        begin
            Y <= 0; // Reset output register using non-blocking assignment.
            X <= 0; // Reset internal register using non-blocking assignment.
        end
        // Normal operation when clear is low
        else if(clr==0)
        begin
            // Case statement based on the concatenated enable signals {en_act, en_act_out}.
            // This controls the behavior in different phases.
            case({en_act, en_act_out})
                // Both enables low: Hold the current output value. Do nothing to X.
                2'b00: Y <= Y;
                // Only output enable high: Update output Y with the value stored in X *from the previous cycle*.
                2'b01: Y <= X;
                // Only calculation enable high: Calculate ReLU based on input A and store the result in X.
                // Y is not updated in this case (implicitly holds its value, though the 2'b00 case makes this explicit).
                2'b10: begin
                    if(A < 0)       // If input A is negative (requires 'signed' type)
                        X <= 'd0;   // Store 0 in X. ('d0 is decimal 0)
                    else // if(A >= 0) // If input A is non-negative
                        X <= A;     // Store input A in X.
                    // Y <= Y; // Implicitly holds value, no assignment needed here.
                end
                // Both enables high: Calculate ReLU, store in X, AND update output Y in the same cycle.
                // Note: Y gets the value that X is *scheduled* to get in this same clock cycle.
                // In simulation and synthesis, this usually means Y gets the *new* value of X.
                2'b11: begin
                    if(A < 0)
                        X <= 'd0;
                    else // if(A >= 0)
                        X <= A;
                    Y <= X; // Update Y with the new value being assigned to X.
                end
                // Default case (optional but good practice): Prevents accidental latch creation if cases aren't exhaustive.
                // In this specific case, all 4 possibilities for 2 bits are covered, so it's not strictly needed.
                // default: begin X <= X; Y <= Y; end
            endcase
        end
    end
endmodule
