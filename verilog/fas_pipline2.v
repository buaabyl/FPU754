`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    10:28:21 07/31/2015 
// Design Name: 
// Module Name:    fas_pipline2 
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
module fas_pipline2(
    input clk,
    input rst,

    //s1, significand32
    input[32:0] x1,
    input[32:0] y1,
    input[8:0]  base_ei,
    input       enable,

    //s1, significand32
    output[32:0] x2,
    output[8:0]  base_eo,
    output       valid
);

////////////////////////////////////////////////////////////
wire       X1_s;
wire[31:0] X1_significand;

wire       Y1_s;
wire[31:0] Y1_significand;

assign X1_s             = x1[32];
assign X1_significand   = x1[31:0];

assign Y1_s             = y1[32];
assign Y1_significand   = y1[31:0];

////////////////////////////////////////////////////////////
reg       rX2_s;
reg[31:0] rX2_significand;

reg[8:0]  _base_e;
reg _valid;

////////////////////////////////////////////////////////////
always@(posedge clk)
begin
    if (rst) begin
        rX2_s           <= 0;
        rX2_significand <= 0;
    end
    else if (enable) begin
        if (Y1_significand == 0) begin
            rX2_s           <= X1_s;
            rX2_significand <= X1_significand;
        end
        else if (X1_s == Y1_s) begin
            rX2_s           <= X1_s;
            rX2_significand <= X1_significand + Y1_significand;
        end
        else begin
            rX2_s           <= X1_s;
            rX2_significand <= X1_significand - Y1_significand;
        end
    end
    else begin
        rX2_s           <= rX2_s;
        rX2_significand <= rX2_significand;
    end
end

////////////////////////////////////////////////////////////
always@(posedge clk)
begin
    if (rst) begin
        _base_e <= 0;
        _valid  <= 0;
    end
    else begin
        _base_e <= base_ei;
        _valid  <= enable;
    end
end

assign x2       = {rX2_s, rX2_significand[31:0]};
assign base_eo  = _base_e;
assign valid    = _valid;



endmodule
