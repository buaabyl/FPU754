`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    11:53:54 07/23/2015 
// Design Name: 
// Module Name:    shift32 
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
module shift32(
    // 0:shift  0 (not change)
    // 1:shift  1
    //   ...
    //31:shift 31
    //32:shift 32 (set zero)
    input[5:0]   shift_n,
    input        shift_left,
    input[31:0]  v,
    output[31:0] q
);

////////////////////////////////////////////////////////////
//== shift left ==
//v:        |3|3|2|2|2|2|2|2|2|2|2|2|1|1|1|1|
//          |1|0|9|8|7|6|5|4|3|2|1|0|9|8|7|6|
//          .                               |1|1|1|1|1|1| | | | | | | | | | |
//          .                               |5|4|3|2|1|0|9|8|7|6|5|4|3|2|1|0|
//          .                               .                               .
//v<<2: |3|3|2|2|2|2|2|2|2|2|2|2|1|1|1|1| | |                               .
//      |1|0|9|8|7|6|5|4|3|2|1|0|9|8|7|6| | |                               .
//                                      |1|1|1|1|1|1| | | | | | | | | | | | |
//                                      |5|4|3|2|1|0|9|8|7|6|5|4|3|2|1|0| | |
//
//lo[31:0] = v[15:0]  * 16'h0004;// v[15:0]  << 2
//hi[31:0] = v[31:16] * 16'h0004;// v[31:16] << 2
//q[31:0]  = {hi[15:0], 16'h00} | lo[31:0];
//
//== shift right ==
//v:    |3|3|2|2|2|2|2|2|2|2|2|2|1|1|1|1|
//      |1|0|9|8|7|6|5|4|3|2|1|0|9|8|7|6|
//      .   .                           |1|1|1|1|1|1| | | | | | | | | | |
//      .   .                           |5|4|3|2|1|0|9|8|7|6|5|4|3|2|1|0|
//      .   .                           .   .                           .
//v>>2: | | |3|3|2|2|2|2|2|2|2|2|2|2|1|1|1|1|                           .
//      | | |1|0|9|8|7|6|5|4|3|2|1|0|9|8|7|6|                           .
//                                          |1|1|1|1|1|1| | | | | | | | | | |
//                                          |5|4|3|2|1|0|9|8|7|6|5|4|3|2|1|0|
//
//lo[31:0] = v[15:0]  * 16'h4000;// v[15:0]  << 14
//hi[31:0] = v[31:16] * 16'h4000;// v[31:16] << 14
//q[31:0]  = hi[31:0] | {16'h00, lo[31:16]};
//
//== summary ==
//n = 0..15
//  q = v << n:=
//    b[15:0]  = 1 << n;
//    lo[31:0] = v[15:0]  * b[15:0];
//    hi[31:0] = v[31:16] * b[15:0];
//    q[31:0]  = {hi[15:0], 16'h00} | lo[31:0];
//  
//  q = v >> n:=
//    b[15:0]  = 1 << (16-n);
//    lo[31:0] = v[15:0]  * b[15:0];
//    hi[31:0] = v[31:16] * b[15:0];
//    q[31:0]  = hi[31:0] | {16'h00, lo[31:16]};
//
//n = 16..32
//  q = v << n:=
//    b[15:0]  = 1 << (n-16);
//    lo[31:0] = v[15:0]  * b[15:0];
//    hi[31:0] = v[31:16] * b[15:0];
//    q[31:0]  = {lo[15:0], 16'h00};
//
//  q = v >> n:=
//    b[15:0]  = 1 << (16-(n-16));
//    lo[31:0] = v[15:0]  * b[15:0];
//    hi[31:0] = v[31:16] * b[15:0];
//    q[31:0]  = {16'h00, hi[31:16]};
//

////////////////////////////////////////////////////////////
wire[15:0] mul_b;
wire[31:0] hi;
wire[31:0] lo;

wire[31:0] res_shl16;//n = 0..15
wire[31:0] res_shr16;//n = 0..15
wire[31:0] res_shl32;//n = 16..31
wire[31:0] res_shr32;//n = 16..31
reg[31:0]  res;

mult16x16 mult16x16_hi_inst(
    .a(v[31:16]),
    .b(mul_b),
    .p(hi)
);

mult16x16 mult16x16_lo_inst(
    .a(v[15:0]),
    .b(mul_b),
    .p(lo)
);

////////////////////////////////////////////////////////////
reg[3:0]  decode_din;//wire
reg[16:0] decode_dout;//wire
always@(*)
begin
    case (decode_din)
        4'd0 :decode_dout = 16'h0001;
        4'd1 :decode_dout = 16'h0002;
        4'd2 :decode_dout = 16'h0004;
        4'd3 :decode_dout = 16'h0008;
        4'd4 :decode_dout = 16'h0010;
        4'd5 :decode_dout = 16'h0020;
        4'd6 :decode_dout = 16'h0040;
        4'd7 :decode_dout = 16'h0080;
        4'd8 :decode_dout = 16'h0100;
        4'd9 :decode_dout = 16'h0200;
        4'd10:decode_dout = 16'h0400;
        4'd11:decode_dout = 16'h0800;
        4'd12:decode_dout = 16'h1000;
        4'd13:decode_dout = 16'h2000;
        4'd14:decode_dout = 16'h4000;
        4'd15:decode_dout = 16'h8000;
    endcase
end

always@(*)
begin
    if (shift_left)
        decode_din = shift_n[3:0];
    else
        decode_din = ~shift_n[3:0] + 4'b0001;
end

assign mul_b = decode_dout;

////////////////////////////////////////////////////////////
assign res_shl16[31:0] = {hi[15:0], 16'h0000} | lo[31:0];
assign res_shr16[31:0] =  hi[31:0]            | {16'h0000, lo[31:16]};
assign res_shl32[31:0] = {lo[15:0], 16'h00};
assign res_shr32[31:0] = {16'h00,   hi[31:16]};

always@(*)
begin
    if (shift_n == 6'd32)
        res = 32'h0;
    else if (shift_n == 6'd0)
        res = v;
    else if (shift_n[4] == 0)//n = 0..15
        if (shift_left)
            res = res_shl16;
        else
            res = res_shr16;
    else
        if (shift_left)
            res = res_shl32;
        else
            res = res_shr32;
end

assign q = res;


endmodule
