`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    17:30:20 07/31/2015 
// Design Name: 
// Module Name:    fmul_pipline3 
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
module fmul_pipline3(
    input clk,
    input rst,

    //s1, significand64
    input[64:0] x2,
    input[8:0]  base_ei,
    input       enable,

    //s1, significand32
    output[31:0] x3,
    output[8:0]  base_eo,
    output       valid
);

////////////////////////////////////////////////////////////
wire       X2_s;
wire[8:0]  X2_exponent;
wire[63:0] X2_significand;

assign X2_s             = x2[64];
assign X2_exponent      = base_ei;
assign X2_significand   = x2[63:0];

////////////////////////////////////////////////////////////
reg       rX3_s;
reg[8:0]  rX3_exponent;
reg[31:0] rX3_significand;

reg _valid;

////////////////////////////////////////////////////////////
always@(posedge clk)
begin
    if (rst) begin
        rX3_s           <= 0;
        rX3_exponent    <= 0;
        rX3_significand <= 0;
    end
    else if (enable) begin
        if (X2_significand[47]) begin
            rX3_s           <= X2_s;
            rX3_exponent    <= X2_exponent + 9'd1;
            rX3_significand <= {8'h0, X2_significand[47:24]};
        end
        else begin
            rX3_s           <= X2_s;
            rX3_exponent    <= X2_exponent;
            rX3_significand <= {8'h0, X2_significand[46:23]};
        end
    end
    else begin
        rX3_s           <= rX3_s;
        rX3_exponent    <= rX3_exponent;
        rX3_significand <= rX3_significand;
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

assign x3       = {rX3_s, rX3_significand[30:0]};
assign base_eo  = rX3_exponent;
assign valid    = _valid;

endmodule
