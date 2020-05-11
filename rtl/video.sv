//
// Specialist display implementation
// 
// Copyright (c) 2016 Sorgelig
//
// 
// This source file is free software: you can redistribute it and/or modify 
// it under the terms of the GNU General Public License as published 
// by the Free Software Foundation, either version 3 of the License, or 
// (at your option) any later version. 
// 
// This source file is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of 
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the 
// GNU General Public License for more details.
// 
// You should have received a copy of the GNU General Public License 
// along with this program.  If not, see <http://www.gnu.org/licenses/>. 
//


`timescale 1ns / 1ps

module video
(
	// Clocks
	input         clk_sys,
	input         ce_pix_p, // Video clock enable (16 MHz)
	input         ce_pix_n, // Video clock enable (16 MHz)
	output        ce_pix,

	// Video outputs
	output  [7:0] VGA_R,
	output  [7:0] VGA_G,
	output  [7:0] VGA_B,
	output        VGA_VS,
	output        VGA_HS,
	output        VGA_DE,

	// TV/VGA
	input         scandoubler,
	input         hq2x,
	inout  [21:0] gamma_bus,

	// CPU bus
	input	 [15:0] addr,
	input	  [7:0] din,
	input			  we,
	
	// Misc signals
	input	  [7:0] color,
	input	        mx,
	input         bw_mode
);

reg [8:0] hc;
reg [8:0] vc;
reg       HSync, HBlank;
reg       VSync, VBlank;
reg [7:0] bmp;
reg [7:0] rgb;
wire      blank = HBlank | VBlank;

always @(posedge clk_sys) begin
	if(ce_pix_p) begin
		if(hc == 511) begin 
			hc <=0;
			if (vc == 311) begin 
				vc <= 9'd0;
			end else begin
				vc <= vc + 1'd1;
			end
		end else hc <= hc + 1'd1;

		if(hc == 415) begin
			HSync  <= 1;
			if(vc == 271) VSync  <= 1;
			if(vc == 281) VSync  <= 0;
		end
		if(hc == 463) HSync  <= 0;
	end
	if(ce_pix_n) begin
		bmp <= {bmp[6:0], 1'b0};
		if(!hc[2:0] & ~(hc[8] & hc[7]) & ~vc[8]) {rgb, bmp} <= vram_o;
		HBlank <= hc[8] & hc[7];
		VBlank <= vc[8];
	end
end

wire [15:0] vram_o;
dpram vram
(
	.clock(clk_sys),
	.wraddress(addr[13:0]-14'h1000),
	.data({color,din}),
	.wren(we & addr[15] & ~addr[14] & (addr[13] | addr[12])),
	.rdaddress({hc[8:3], vc[7:0]}),
	.q(vram_o)
);

wire [2:0] R,  G,  B;

always_comb begin
	casex({blank, bw_mode, mx})
		3'b1XX: {R,G,B} = {9{1'b0}};
		2'b01X: {R,G,B} = {9{bmp[7]}};
		2'b000: begin
			R = {3{bmp[7] & rgb[6]}};
			G = {3{bmp[7] & rgb[5]}};
			B = {3{bmp[7] & rgb[4]}};
		end
		2'b001: begin
			R = bmp[7] ? {rgb[6],rgb[7],rgb[6]} : {rgb[2],rgb[3],rgb[2]};
			G = bmp[7] ? {rgb[5],rgb[7],rgb[5]} : {rgb[1],rgb[3],rgb[1]};
			B = bmp[7] ? {rgb[4],rgb[7],rgb[4]} : {rgb[0],rgb[3],rgb[0]};
		end
	endcase
end

video_mixer #(.LINE_LENGTH(512), .HALF_DEPTH(1), .GAMMA(1)) video_mixer
(
	.*,

	.clk_vid(clk_sys),
	.ce_pix(ce_pix_p),
	.ce_pix_out(ce_pix),
	
	.R({R, R[2]}),
	.G({G, G[2]}),
	.B({B, B[2]}),

	.scanlines(0),

	.mono(0)
);

endmodule
