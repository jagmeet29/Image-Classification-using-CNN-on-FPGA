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
//////////////////////////////////////////////////////////////////////////////////


module ReLU #(parameter In_d_W=18) ( // Parameter In_d_W defines the data width
    input clk,         // Clock signal
    input clr,         // Synchronous clear signal
    input en_act,      // Enable signal for ReLU calculation
    input en_act_out,  // Enable signal for output update
    input signed [In_d_W-1:0] A, // Input data
    output reg signed [In_d_W-1:0] Y  // Output data (ReLU result)
    );

    // Internal register to store the intermediate ReLU result
    reg signed [In_d_W-1:0] X;

    // Synchronous logic block
    always@(posedge clk)
    begin
        // Reset condition
        if(clr==1)
        begin
            Y <= 0; // Reset output register
            X <= 0; // Reset internal register
        end
        // Normal operation when clear is low
        else if(clr==0)
        begin
            // Case statement based on enable signals
            case({en_act, en_act_out})
                // Both enables low: Hold the output value
                2'b00: Y <= Y;
                // Only output enable high: Update output with the previous internal value
                2'b01: Y <= X;
                // Only calculation enable high: Calculate ReLU and store in internal register X
                2'b10: begin
                    if(A < 0)       // If input is negative
                        X <= 'd0;   // Store 0 in X
                    else if(A >= 0) // If input is non-negative
                        X <= A;     // Store input A in X
                end
                // Both enables high: Calculate ReLU, store in X, and update output Y in the same cycle (potentially problematic for timing, depends on synthesis)
                // This case combines calculation and output update.
                2'b11: begin
                    if(A < 0)       // If input is negative
                        X <= 'd0;   // Store 0 in X
                    else if(A >= 0) // If input is non-negative
                        X <= A;     // Store input A in X
                    Y <= X;         // Update output Y with the newly calculated value in X (combinatorial path from A to Y through X update logic)
                                    // Note: This might behave differently in simulation vs. synthesis depending on how X is updated and read in the same clock edge.
                                    // A safer approach might be to always update Y based on the value of X from the *previous* cycle when en_act_out is high.
                end
                // Default case (optional, can prevent latches in some synthesis tools if cases are not full)
                // default: begin X <= X; Y <= Y; end
            endcase
        end
    end
endmodule
