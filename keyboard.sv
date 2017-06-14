// ====================================================================
//                Radio-86RK FPGA REPLICA
//
//            Copyright (C) 2011 Dmitry Tselikov
//
// This core is distributed under modified BSD license. 
// For complete licensing information see LICENSE.TXT.
// -------------------------------------------------------------------- 
//
// An open implementation of Radio-86RK keyboard
//
// Author: Dmitry Tselikov   http://bashkiria-2m.narod.ru/
// 
//

module keyboard
(
	input           reset,
	input           clk_sys,

	input           ps2_kbd_clk,
	input           ps2_kbd_data,

	input           mx,
	input     [5:0] row_in,
	output   [11:0] col_out,
	input    [11:0] col_in,
	output    [5:0] row_out,
	output          nr,

	output reg      color_key,
	output reg[1:0] reset_key
);

assign nr = ~knr;
reg  knr;

reg [11:0] col_state[5:0];
assign col_out =~((col_state[0] & {12{~row_in[0]}})|
						(col_state[1] & {12{~row_in[1]}})|
						(col_state[2] & {12{~row_in[2]}})|
						(col_state[3] & {12{~row_in[3]}})|
						(col_state[4] & {12{~row_in[4]}})|
						(col_state[5] & {12{~row_in[5]}}));


reg [5:0] row_state[11:0];
assign row_out =~((row_state[0]  & {6{~col_in[0]}})|
						(row_state[1]  & {6{~col_in[1]}})|
						(row_state[2]  & {6{~col_in[2]}})|
						(row_state[3]  & {6{~col_in[3]}})|
						(row_state[4]  & {6{~col_in[4]}})|
						(row_state[5]  & {6{~col_in[5]}})|
						(row_state[6]  & {6{~col_in[6]}})|
						(row_state[7]  & {6{~col_in[7]}})|
						(row_state[8]  & {6{~col_in[8]}})|
						(row_state[9]  & {6{~col_in[9]}})|
						(row_state[10] & {6{~col_in[10]}})|
						(row_state[11] & {6{~col_in[11]}}));

reg  [2:0] c;
reg  [3:0] r;
reg [11:0] shift_reg;

wire[11:0] kdata = {ps2_kbd_data,shift_reg[11:1]};
wire [7:0] kcode = kdata[9:2];

/*
   5    5MX  4   3   2   1   0
0  CLS  CLS  -=  :*  .>  ЗБ  ВК    
1  NEG  NEG  0   ХH  Э\  /?  ПС
2  POS  POS  9)  ЗZ  ЖV  ,<  Right
3  EDIT F7   8(  Щ]  ДD  Ю@  ПВ
4  F8   F6   7,  Ш[  ЛL  БB  Left
5  F7   F5   6&  ГG  ОO  ЬX  Space
6  F6   F4   5%  НN  РR  ТT  АР2
7  F5   F3   4$  ЕE  ПP  ИI  Tab
8  F4   F2   3#  КK  АA  МM  Down
9  F3   F1   2"  УU  ВW  СS  Up
A  F2   KOI  1!  ЦC  ЫY  Ч^  Home
B  F1   ESC  ;+  ЙJ  ФF  ЯQ  Ru/En
C                            NR
*/

always @(*) begin
	casex({mx, 3'b0,knr, kcode})

	13'hXX09: {c,r} = 7'h50; // F10    - CLS
	13'hXX71: {c,r} = 7'h51; // DELETE - TF
	13'hXX70: {c,r} = 7'h52; // INSERT - SF

	13'h0X01: {c,r} = 7'h53; // F9 - EDIT
	13'h0X0A: {c,r} = 7'h54; // F8
	13'h0X83: {c,r} = 7'h55; // F7
	13'h0X0B: {c,r} = 7'h56; // F6
	13'h0X03: {c,r} = 7'h57; // F5
	13'h0X0C: {c,r} = 7'h58; // F4
	13'h0X04: {c,r} = 7'h59; // F3
	13'h0X06: {c,r} = 7'h5A; // F2
	13'h0X05: {c,r} = 7'h5B; // F1

	13'h1X83: {c,r} = 7'h53; // F7
	13'h1X0B: {c,r} = 7'h54; // F6
	13'h1X03: {c,r} = 7'h55; // F5
	13'h1X0C: {c,r} = 7'h56; // F4
	13'h1X04: {c,r} = 7'h57; // F3
	13'h1X06: {c,r} = 7'h58; // F2
	13'h1X05: {c,r} = 7'h59; // F1
	13'h1X0A: {c,r} = 7'h5A; // F8 - KOI
	13'h1X76: {c,r} = 7'h5B; // Esc

	13'hXX4E: {c,r} = 7'h40; // -
	13'hX045: {c,r} = 7'h41; // 0
	13'hX046: {c,r} = 7'h42; // 9
	13'hX03E: {c,r} = 7'h43; // 8
	13'hX03D: {c,r} = 7'h44; // 7
	13'hX036: {c,r} = 7'h45; // 6
	13'hXX2E: {c,r} = 7'h46; // 5
	13'hXX25: {c,r} = 7'h47; // 4
	13'hXX26: {c,r} = 7'h48; // 3
	13'hXX1E: {c,r} = 7'h49; // 2
	13'hXX16: {c,r} = 7'h4A; // 1
	13'hXX55: {c,r} = 7'h4B; // =

	13'hX145: {c,r} = 7'h42; // )
	13'hX146: {c,r} = 7'h43; // (
	13'hX13E: {c,r} = 7'h30; // *
	13'hX13D: {c,r} = 7'h45; // &
	13'hX136: {c,r} = 7'h44; // '
	
	13'hXX4C: {c,r} = 7'h30; // ;
	13'hXX33: {c,r} = 7'h31; // H
	13'hXX1A: {c,r} = 7'h32; // Z
	13'hXX5B: {c,r} = 7'h33; // ]
	13'hXX54: {c,r} = 7'h34; // [
	13'hXX34: {c,r} = 7'h35; // G
	13'hXX31: {c,r} = 7'h36; // N
	13'hXX24: {c,r} = 7'h37; // E
	13'hXX42: {c,r} = 7'h38; // K
	13'hXX3C: {c,r} = 7'h39; // U
	13'hXX21: {c,r} = 7'h3A; // C
	13'hXX3B: {c,r} = 7'h3B; // J

	13'hXX49: {c,r} = 7'h20; // .
	13'hXX5D: {c,r} = 7'h21; // \
	13'hXX2A: {c,r} = 7'h22; // V
	13'hXX23: {c,r} = 7'h23; // D
	13'hXX4B: {c,r} = 7'h24; // L
	13'hXX44: {c,r} = 7'h25; // O
	13'hXX2D: {c,r} = 7'h26; // R
	13'hXX4D: {c,r} = 7'h27; // P
	13'hXX1C: {c,r} = 7'h28; // A
	13'hXX1D: {c,r} = 7'h29; // W
	13'hXX35: {c,r} = 7'h2A; // Y
	13'hXX2B: {c,r} = 7'h2B; // F

	13'hXX66: {c,r} = 7'h10; // bksp
	13'hXX4A: {c,r} = 7'h11; // /
	13'hXX41: {c,r} = 7'h12; // ,
	13'hXX52: {c,r} = 7'h13; // ' - @
	13'hXX32: {c,r} = 7'h14; // B
	13'hXX22: {c,r} = 7'h15; // X
	13'hXX2C: {c,r} = 7'h16; // T
	13'hXX43: {c,r} = 7'h17; // I
	13'hXX3A: {c,r} = 7'h18; // M
	13'hXX1B: {c,r} = 7'h19; // S
	13'hXX0E: {c,r} = 7'h1A; // ` - ^
	13'hXX15: {c,r} = 7'h1B; // Q

	13'hXX5A: {c,r} = 7'h00; // enter
	13'hXX59: {c,r} = 7'h01; // rshift - PS
	13'hXX74: {c,r} = 7'h02; // right
	13'hXX1F: {c,r} = 7'h03; // LWin - PV
	13'hXX27: {c,r} = 7'h03; // RWin - PV
	13'hXX6B: {c,r} = 7'h04; // left
	13'hXX29: {c,r} = 7'h05; // space
	13'hXX11: {c,r} = 7'h06; // alt - AR2
	13'hXX0D: {c,r} = 7'h07; // tab
	13'hXX72: {c,r} = 7'h08; // down
	13'hXX75: {c,r} = 7'h09; // up
	13'hXX6C: {c,r} = 7'h0A; // home
	13'hXX58: {c,r} = 7'h0B; // caps - RUS/LAT

	13'hXX12: {c,r} = 7'h0C; // lshift - NR

	default: {c,r} = 7'h7F;
	endcase
end

always @(posedge clk_sys) begin
	reg mctrl, malt;
	reg old_reset;
	reg unpress;
	reg [3:0] prev_clk;

	color_key <= 0;
	old_reset <= reset;
	if(!old_reset && reset) begin
		prev_clk <= 0;
		shift_reg <= 12'hFFF;
		unpress <= 0;
		col_state <= '{default:0};
		row_state <= '{default:0};
	end else begin
		prev_clk <= {ps2_kbd_clk,prev_clk[3:1]};
		if (prev_clk==4'b1) begin
			if (kdata[11]==1'b1 && ^kdata[10:2]==1'b1 && kdata[1:0]==2'b1) begin
				shift_reg <= 12'hFFF;
				if (kcode==8'h14) mctrl     <= ~unpress;
				if (kcode==8'h11) malt      <= ~unpress;
				if (kcode==8'h78) {color_key, reset_key} <= {~(malt | mctrl) & ~unpress, malt & ~unpress, (malt | mctrl) & ~unpress};
				if (kcode==8'hF0) unpress   <= 1;
				else begin
					unpress <= 0;
					if((~mctrl | unpress) & (r != 4'hF)) begin
						if(r == 4'hC) knr <= ~unpress;
						else begin
							col_state[c][r] <= ~unpress;
							row_state[r][c] <= ~unpress;
						end
					end
				end
			end else begin
				shift_reg <= kdata;
			end
		end
	end
end

endmodule
