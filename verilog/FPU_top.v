`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    16:16:41 08/04/2015 
// Design Name: 
// Module Name:    FPU_top 
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
module FPU_top(
    input clk,
    input rst,

    /*cpu interface*/
    input we,
    input re,
    input[6:0]  addr,
    input[7:0]  idata,
    output[7:0] odata
);

////////////////////////////////////////////////////////////
parameter BASEADDR = 7'h71;

parameter ADDR_DATA0    = BASEADDR + 7'h0;
parameter ADDR_DATA1    = BASEADDR + 7'h1;
parameter ADDR_DATA2    = BASEADDR + 7'h2;
parameter ADDR_DATA3    = BASEADDR + 7'h3;
parameter ADDR_XL       = BASEADDR + 7'h4;
parameter ADDR_XH       = BASEADDR + 7'h5;
parameter ADDR_YL       = BASEADDR + 7'h6;
parameter ADDR_YH       = BASEADDR + 7'h7;
parameter ADDR_CTL      = BASEADDR + 7'h8;

parameter OP_FLDR       = 8'h01;
parameter OP_FMOV       = 8'h02;
parameter OP_FADD       = 8'h03;
parameter OP_FSUB       = 8'h04;
parameter OP_FMUL       = 8'h05;
parameter OP_FDIV       = 8'h06;
parameter OP_FCONV24    = 8'h07;//pcap_float24 to ieee754_float32
parameter OP_F2INT      = 8'h08;


////////////////////////////////////////////////////////////
reg[31:0]  op_imm;
wire[31:0] op_x;
wire[31:0] op_y;

reg[31:0]  op_imm_f32;

reg[8:0] rX;
reg[8:0] rY;
reg[7:0] ctl;
reg busy;
reg zero;
reg negtive;

reg do_fadd;
reg do_fsub;
reg do_fmul;
reg do_fdiv;
reg do_f2int;

reg update_x;
reg update_y;

reg[31:0] mux_result;//wire
reg[7:0] _odata;//wire

////////////////////////////////////////////////////////////
wire[31:0] fas_q;
wire fas_valid;

wire[31:0] fmul_q;
wire fmul_valid;

wire[31:0] fdiv_q;
wire fdiv_valid;

wire[31:0] f2int_q;
wire f2int_valid;

wire        regfiles_we_a;
wire[8:0]   regfiles_addr_a;
wire[35:0]  regfiles_din_a;
wire[35:0]  regfiles_dout_a;

wire        regfiles_we_b;
wire[8:0]   regfiles_addr_b;
wire[35:0]  regfiles_din_b;
wire[35:0]  regfiles_dout_b;

////////////////////////////////////////////////////////////
FPU_fas fas_inst(
    .clk(clk),
    .rst(rst),

    .do_fadd(do_fadd),
    .do_fsub(do_fsub),
    .a(op_x),
    .b(op_y),

    .q(fas_q),
    .valid(fas_valid)
);

FPU_fmul fmul_inst(
    .clk(clk),
    .rst(rst),

    .do_fmul(do_fmul),
    .a(op_x),
    .b(op_y),

    .q(fmul_q),
    .valid(fmul_valid)
);

FPU_fdiv fdiv_inst(
    .clk(clk),
    .rst(rst),

    .do_fdiv(do_fdiv),
    .a(op_x),
    .b(op_y),

    .q(fdiv_q),
    .valid(fdiv_valid)
);

FPU_f2int f2int_inst(
    .clk(clk),
    .rst(rst),

    .do_f2int(do_f2int),
    .b(op_y),
    .q(f2int_q),
    .valid(f2int_valid)
);


FPU_regfiles regfiles_inst(
    .clk_a(clk),
    .we_a(regfiles_we_a),
    .addr_a(regfiles_addr_a),
    .din_a(regfiles_din_a),
    .dout_a(regfiles_dout_a),

    .clk_b(clk),
    .we_b(regfiles_we_b),
    .addr_b(regfiles_addr_b),
    .din_b(regfiles_din_b),
    .dout_b(regfiles_dout_b)
);



////////////////////////////////////////////////////////////
assign regfiles_addr_a[8:0] = rX[8:0];
assign regfiles_addr_b[8:0] = rY[8:0];
assign regfiles_we_a        = update_x;
assign regfiles_we_b        = update_y;
assign regfiles_din_a[35:0] = {4'h0, mux_result[31:0]};
assign regfiles_din_b[35:0] = {4'h0, op_imm[31:0]};

assign op_x[31:0] = regfiles_dout_a[31:0];
assign op_y[31:0] = regfiles_dout_b[31:0];

always@(*)
begin
    case (ctl)
        OP_FMOV:mux_result = op_y;
        OP_FMUL:mux_result = fmul_q;
        OP_FDIV:mux_result = fdiv_q;
        OP_F2INT:mux_result = f2int_q;
        default:mux_result = fas_q;
    endcase
end

////////////////////////////////////////////////////////////
always@(posedge clk)
begin
    if (rst)
        ctl <= 1'b0;
    else if (we && (addr == ADDR_CTL))
        ctl <= idata;
    else
        ctl <= ctl;
end

always@(posedge clk)
begin
    if (rst)
        do_fadd <= 1'b0;
    else if (we && (addr == ADDR_CTL) && (idata == OP_FADD))
        do_fadd <= 1'b1;
    else
        do_fadd <= 1'b0;
end

always@(posedge clk)
begin
    if (rst)
        do_fsub <= 1'b0;
    else if (we && (addr == ADDR_CTL) && (idata == OP_FSUB))
        do_fsub <= 1'b1;
    else
        do_fsub <= 1'b0;
end

always@(posedge clk)
begin
    if (rst)
        do_fmul <= 1'b0;
    else if (we && (addr == ADDR_CTL) && (idata == OP_FMUL))
        do_fmul <= 1'b1;
    else
        do_fmul <= 1'b0;
end

always@(posedge clk)
begin
    if (rst)
        do_fdiv <= 1'b0;
    else if (we && (addr == ADDR_CTL) && (idata == OP_FDIV))
        do_fdiv <= 1'b1;
    else
        do_fdiv <= 1'b0;
end

always@(posedge clk)
begin
    if (rst)
        do_f2int <= 1'b0;
    else if (we && (addr == ADDR_CTL) && (idata == OP_F2INT))
        do_f2int <= 1'b1;
    else
        do_f2int <= 1'b0;
end

always@(posedge clk)
begin
    if (rst)
        busy <= 1'b0;
    else if (we && (addr == ADDR_CTL) &&
        ((idata == OP_FADD) ||
        (idata == OP_FSUB) ||
        (idata == OP_FMUL) ||
        (idata == OP_FDIV) ||
        (idata == OP_F2INT)))
        busy <= 1'b1;
    else if (fas_valid || fmul_valid || fdiv_valid || f2int_valid)
        busy <= 1'b0;
    else
        busy <= busy;
end

always@(posedge clk)
begin
    if (rst)
        zero <= 1'b0;
    else if (fas_valid || fmul_valid || fdiv_valid || f2int_valid)
        if (mux_result[30:0] == 31'h0)
            zero <= 1'b0;
        else
            zero <= 1'b1;
    else
        zero <= zero;
end

always@(posedge clk)
begin
    if (rst)
        negtive <= 1'b0;
    else if (fas_valid || fmul_valid || fdiv_valid || f2int_valid)
        if (mux_result[31] == 1'b1)
            negtive <= 1'b1;
        else
            negtive <= 1'b0;
    else
        negtive <= negtive;
end

always@(posedge clk)
begin
    if (rst)
        update_x <= 1'b0;
    else if (we && (addr == ADDR_CTL) && (idata == OP_FMOV))
        update_x <= 1'b1;
    else if (fas_valid || fmul_valid || fdiv_valid || f2int_valid)
        update_x <= 1'b1;
    else
        update_x <= 1'b0;
end

always@(posedge clk)
begin
    if (rst)
        update_y <= 1'b0;
    else if (we && (addr == ADDR_CTL) && (idata == OP_FLDR))
        update_y <= 1'b1;
    else
        update_y <= 1'b0;
end

always@(posedge clk)
begin
    if (rst)
        rX[7:0] <= 0;
    else if (we && (addr == ADDR_XL))
        rX[7:0] <= idata[7:0];
    else
        rX[7:0] <= rX[7:0];
end

always@(posedge clk)
begin
    if (rst)
        rX[8] <= 0;
    else if (we && (addr == ADDR_XH))
        rX[8] <= idata[0];
    else
        rX[8] <= rX[8];
end

always@(posedge clk)
begin
    if (rst)
        rY[7:0] <= 0;
    else if (we && (addr == ADDR_YL))
        rY[7:0] <= idata[7:0];
    else
        rY[7:0] <= rY[7:0];
end

always@(posedge clk)
begin
    if (rst)
        rY[8] <= 0;
    else if (we && (addr == ADDR_YH))
        rY[8] <= idata[0];
    else
        rY[8] <= rY[8];
end

always@(posedge clk)
begin
    if (rst)
        op_imm[7:0] <= 0;
    else if (we && (addr == ADDR_DATA0))
        op_imm[7:0] <= idata[7:0];
    else if (we && (addr == ADDR_CTL) && (idata == OP_FCONV24))
        op_imm[7:0] <= op_imm_f32[7:0];
    else
        op_imm[7:0] <= op_imm[7:0];
end

always@(posedge clk)
begin
    if (rst)
        op_imm[15:8] <= 0;
    else if (we && (addr == ADDR_DATA1))
        op_imm[15:8] <= idata[7:0];
    else if (we && (addr == ADDR_CTL) && (idata == OP_FCONV24))
        op_imm[15:8] <= op_imm_f32[15:8];
    else
        op_imm[15:8] <= op_imm[15:8];
end

always@(posedge clk)
begin
    if (rst)
        op_imm[23:16] <= 0;
    else if (we && (addr == ADDR_DATA2))
        op_imm[23:16] <= idata[7:0];
    else if (we && (addr == ADDR_CTL) && (idata == OP_FCONV24))
        op_imm[23:16] <= op_imm_f32[23:16];
    else
        op_imm[23:16] <= op_imm[23:16];
end

always@(posedge clk)
begin
    if (rst)
        op_imm[31:24] <= 0;
    else if (we && (addr == ADDR_DATA3))
        op_imm[31:24] <= idata[7:0];
    else if (we && (addr == ADDR_CTL) && (idata == OP_FCONV24))
        op_imm[31:24] <= op_imm_f32[31:24];
    else
        op_imm[31:24] <= op_imm[31:24];
end

always@(posedge clk)
begin
    if (rst)
        op_imm_f32[31] <= 0;
    else
        op_imm_f32[31] <= 0;
end

always@(posedge clk)
begin
    if (rst)
        op_imm_f32[30:23] <= 0;
    else if (op_imm[7])
        op_imm_f32[30:23] <= 8'd127 + 8'd23 - {1'b0, op_imm[6:0]};
    else
        op_imm_f32[30:23] <= 8'd127 + 8'd23 + {1'b0, op_imm[6:0]};
end

always@(posedge clk)
begin
    if (rst)
        op_imm_f32[22:0] <= 0;
    else
        op_imm_f32[22:0] <= {op_imm[22:8], 8'h0};
end


always@(*)
begin
    case (addr)
        ADDR_DATA0:_odata = op_y[7:0];
        ADDR_DATA1:_odata = op_y[15:8];
        ADDR_DATA2:_odata = op_y[23:16];
        ADDR_DATA3:_odata = op_y[31:24];
        ADDR_XL:   _odata = rX[7:0];
        ADDR_XH:   _odata = {7'h0,rX[8]};
        ADDR_YL:   _odata = rY[7:0];
        ADDR_YH:   _odata = {7'h0,rY[8]};
        ADDR_CTL:  _odata = {busy, zero, negtive, 5'h0};
        default:   _odata = 8'h0;
    endcase
end

assign odata = _odata;


endmodule
