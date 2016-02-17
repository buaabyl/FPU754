`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    17:57:19 07/31/2015 
// Design Name: 
// Module Name:    FPU_fdiv 
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
module FPU_fdiv(
    input clk,
    input rst,

    //do_fdiv just pluse one clock
    //and wait 'valid' pluse.
    input        do_fdiv,
    input[31:0]  a,
    input[31:0]  b,

    output[31:0] q,
    output       valid
);

////////////////////////////////////////////////////////////
reg sign;
reg[24:0] rA;//divident
reg[24:0] rQ;
reg[24:0] rM;//divisor
reg[8:0]  exponent;
wire[24:0] rAsubrM;

reg[4:0]  cnt;

reg _valid;

parameter ST_IDLE   = 4'h0;
parameter ST_UNPACK = 4'h1;//convert ieee754 to uint25
parameter ST_DIV    = 4'h2;//loop divid
parameter ST_NORMAL = 4'h3;
parameter ST_ERROR  = 4'h4;

reg[3:0] state;
reg[3:0] next_state;//wire

always@(posedge clk)
begin
    if (rst)
        state <= ST_IDLE;
    else
        state <= next_state;
end

always@(*)
begin
    case (state)
        ST_IDLE:begin
            if (do_fdiv)
                next_state = ST_UNPACK;
            else
                next_state = ST_IDLE;
        end
        ST_UNPACK:begin
            if (rM == 0)
                next_state = ST_ERROR;
            else
                next_state = ST_DIV;
        end
        ST_DIV:begin
            if (cnt < 5'd24)//0..24
                next_state = ST_DIV;
            else
                next_state = ST_NORMAL;
        end
        default:begin
            next_state = ST_IDLE;
        end
    endcase
end

always@(posedge clk)
begin
    if (rst)
        cnt <= 0;
    else if (state == ST_UNPACK)
        cnt <= 0;
    else if (state == ST_DIV)
        cnt <= cnt + 1;
    else
        cnt <= cnt;
end

always@(posedge clk)
begin
    if (rst)
        sign <= 0;
    else if ((state == ST_IDLE) && do_fdiv)
        sign <= a[31] ^ b[31];
    else
        sign <= sign;
end

always@(posedge clk)
begin
    if (rst)
        rA <= 0;
    else if ((state == ST_IDLE) && do_fdiv)
        if (a[30:0] == 0)
            rA <= 0;
        else
            rA <= {1'b0, 1'b1, a[22:0]};
    else if (state == ST_DIV)
        if (rA >= rM)
            rA <= {rAsubrM[23:0], 1'b0};
        else
            rA <= {rA[23:0], 1'b0};
    else if (state == ST_NORMAL)//TODO
        rA <= rA;
    else
        rA <= rA;
end

always@(posedge clk)
begin
    if (rst)
        rM <= 0;
    else if ((state == ST_IDLE) && do_fdiv)
        if (b[30:0] == 0)
            rM <= 0;
        else
            rM <= {1'b0, 1'b1, b[22:0]};
    else
        rM <= rM;
end

always@(posedge clk)
begin
    if (rst)
        rQ <= 0;
    else if ((state == ST_IDLE) && do_fdiv)
        rQ <= 0;
    else if (state == ST_DIV)
        if (rA >= rM)
            rQ <= {rQ[23:0], 1'b1};
        else
            rQ <= {rQ[23:0], 1'b0};
    else if (state == ST_NORMAL)
        if (rQ[24])
            rQ <= {1'b0, rQ[24:1]};
        else
            rQ <= rQ;
    else
        rQ <= rQ;
end

always@(posedge clk)
begin
    if (rst)
        exponent <= 0;
    else if ((state == ST_IDLE) && do_fdiv)
        if (b[30:0] == 0)
            exponent <= 255;//inifinite!
        else
            exponent <= {1'b0, a[30:23]} + 9'd127 - {1'b0, b[30:23]};
    else if (state == ST_NORMAL)
        if (rQ[24])
            exponent <= exponent;
        else
            exponent <= exponent - 9'd1;//because we divide 25 times.
    else
        exponent <= exponent;
end

always@(posedge clk)
begin
    if (rst)
        _valid <= 0;
    else if (state == ST_NORMAL)
        _valid <= 1;
    else
        _valid <= 0;
end

assign rAsubrM = rA - rM;

assign q[31:0] = {sign, exponent[7:0], rQ[22:0]};
assign valid = _valid;

endmodule
