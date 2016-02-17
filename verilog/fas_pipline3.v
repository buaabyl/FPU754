`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    10:38:22 07/31/2015 
// Design Name: 
// Module Name:    fas_pipline3 
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
module fas_pipline3(
    input clk,
    input rst,

    //s1, significand32
    input[32:0] x2,
    input[8:0]  base_ei,
    input       enable,

    //s1, significand32
    output[32:0] x3,
    output[8:0]  base_eo,
    output       valid
);

////////////////////////////////////////////////////////////
wire       X2_s;
wire[31:0] X2_significand;

assign X2_s             = x2[32];
assign X2_significand   = x2[31:0];

////////////////////////////////////////////////////////////
reg _sign;
reg[31:0] rX3_significand;
reg[8:0]  _base_e;
reg _valid;

////////////////////////////////////////////////////////////
always@(posedge clk)
begin
    if (rst) 
        rX3_significand <= 0;
    else if (enable)
        if (X2_significand[6]) // <=> (X2_significand & 0x0000_0040)
            rX3_significand <= X2_significand + 32'h0000_0040;
        else
            rX3_significand <= X2_significand;
    else
        rX3_significand <= rX3_significand;
end

////////////////////////////////////////////////////////////
always@(posedge clk)
begin
    if (rst) begin
        _base_e <= 0;
        _valid  <= 0;
        _sign   <= 0;
    end
    else begin
        _base_e <= base_ei;
        _valid  <= enable;
        _sign   <= X2_s;
    end
end

assign x3       = {_sign, rX3_significand[31:0]};
assign base_eo  = _base_e;
assign valid    = _valid;

endmodule
