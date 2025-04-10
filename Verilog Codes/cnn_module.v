`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/07/2020 12:50:42 PM
// Design Name: 
// Module Name: cnn_module
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module cnn_module #(
    // Input data width (bit depth of input pixels)
    parameter In_d_W=8, 
    // Width of addressing for input data
    parameter In_Add_W=4, 
    // Number of rows in input feature map/image
    parameter R_N_Conv=5, 
    // Number of columns in input feature map/image
    parameter C_N_Conv=5, 
    // Number of rows in convolution filter
    parameter R_F_Conv=3, 
    // Number of columns in convolution filter
    parameter C_F_Conv=3, 
    // Padding size for convolution operation
    parameter P_Conv=0, 
    // Stride (step size) for convolution operation
    parameter S_Conv=1, 
    // Calculate output feature map height after convolution (derived parameter)
    parameter R_Pool_In=(((R_N_Conv+(2*P_Conv)-R_F_Conv)/S_Conv)+1), 
    // Calculate output feature map width after convolution (derived parameter)
    parameter C_Pool_In=(((C_N_Conv+(2*P_Conv)-C_F_Conv)/S_Conv)+1), 
    // Pooling window height
    parameter R_Pool_Area=2, 
    // Pooling window width
    parameter C_Pool_Area=2, 
    // Padding for pooling operation
    parameter P_Pool=0, 
    // Stride for pooling operation
    parameter S_Pool=1, 
    // Clock period for timing considerations
    parameter Timeperiod=10
) (
    // System clock
    input clk,
    // System reset
    input rst,
    // Clear signal to reset internal registers
    input clr,
    // Write enable for loading data
    input wr,
    // Enable clock for convolution module
    input en_clk,
    // Enable write operation for data loading
    input en_wr,
    // Enable read operation for data retrieval
    input en_rd,
    // Enable MAC (Multiply-Accumulate) operations
    input en_MAC,
    // Enable output from MAC operations
    input en_MAC_out,
    // Enable activation function (ReLU)
    input en_act,
    // Enable output from activation function
    input en_act_out,
    // Enable pooling operations
    input en_pool,
    // Enable output from pooling layer
    input en_pool_out,
    // Input feature map/image data - size: [199:0] for 5x5x8 input
    input [(C_N_Conv*R_N_Conv*In_d_W)-1:0] N,
    // Convolution filter weights - size: [71:0] for 3x3x8 filter
    input [(C_F_Conv*R_F_Conv*In_d_W)-1:0] F,
    // Final output after pooling - size: [2*2*18-1:0] for 2x2 output with 18-bit precision
    output [((((R_Pool_In+(2*P_Pool)-R_Pool_Area)/S_Pool)+1)*(((C_Pool_In+(2*P_Pool)-C_Pool_Area)/S_Pool)+1)*((2*In_d_W)+2))-1 : 0] Y
);
    // Define the dimensions of convolution output (same as pooling input)
    parameter R_Conv_Out=R_Pool_In;    // Number of rows in convolution output (3 for default parameters)
    parameter C_Conv_Out=C_Pool_In;    // Number of columns in convolution output (3 for default parameters)
    // Calculate the dimensions of pooling output
    parameter R_Pool_Out=(((R_Pool_In+(2*P_Pool)-R_Pool_Area)/S_Pool)+1);    // Number of rows after pooling (2 for default parameters)
    parameter C_Pool_Out=(((C_Pool_In+(2*P_Pool)-C_Pool_Area)/S_Pool)+1);    // Number of columns after pooling (2 for default parameters)
    // Data width after convolution - increases due to multiplication and addition
    parameter Out_d_W_Conv=((2*In_d_W)+2);    // Output data width after convolution (18 bits for 8-bit input)
    // Data width for pooling input (same as convolution output)
    parameter In_d_W_Pool=Out_d_W_Conv;    // Input data width for pooling (18 bits)
    
    // Wire to carry output from convolution layer to activation function
    // Size: [3*3*18-1:0] for 3x3 feature map with 18-bit precision
    wire [(R_Conv_Out * C_Conv_Out * Out_d_W_Conv)-1:0] W1;
    
    // Wire to carry output from activation function to pooling layer
    // Size: [3*3*18-1:0] for 3x3 feature map with 18-bit precision
    wire [(R_Pool_In * C_Pool_In * In_d_W_Pool)-1:0] W2;
    
    // Instantiate the sliding window convolution module
    // Performs convolution operation on input feature map using the filter
    slide_window_conv #(In_d_W, In_Add_W, R_N_Conv, C_N_Conv, R_F_Conv, C_F_Conv, P_Conv, S_Conv, Timeperiod) SWC
    (.clk(clk),             // Connect system clock
     .clk_en(en_clk),       // Connect clock enable signal
     .rst(rst),             // Connect reset signal
     .clr(clr),             // Connect clear signal
     .en_wr(en_wr),         // Connect write enable signal
     .en_rd(en_rd),         // Connect read enable signal
     .wr(wr),               // Connect write signal
     .en_MAC(en_MAC),       // Connect MAC enable signal
     .en_MAC_out(en_MAC_out), // Connect MAC output enable signal
     .N(N),                 // Connect input feature map
     .F(F),                 // Connect convolution filter
     .Y(W1));               // Connect output to intermediate wire W1
    
    // Instantiate the ReLU activation function module
    // Applies ReLU (max(0,x)) to each element of the convolution output
    ReLU_Activation #(Out_d_W_Conv, R_Conv_Out, C_Conv_Out) RA 
    (.clk(clk),             // Connect system clock
     .clr(clr),             // Connect clear signal
     .en_act(en_act),       // Connect activation enable signal
     .en_act_out(en_act_out), // Connect activation output enable signal
     .X(W1),                // Connect input from convolution output (W1)
     .Z(W2));               // Connect output to intermediate wire W2
    
    // Instantiate the max pooling module
    // Performs max pooling operation on the activated feature map
    max_pooling #(In_d_W_Pool, R_Pool_In, C_Pool_In, R_Pool_Area, C_Pool_Area, P_Pool, S_Pool, Timeperiod) MP 
    (.clk(clk),             // Connect system clock
     .rst(rst),             // Connect reset signal
     .clr(clr),             // Connect clear signal
     .en_pool(en_pool),     // Connect pooling enable signal
     .en_pool_out(en_pool_out), // Connect pooling output enable signal
     .N(W2),                // Connect input from activation output (W2)
     .Y(Y));                // Connect to final module output Y
    
endmodule
