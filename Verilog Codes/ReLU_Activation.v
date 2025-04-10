`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/23/2019 01:35:53 PM
// Design Name: 
// Module Name: ReLU_Activation
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: This module applies the Rectified Linear Unit (ReLU) activation 
//              function element-wise to an input feature map represented as a 
//              flattened vector. It instantiates multiple ReLU units, one for 
//              each element in the input map.
// 
// Dependencies: ReLU.v
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

// Module definition for ReLU Activation Layer
module ReLU_Activation #(
    // Parameter: Input data width (bit depth of each element)
    parameter In_d_W=18, 
    // Parameter: Number of rows in the input feature map
    parameter R=3, 
    // Parameter: Number of columns in the input feature map
    parameter C=3
) ( 
    // Input: Clock signal
    input clk,
    // Input: Clear signal (synchronous reset for ReLU units)
    input clr,
    // Input: Enable signal for ReLU computation
    input en_act,
    // Input: Enable signal for ReLU output registration
    input en_act_out,
    // Input: Flattened input feature map (vector)
    // Size: (In_d_W * R * C) bits
    input [(In_d_W * R * C)-1:0] X,
    // Output: Flattened output feature map after ReLU application
    // Size: (In_d_W * R * C) bits
    output [(In_d_W * R * C)-1:0] Z
    );
    
    // Internal wire array to hold unpacked input elements
    // Size: R*C elements, each In_d_W bits wide
    wire [In_d_W-1:0] B [0:R*C-1];
    // Internal wire array to hold output elements from individual ReLU units
    // Size: R*C elements, each In_d_W bits wide
    wire [In_d_W-1:0] D [0:R*C-1];
    
    // Generate block to unpack the flattened input vector X into individual elements B[i]
    generate
    genvar i;
    // Loop through each element of the feature map (R*C total elements)
    for(i=0; i<R*C; i=i+1)
        begin
            // Assign a slice of the input vector X to the corresponding element in array B
            // Each slice is In_d_W bits wide
            assign B[i]=X[(In_d_W*(i+1))-1:In_d_W*i];
        end
    endgenerate
    
    // Generate block to instantiate a ReLU unit for each element of the input feature map
    generate
    genvar j;
    // Loop through each element index (0 to R*C - 1)
    for(j=0; j<R*C; j=j+1)
    begin
        // Instantiate the ReLU module for the j-th element
        // Parameter In_d_W is passed to the ReLU instance
        ReLU #(In_d_W) relu(
            .clk(clk),             // Connect clock
            .clr(clr),             // Connect clear signal
            .en_act(en_act),       // Connect activation enable
            .en_act_out(en_act_out), // Connect activation output enable
            .A(B[j]),              // Connect the j-th input element
            .Y(D[j])               // Connect the j-th output element
        );
    end
    endgenerate
    
    // Generate block to pack the individual ReLU outputs D[k] into the flattened output vector Z
    generate
    genvar k;
    // Loop through each element index (0 to R*C - 1)
    for(k=0; k<R*C; k=k+1)
    begin
        // Assign the k-th ReLU output D[k] to the corresponding slice in the output vector Z
        assign Z[(In_d_W*(k+1))-1 : In_d_W*k]=D[k];
    end
    endgenerate
    
endmodule
