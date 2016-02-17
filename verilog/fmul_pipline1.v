`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    17:00:18 07/31/2015 
// Design Name: 
// Module Name:    fmul_pipline1 
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
module fmul_pipline1(
    input clk,
    input rst,

    //s1, exp9, significand32
    input[41:0] x0,
    input[41:0] y0,
    input       enable,

    //s1, significand64
    output[64:0] x1,
    output[8:0]  base_e,
    output       valid
);

////////////////////////////////////////////////////////////
wire       X0_s;
wire[8:0]  X0_exponent;
wire[31:0] X0_significand;

wire       Y0_s;
wire[8:0]  Y0_exponent;
wire[31:0] Y0_significand;

assign X0_s             = x0[41];
assign X0_exponent      = x0[40:32];
assign X0_significand   = x0[31:0];

assign Y0_s             = y0[41];
assign Y0_exponent      = y0[40:32];
assign Y0_significand   = y0[31:0];

////////////////////////////////////////////////////////////
reg       rX1_s;
reg[8:0]  rX1_exponent;
reg[63:0] rX1_significand;

wire[31:0] mul_a;
wire[31:0] mul_b;
wire[63:0] mul_p;

reg _valid;

////////////////////////////////////////////////////////////
mult32x32 mult32x32_x1_inst(
    .a(mul_a),
    .b(mul_b),
    .p(mul_p)
);

assign mul_a[31:0] = X0_significand[31:0];
assign mul_b[31:0] = Y0_significand[31:0];

////////////////////////////////////////////////////////////
always@(posedge clk)
begin
    if (rst) begin
        rX1_s           <= 0;
        rX1_exponent    <= 0;
    end
    else if (enable) begin
        if (mul_p[63:0] == 64'h0) begin
            rX1_s           <= 0;
            rX1_exponent    <= 0;
        end
        else begin
            rX1_s           <= X0_s ^ Y0_s;
            rX1_exponent    <= X0_exponent + Y0_exponent - 9'd127;
        end
    end
    else begin
        rX1_s           <= rX1_s;
        rX1_exponent    <= rX1_exponent;
    end
end

always@(posedge clk)
begin
    if (rst)
        rX1_significand <= 0;
    else if (enable)
        rX1_significand <= mul_p;
    else
        rX1_significand <= rX1_significand;
end

////////////////////////////////////////////////////////////
always@(posedge clk)
begin
    if (rst)
        _valid <= 1'b0;
    else
        _valid <= enable;
end

assign x1       = {rX1_s, rX1_significand[63:0]};
assign base_e   = rX1_exponent;
assign valid    = _valid;


endmodule
