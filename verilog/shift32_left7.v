`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    14:31:25 07/23/2015 
// Design Name: 
// Module Name:    shift32_left7 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module shift32_left7(
    input[31:0]  v,
    output[31:0] q
);

assign q[31:0] = {v[24:0], 7'h0};


endmodule
