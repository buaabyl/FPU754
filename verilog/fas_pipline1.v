`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    10:03:35 07/31/2015 
// Design Name: 
// Module Name:    fas_pipline1 
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
module fas_pipline1(
    input clk,
    input rst,

    //s1, exp9, significand32
    input[41:0] x0,
    input[41:0] y0,
    input       enable,

    //s1, significand32
    output[32:0] x1,
    output[32:0] y1,
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
reg[31:0] rX1_significand;

reg       rY1_s;
reg[31:0] rY1_significand;

wire[31:0] X0_shift_q;
reg        Y0_shrn_left;//wire
reg[5:0]   Y0_shrn_n;//wire
wire[31:0] Y0_shift_q;

reg _valid;

////////////////////////////////////////////////////////////
//instances
shift32_left7 shift32_rX0_shl7_inst(
    .v(X0_significand),
    .q(X0_shift_q)
);

shift32 shift32_rY0_shrn_inst(
    .shift_n(Y0_shrn_n),
    .shift_left(Y0_shrn_left),
    .v(Y0_significand),
    .q(Y0_shift_q)
);

////////////////////////////////////////////////////////////
always@(*)
begin
    if (X0_exponent - Y0_exponent < 9'h7) begin
        Y0_shrn_left = 1;
        Y0_shrn_n    = 9'h7 - (X0_exponent - Y0_exponent);
    end
    else if (X0_exponent - Y0_exponent > 9'h23) begin
        Y0_shrn_left = 0;
        Y0_shrn_n    = 16;
    end
    else begin
        Y0_shrn_left = 0;
        Y0_shrn_n    = X0_exponent - Y0_exponent - 9'h7;
    end
end

always@(posedge clk)
begin
    if (rst) begin
        rX1_s           <= 0;
        rX1_exponent    <= 0;
        rX1_significand <= 0;
    end
    else if (enable) begin
        rX1_s           <= X0_s;
        rX1_exponent    <= X0_exponent - 9'h7;
        rX1_significand <= X0_shift_q;
    end
    else begin
        rX1_s           <= rX1_s;
        rX1_exponent    <= rX1_exponent;
        rX1_significand <= rX1_significand;
    end
end

always@(posedge clk)
begin
    if (rst) begin
        rY1_s           <= 0;
        rY1_significand <= 0;
    end
    else if (enable) begin
        rY1_s           <= Y0_s;
        rY1_significand <= Y0_shift_q;
    end
    else begin
        rY1_s           <= rY1_s;
        rY1_significand <= rY1_significand;
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

assign x1       = {rX1_s, rX1_significand[31:0]};
assign y1       = {rY1_s, rY1_significand[31:0]};
assign base_e   = rX1_exponent;
assign valid    = _valid;


endmodule
