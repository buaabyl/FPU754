`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    10:47:48 07/31/2015 
// Design Name: 
// Module Name:    fas_pipline4 
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
module fas_pipline4(
    input clk,
    input rst,

    //s1, significand32
    input[32:0] x3,
    input[8:0]  base_ei,
    input       enable,

    //s1, significand32
    output[32:0] x4,
    output[8:0]  base_eo,
    output       valid
);

////////////////////////////////////////////////////////////
wire       X3_s;
wire[8:0]  X3_exponent;
wire[31:0] X3_significand;

assign X3_s             = x3[32];
assign X3_exponent      = base_ei;
assign X3_significand   = x3[31:0];

////////////////////////////////////////////////////////////
reg       rX4_s;
reg[8:0]  rX4_exponent;
reg[31:0] rX4_significand;

reg        X3_shrn_left;//wire
reg[5:0]   X3_shrn_n;//wire
wire[31:0] X3_shift_q;
reg[8:0]   X3_exp_new;//wire

reg _valid;

////////////////////////////////////////////////////////////
shift32 shift32_X3_shrn_inst(
    .shift_n(X3_shrn_n),
    .shift_left(X3_shrn_left),
    .v(X3_significand),
    .q(X3_shift_q)
);

////////////////////////////////////////////////////////////
always@(*)
begin
    ////////////////////////////////
    //bigger: val = val >> n
    if (X3_significand[31]) begin
        X3_shrn_left = 0;
        X3_shrn_n    = 8;
        X3_exp_new  = X3_exponent + 9'd8;
    end
    else if (X3_significand[30]) begin
        X3_shrn_left = 0;
        X3_shrn_n    = 7;
        X3_exp_new  = X3_exponent + 9'd7;
    end
    else if (X3_significand[29]) begin
        X3_shrn_left = 0;
        X3_shrn_n    = 6;
        X3_exp_new  = X3_exponent + 9'd6;
    end
    else if (X3_significand[28]) begin
        X3_shrn_left = 0;
        X3_shrn_n    = 5;
        X3_exp_new  = X3_exponent + 9'd5;
    end
    else if (X3_significand[27]) begin
        X3_shrn_left = 0;
        X3_shrn_n    = 4;
        X3_exp_new  = X3_exponent + 9'd4;
    end
    else if (X3_significand[26]) begin
        X3_shrn_left = 0;
        X3_shrn_n    = 3;
        X3_exp_new  = X3_exponent + 9'd3;
    end
    else if (X3_significand[25]) begin
        X3_shrn_left = 0;
        X3_shrn_n    = 2;
        X3_exp_new  = X3_exponent + 9'd2;
    end
    else if (X3_significand[24]) begin
        X3_shrn_left = 0;
        X3_shrn_n    = 1;
        X3_exp_new  = X3_exponent + 9'd1;
    end
    ////////////////////////////////
    //no need to shift
    else if (X3_significand[23]) begin
        X3_shrn_left = 0;
        X3_shrn_n    = 0;
        X3_exp_new  = X3_exponent;
    end
    ////////////////////////////////
    //smaller: val = val << n
    else if (X3_significand[22]) begin
        X3_shrn_left = 1;
        X3_shrn_n    = 1;
        X3_exp_new  = X3_exponent - 9'd1;
    end
    else if (X3_significand[21]) begin
        X3_shrn_left = 1;
        X3_shrn_n    = 2;
        X3_exp_new  = X3_exponent - 9'd2;
    end
    else if (X3_significand[20]) begin
        X3_shrn_left = 1;
        X3_shrn_n    = 3;
        X3_exp_new  = X3_exponent - 9'd3;
    end
    else if (X3_significand[19]) begin
        X3_shrn_left = 1;
        X3_shrn_n    = 4;
        X3_exp_new  = X3_exponent - 9'd4;
    end
    else if (X3_significand[18]) begin
        X3_shrn_left = 1;
        X3_shrn_n    = 5;
        X3_exp_new  = X3_exponent - 9'd5;
    end
    else if (X3_significand[17]) begin
        X3_shrn_left = 1;
        X3_shrn_n    = 6;
        X3_exp_new  = X3_exponent - 9'd6;
    end
    else if (X3_significand[16]) begin
        X3_shrn_left = 1;
        X3_shrn_n    = 7;
        X3_exp_new  = X3_exponent - 9'd7;
    end
    else if (X3_significand[15]) begin
        X3_shrn_left = 1;
        X3_shrn_n    = 8;
        X3_exp_new  = X3_exponent - 9'd8;
    end
    else if (X3_significand[14]) begin
        X3_shrn_left = 1;
        X3_shrn_n    = 9;
        X3_exp_new  = X3_exponent - 9'd9;
    end
    else if (X3_significand[13]) begin
        X3_shrn_left = 1;
        X3_shrn_n    = 10;
        X3_exp_new  = X3_exponent - 9'd10;
    end
    else if (X3_significand[12]) begin
        X3_shrn_left = 1;
        X3_shrn_n    = 11;
        X3_exp_new  = X3_exponent - 9'd11;
    end
    else if (X3_significand[11]) begin
        X3_shrn_left = 1;
        X3_shrn_n    = 12;
        X3_exp_new  = X3_exponent - 9'd12;
    end
    else if (X3_significand[10]) begin
        X3_shrn_left = 1;
        X3_shrn_n    = 13;
        X3_exp_new  = X3_exponent - 9'd13;
    end
    else if (X3_significand[9]) begin
        X3_shrn_left = 1;
        X3_shrn_n    = 14;
        X3_exp_new  = X3_exponent - 9'd14;
    end
    else if (X3_significand[8]) begin
        X3_shrn_left = 1;
        X3_shrn_n    = 15;
        X3_exp_new  = X3_exponent - 9'd15;
    end
    ////////////////////////////////
    //too small
    else begin
        X3_shrn_left = 1;
        X3_shrn_n    = 16;
        X3_exp_new  = 9'd0;
    end
end

always@(posedge clk)
begin
    if (rst) begin
        rX4_s           <= 0;
        rX4_exponent    <= 0;
        rX4_significand <= 0;
    end
    else if (enable) begin
        if (X3_significand < 32'h0000_000F) begin
            rX4_s           <= 0;
            rX4_exponent    <= 0;
            rX4_significand <= 0;
        end
        else begin
            rX4_s           <= X3_s;
            rX4_exponent    <= X3_exp_new;
            rX4_significand <= X3_shift_q;
        end
    end
    else begin
        rX4_s           <= rX4_s;
        rX4_exponent    <= rX4_exponent;
        rX4_significand <= rX4_significand;
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

assign x4       = {rX4_s, rX4_significand[31:0]};
assign base_eo  = rX4_exponent;
assign valid    = _valid;


endmodule
