`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    12:09:23 09/01/2015 
// Design Name: 
// Module Name:    FPU_f2int 
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
module FPU_f2int(
    input clk,
    input rst,

    //do_f2int just pluse one clock
    //and wait 'valid' pluse.
    input        do_f2int,
    input[31:0]  b,
    output[31:0] q,
    output       valid
);

////////////////////////////////////////////////////////////
parameter ST_IDLE   = 4'd0;
parameter ST_SHIFT  = 4'd1;
parameter ST_ZERO   = 4'd2;
parameter ST_OVFL   = 4'd3;
parameter ST_DONE   = 4'd4;

reg[3:0]  next_state;
reg[3:0]  state;

reg       rY_s;
reg[8:0]  rY_exponent;
reg[31:0] rY_significand;

reg[8:0]   shift_n;
reg        shift_left;
wire[5:0]  Y_shrn_n;
wire       Y_shrn_left;
wire[31:0] Y_shift_q;

reg[31:0] result;
reg _valid;

////////////////////////////////////////////////////////////
shift32 shift32_rY0_shrn_inst(
    .shift_n(Y_shrn_n),
    .shift_left(Y_shrn_left),
    .v(rY_significand),
    .q(Y_shift_q)
);

assign Y_shrn_n[5:0] = shift_n[5:0];
assign Y_shrn_left = shift_left;

////////////////////////////////////////////////////////////
//  shift = exponent - 23;
//  if (shift > 127) {
//      vfinal = significand << (shift - 127);
//  } else {
//      vfinal = significand >> (127 - shift);
//  }
//
//  let vfinal = 0:
//      <=> 0 = significand >> (127 - shift);
//      <=> 0 = significand >> 24
//  so shift = 103
//
//  let vfinal overflow:
//      <=> significand << (shift - 127)
//      <=> significand << 9
//  so shift = 136
//
//  if (exponent < 126) {
//      vfinal = 0;
//  }
//  if (exponent > 159) {
//      vfinal overflow;
//  }
//
//
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
            if (do_f2int)
                if (b[30:23] <= 9'd126)
                    next_state = ST_ZERO;
                else if (b[30:23] >= 9'd159)
                    next_state = ST_OVFL;
                else
                    next_state = ST_SHIFT;
            else
                next_state = ST_IDLE;
        end
        ST_SHIFT:begin
            next_state = ST_DONE;
        end
        ST_DONE:begin
            next_state = ST_IDLE;
        end

        ST_ZERO:begin
            next_state = ST_IDLE;
        end
        ST_OVFL:begin
            next_state = ST_IDLE;
        end
        default:begin
            next_state = ST_IDLE;
        end
    endcase
end

////////////////////////////////////////////////////////////
always@(posedge clk)
begin
    if (rst) begin
        rY_s           <= 0;
        rY_exponent    <= 0;
        rY_significand <= 0;
    end
    else if (do_f2int) begin
        rY_s           <= b[31];
        rY_exponent    <= {1'b0, b[30:23]};
        rY_significand <= {8'h0, 1'b1, b[22:0]};
    end
    else begin
        rY_s           <= rY_s;
        rY_exponent    <= rY_exponent;
        rY_significand <= rY_significand;
    end
end

always@(posedge clk)
begin
    if (rst)
        result <= 0;
    else if (state == ST_ZERO)
        result <= 32'h0;
    else if (state == ST_OVFL)
        result <= 32'hFFFFFFFF;
    else if (state == ST_DONE)
        result <= Y_shift_q;
    else
        result <= result;
end

always@(posedge clk)
begin
    if (rst) begin
        shift_left  <= 0;
        shift_n     <= 0;
    end
    else if (state == ST_SHIFT) begin
        if (rY_exponent > 9'd150) begin
            shift_left  <= 1;
            shift_n     <= rY_exponent - 9'd150;
        end
        else begin
            shift_left  <= 0;
            shift_n     <= 9'd150 - rY_exponent;
        end
    end
    else begin
        shift_left  <= shift_left;
        shift_n     <= shift_n;
    end
end

always@(posedge clk)
begin
    if (rst)
        _valid <= 0;
    else if ((state == ST_DONE) || (state == ST_OVFL) || (state == ST_ZERO))
        _valid <= 1;
    else
        _valid <= 0;
end

assign q = result;
assign valid = _valid;


endmodule
