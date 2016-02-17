`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    17:19:57 07/31/2015 
// Design Name: 
// Module Name:    fmul_pipline2 
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
module fmul_pipline2(
    input clk,
    input rst,

    //s1, significand64
    input[64:0] x1,
    input[8:0]  base_ei,
    input       enable,

    //s1, significand64
    output[64:0] x2,
    output[8:0]  base_eo,
    output       valid
);

////////////////////////////////////////////////////////////
wire       X1_s;
wire[8:0]  X1_exponent;
wire[63:0] X1_significand;

assign X1_s             = x1[64];
assign X1_exponent      = base_ei;
assign X1_significand   = x1[63:0];

////////////////////////////////////////////////////////////
reg       rX2_s;
reg[8:0]  rX2_exponent;
reg[63:0] rX2_significand;

reg _valid;

////////////////////////////////////////////////////////////
always@(posedge clk)
begin
    if (rst) begin
        rX2_s           <= 0;
        rX2_exponent    <= 0;
        rX2_significand <= 0;
    end
    else if (enable) begin
        if (X1_significand[23]) begin
            rX2_s           <= X1_s;
            rX2_exponent    <= X1_exponent;
            rX2_significand <= X1_significand + 64'h0000_0000_0080_0000;
        end
        else begin
            rX2_s           <= X1_s;
            rX2_exponent    <= X1_exponent;
            rX2_significand <= X1_significand;
        end
    end
    else begin
        rX2_s           <= rX2_s;
        rX2_exponent    <= rX2_exponent;
        rX2_significand <= rX2_significand;
    end
end

////////////////////////////////////////////////////////////
always@(posedge clk)
begin
    if (rst)
        _valid <= 1'b0;
    else
        _valid <= enable;
end

assign x2       = {rX2_s, rX2_significand[63:0]};
assign base_eo  = rX2_exponent;
assign valid    = _valid;


endmodule
