// ====================================================================
//                Specialist FPGA REPLICA
//
//            Copyright (C) 2016-2019 Sorgelig
//
// This core is distributed under modified GNU GPL v2 license. 
// For complete licensing information see LICENSE.TXT.
// -------------------------------------------------------------------- 
//
//
// 

module emu
(
	//Master input clock
	input         CLK_50M,

	//Async reset from top-level module.
	//Can be used as initial reset.
	input         RESET,

	//Must be passed to hps_io module
	inout  [48:0] HPS_BUS,

	//Base video clock. Usually equals to CLK_SYS.
	output        CLK_VIDEO,

	//Multiple resolutions are supported using different CE_PIXEL rates.
	//Must be based on CLK_VIDEO
	output        CE_PIXEL,

	//Video aspect ratio for HDMI. Most retro systems have ratio 4:3.
	//if VIDEO_ARX[12] or VIDEO_ARY[12] is set then [11:0] contains scaled size instead of aspect ratio.
	output [12:0] VIDEO_ARX,
	output [12:0] VIDEO_ARY,

	output  [7:0] VGA_R,
	output  [7:0] VGA_G,
	output  [7:0] VGA_B,
	output        VGA_HS,
	output        VGA_VS,
	output        VGA_DE,    // = ~(VBlank | HBlank)
	output        VGA_F1,
	output [1:0]  VGA_SL,
	output        VGA_SCALER, // Force VGA scaler
	output        VGA_DISABLE, // analog out is off

	input  [11:0] HDMI_WIDTH,
	input  [11:0] HDMI_HEIGHT,
	output        HDMI_FREEZE,

`ifdef MISTER_FB
	// Use framebuffer in DDRAM
	// FB_FORMAT:
	//    [2:0] : 011=8bpp(palette) 100=16bpp 101=24bpp 110=32bpp
	//    [3]   : 0=16bits 565 1=16bits 1555
	//    [4]   : 0=RGB  1=BGR (for 16/24/32 modes)
	//
	// FB_STRIDE either 0 (rounded to 256 bytes) or multiple of pixel size (in bytes)
	output        FB_EN,
	output  [4:0] FB_FORMAT,
	output [11:0] FB_WIDTH,
	output [11:0] FB_HEIGHT,
	output [31:0] FB_BASE,
	output [13:0] FB_STRIDE,
	input         FB_VBL,
	input         FB_LL,
	output        FB_FORCE_BLANK,

`ifdef MISTER_FB_PALETTE
	// Palette control for 8bit modes.
	// Ignored for other video modes.
	output        FB_PAL_CLK,
	output  [7:0] FB_PAL_ADDR,
	output [23:0] FB_PAL_DOUT,
	input  [23:0] FB_PAL_DIN,
	output        FB_PAL_WR,
`endif
`endif

	output        LED_USER,  // 1 - ON, 0 - OFF.

	// b[1]: 0 - LED status is system status OR'd with b[0]
	//       1 - LED status is controled solely by b[0]
	// hint: supply 2'b00 to let the system control the LED.
	output  [1:0] LED_POWER,
	output  [1:0] LED_DISK,

	// I/O board button press simulation (active high)
	// b[1]: user button
	// b[0]: osd button
	output  [1:0] BUTTONS,

	input         CLK_AUDIO, // 24.576 MHz
	output [15:0] AUDIO_L,
	output [15:0] AUDIO_R,
	output        AUDIO_S,   // 1 - signed audio samples, 0 - unsigned
	output  [1:0] AUDIO_MIX, // 0 - no mix, 1 - 25%, 2 - 50%, 3 - 100% (mono)

	//ADC
	inout   [3:0] ADC_BUS,

	//SD-SPI
	output        SD_SCK,
	output        SD_MOSI,
	input         SD_MISO,
	output        SD_CS,
	input         SD_CD,

	//High latency DDR3 RAM interface
	//Use for non-critical time purposes
	output        DDRAM_CLK,
	input         DDRAM_BUSY,
	output  [7:0] DDRAM_BURSTCNT,
	output [28:0] DDRAM_ADDR,
	input  [63:0] DDRAM_DOUT,
	input         DDRAM_DOUT_READY,
	output        DDRAM_RD,
	output [63:0] DDRAM_DIN,
	output  [7:0] DDRAM_BE,
	output        DDRAM_WE,

	//SDRAM interface with lower latency
	output        SDRAM_CLK,
	output        SDRAM_CKE,
	output [12:0] SDRAM_A,
	output  [1:0] SDRAM_BA,
	inout  [15:0] SDRAM_DQ,
	output        SDRAM_DQML,
	output        SDRAM_DQMH,
	output        SDRAM_nCS,
	output        SDRAM_nCAS,
	output        SDRAM_nRAS,
	output        SDRAM_nWE,

`ifdef MISTER_DUAL_SDRAM
	//Secondary SDRAM
	//Set all output SDRAM_* signals to Z ASAP if SDRAM2_EN is 0
	input         SDRAM2_EN,
	output        SDRAM2_CLK,
	output [12:0] SDRAM2_A,
	output  [1:0] SDRAM2_BA,
	inout  [15:0] SDRAM2_DQ,
	output        SDRAM2_nCS,
	output        SDRAM2_nCAS,
	output        SDRAM2_nRAS,
	output        SDRAM2_nWE,
`endif

	input         UART_CTS,
	output        UART_RTS,
	input         UART_RXD,
	output        UART_TXD,
	output        UART_DTR,
	input         UART_DSR,

	// Open-drain User port.
	// 0 - D+/RX
	// 1 - D-/TX
	// 2..6 - USR2..USR6
	// Set USER_OUT to 1 to read from USER_IN.
	input   [6:0] USER_IN,
	output  [6:0] USER_OUT,

	input         OSD_STATUS
);

assign ADC_BUS  = 'Z;
assign USER_OUT = '1;
assign {UART_RTS, UART_TXD, UART_DTR} = 0;
assign {SDRAM_DQ, SDRAM_A, SDRAM_BA, SDRAM_CLK, SDRAM_CKE, SDRAM_DQML, SDRAM_DQMH, SDRAM_nWE, SDRAM_nCAS, SDRAM_nRAS, SDRAM_nCS} = 'Z;
assign {DDRAM_CLK, DDRAM_BURSTCNT, DDRAM_ADDR, DDRAM_DIN, DDRAM_BE, DDRAM_RD, DDRAM_WE} = 0;
assign {SD_SCK, SD_MOSI, SD_CS} = 'Z;

assign AUDIO_S   = 0;

assign LED_USER  = filling;
assign LED_DISK  = 0;
assign LED_POWER = 0;
assign BUTTONS   = 0;
assign VGA_SCALER= 0;
assign VGA_DISABLE = 0;
assign HDMI_FREEZE = 0;

wire [1:0] ar = status[10:9];
video_freak video_freak
(
	.*,
	.VGA_DE_IN(VGA_DE),
	.VGA_DE(),

	.ARX((!ar) ? 12'd4 : (ar - 1'd1)),
	.ARY((!ar) ? 12'd3 : 12'd0),
	.CROP_SIZE(0),
	.CROP_OFF(0),
	.SCALE(status[12:11])
);

assign CLK_VIDEO = clk_sys;

`include "build_id.v"
localparam CONF_STR =
{
	"SPMX;;",
	"-;",
	"F0,RKS,Load Tape;",
	"S0,ODI,Mount Disk;",
	"-;",
	"O9A,Aspect ratio,Original,Full Screen,[ARC1],[ARC2];",
	"O78,Scandoubler Fx,None,HQ2x,CRT 25%,CRT 50%;",
	"OBC,Scale,Normal,V-Integer,Narrower HV-Integer,Wider HV-Integer;",
	"-;",
	"O4,CPU Speed,2MHz,4MHz;",
	"O23,Model,Original,MX & Disk,MX;",
	"-;",
	"R6,Cold Reset;",
	"V,v",`BUILD_DATE
};


///////////////////   HPS I/O   //////////////////
wire [31:0] status;
wire  [1:0] buttons;
wire        forced_scandoubler;
wire [10:0] ps2_key;
wire [21:0] gamma_bus;

wire        ioctl_wr;
wire [24:0] ioctl_addr;
wire  [7:0] ioctl_dout;
wire        ioctl_download;
wire  [7:0] ioctl_index;
wire        rks_load =  (ioctl_download && !ioctl_index);

wire [31:0] sd_lba;
wire        sd_rd;
wire        sd_wr;
wire        sd_ack;
wire  [8:0] sd_buff_addr;
wire  [7:0] sd_buff_dout;
wire  [7:0] sd_buff_din;
wire        sd_buff_wr;
wire        img_mounted;
wire [63:0] img_size;

hps_io #(.CONF_STR(CONF_STR)) hps_io 
(
	.clk_sys(clk_sys),

	.HPS_BUS(HPS_BUS),
	
	.ps2_key(ps2_key),

	.buttons(buttons),
	.forced_scandoubler(forced_scandoubler),
	.status(status),
	.gamma_bus(gamma_bus),

	.sd_lba('{sd_lba}),
	.sd_rd(sd_rd),
	.sd_wr(sd_wr),
	.sd_ack(sd_ack),
	.sd_buff_addr(sd_buff_addr),
	.sd_buff_dout(sd_buff_dout),
	.sd_buff_din('{sd_buff_din}),
	.sd_buff_wr(sd_buff_wr),
	.img_mounted(img_mounted),
	.img_size(img_size),

	.ioctl_wr(ioctl_wr),
	.ioctl_addr(ioctl_addr),
	.ioctl_dout(ioctl_dout),
	.ioctl_download(ioctl_download),
	.ioctl_index(ioctl_index)  
);


////////////////////   CLOCKS   ///////////////////
wire locked;
pll pll
(
	.refclk(CLK_50M),
	.rst(0),
	.outclk_0(clk_sys),
	.locked(locked)
);

wire clk_sys;       // 96MHz
reg  ce_f1,ce_f2;   // 2MHz/4MHz
reg  ce_pit;        // 2MHz
reg  ce_pix_p;      // 16MHz
reg  ce_pix_n;      // 16MHz

always @(negedge clk_sys) begin
	reg [3:0] clk_viddiv;
	reg [5:0] cpu_div = 0;
	reg       turbo = 0;

	clk_viddiv <= clk_viddiv + 1'd1;
	if(clk_viddiv == 11) clk_viddiv <=0;
	ce_pix_p <= (clk_viddiv == 0);
	ce_pix_n <= (clk_viddiv == 6);

	cpu_div <= cpu_div + 1'd1;
	if(cpu_div == 47) begin 
		cpu_div <= 0;
		turbo <= status[4];
	end
	ce_f1  <= ((cpu_div == 0)  | (turbo & (cpu_div == 24)));
	ce_f2  <= ((cpu_div == 12) | (turbo & (cpu_div == 36)));
	ce_pit <= !cpu_div;
end


////////////////////   RESET   ////////////////////
reg       reset = 0;
reg [7:0] mon;

reg       sys_ready = 0;
always @(posedge clk_sys) begin
	reg old_rst = 0;

	old_rst <= status[0];
	if(old_rst & ~status[0]) sys_ready <= 1;

	if(RESET | ~sys_ready | buttons[1] | reset_key[0] | erasing) begin
		mx    <= (status[3:2] >0);
		mxd   <= (status[3:2]==1) && ~reset_key[1];
		mon   <= (status[3:2]==0) ? 8'h1C : ((status[3:2]==1) && reset_key[1]) ? 8'h0C : 8'h1D;
		reset <= 1;
	end else begin
		reset <= 0;
	end
end


//////////////////   MEMORY   ////////////////////
wire  [7:0] ram_dout;

memory memory
(
	.clock(clk_sys),

	.address_a(fill_addr[18:0]),
	.data_a(fill_data),
	.wren_a(fill_wr && (fill_addr[18:16] != 1)),
	.q_a(),

	.address_b(ram_addr[18:0]),
	.data_b(cpu_o),
	.wren_b(~cpu_wr_n && ~rom_sel && (ram_addr < 393216)),
	.q_b(ram_dout)
);

wire [7:0] mem_o = (ram_addr < 393216) ? ram_dout : 8'hFF;

reg  [3:0] page = 1;
wire       romp = (page == 1);
always @(posedge clk_sys) begin
	reg old_wr;
	old_wr <= cpu_wr_n;

	if(reset) begin
		page <= 1;
	end else if(rks_load) begin
		page <= 0;
	end else begin
		if(old_wr & ~cpu_wr_n & page_sel & mxd) begin
			casex(addrbus[1:0])
				2'b00: page <= 4'd0;
				2'b01: page <= 4'd2 + cpu_o[2:0];
				2'b1X: page <= 4'd1;
			endcase
		end
		if(~(mx & mxd) & addrbus[15]) page <= 0;
	end
end

reg [24:0] ram_addr;
always_comb begin
	casex({mxd, base_sel, rom_sel})
		//without disk
		4'b0_X0: ram_addr = addrbus;
		4'b0_X1: ram_addr = {mon,  addrbus[11:0]};

		//with disk
		4'b1_1X: ram_addr = addrbus;
		4'b1_0X: ram_addr = {page, addrbus};
	endcase
end


////////////////////   MMU   ////////////////////
reg ppi1_sel;
reg ppi2_sel;
reg pit_sel;
reg pal_sel;
reg page_sel;
reg base_sel;
reg rom_sel;
reg fdd_sel;
reg fdd2_sel;
reg mx;
reg mxd;

always_comb begin
	ppi1_sel = 0;
	ppi2_sel = 0;
	pit_sel  = 0;
	pal_sel  = 0;
	page_sel = 0;
	base_sel = 0;
	rom_sel  = 0;
	fdd_sel  = 0;
	fdd2_sel = 0;
	cpu_i    = 255;
	casex({mx, mxd, romp, addrbus})

		//MX
		'b11_1_0XXXXXXX_XXXXXXXX: begin cpu_i = mem_o;  rom_sel  = 1;    end
		'b11_1_10XXXXXX_XXXXXXXX: begin cpu_i = mem_o;  rom_sel  = 1;    end
		'b10_1_0000XXXX_XXXXXXXX: begin cpu_i = mem_o;  rom_sel  = 1;    end
		'b10_X_1100XXXX_XXXXXXXX: begin cpu_i = mem_o;  rom_sel  = 1;    end
		'b1X_X_11111111_110XXXXX: begin cpu_i = mem_o;  base_sel = 1;    end
		'b1X_X_11111111_111000XX: begin cpu_i = ppi1_o; ppi1_sel = 1;    end
		'b1X_X_11111111_111001XX: begin cpu_i = ppi2_o; ppi2_sel = 1;    end
		'b1X_X_11111111_111010XX: begin cpu_i = fdd_o;  fdd_sel  = 1;    end
		'b1X_X_11111111_111011XX: begin cpu_i = pit_o;  pit_sel  = 1;    end
		'b1X_X_11111111_111100XX: begin                 fdd2_sel = 1;    end
		'b1X_X_11111111_111101XX: begin                                  end
		'b1X_X_11111111_111110XX: begin                 pal_sel  = 1;    end
		'b1X_X_11111111_111111XX: begin                 page_sel = 1;    end

		//Original
		'b0X_1_0000XXXX_XXXXXXXX: begin cpu_i = mem_o;  rom_sel  = 1;    end
		'b0X_X_1100XXXX_XXXXXXXX: begin cpu_i = mem_o;  rom_sel  = 1;    end
		'b0X_X_11110XXX_XXXXXXXX: begin cpu_i = ppi2_o; ppi2_sel = 1;    end
		'b0X_X_11111XXX_XXXXXXXX: begin cpu_i = ppi1_o; ppi1_sel = 1;    end

							  default: begin cpu_i = mem_o;  base_sel = romp; end
	endcase
end


////////////////////   CPU   ////////////////////
wire [15:0] addrbus;
reg   [7:0] cpu_i;
wire  [7:0] cpu_o;
wire        cpu_rd;
wire        cpu_wr_n;
reg         cpu_hold = 0;

k580vm80a cpu
(
   .pin_clk(clk_sys),
   .pin_f1(ce_f1),
   .pin_f2(ce_f2),
   .pin_reset(reset | rks_load),
   .pin_a(addrbus),
   .pin_dout(cpu_o),
   .pin_din(cpu_i),
   .pin_hold(cpu_hold),
   .pin_ready(1),
   .pin_int(0),
   .pin_dbin(cpu_rd),
   .pin_wr_n(cpu_wr_n)
);


////////////////////   VIDEO   ////////////////////
wire [2:0] color;
reg  [7:0] color_mx;
reg        bw_mode;

wire [1:0] scale = status[8:7];

wire       HSync,HBlank,VSync,VBlank;
wire [2:0] R,G,B;

video video
(
	.*,
	.addr(addrbus),
	.din(cpu_o),
	.we(~cpu_wr_n && !page),
	.color(mx ? color_mx : {1'b0, ~color[1], ~color[2], ~color[0], 4'b0000})
);

always @(posedge clk_sys) begin
	reg old_wr, old_key;
	old_wr <= cpu_wr_n;
	if(reset | rks_load) color_mx <= 8'hF0;
		else if(old_wr & ~cpu_wr_n & pal_sel) color_mx <= cpu_o;
	
	old_key <= color_key;
	if(~old_key & color_key) bw_mode <= ~bw_mode;
end

assign VGA_SL = scale ? scale - 1'd1 : 2'd0;
assign VGA_F1 = 0;

video_mixer #(.LINE_LENGTH(512), .HALF_DEPTH(1), .GAMMA(1)) video_mixer
(
	.*,
	.ce_pix(ce_pix_p),
	.hq2x(scale==1),
	.scandoubler(scale || forced_scandoubler),
	.freeze_sync(),

	.R({R, R[2]}),
	.G({G, G[2]}),
	.B({B, B[2]})
);

//////////////////   KEYBOARD   ///////////////////
wire  [5:0] row_in;
wire [11:0] col_out;
wire [11:0] col_in;
wire  [5:0] row_out;
wire        nr;
wire  [1:0] reset_key;
wire        color_key;

keyboard keyboard(.*);


////////////////////   SYS PPI   ////////////////////
wire [7:0] ppi1_o;

k580vv55 ppi1
(
	.clk_sys(clk_sys),

	.addr(addrbus[1:0]),
	.we_n(cpu_wr_n | ~ppi1_sel),
	.idata(cpu_o),
	.odata(ppi1_o),

	.ipa(col_out[7:0]),
	.ipc({4'b1111, col_out[11:8]}),
	.opb({row_in, 2'bZZ}),

	.opa(col_in[7:0]),
	.opc({color[2], color[1], spk_out, color[0], col_in[11:8]}),
	.ipb({row_out, nr, 1'b0})
);


///////////////////   MISC PPI   ////////////////////
wire [7:0] ppi2_o;
wire [7:0] ppi2_a;
wire [7:0] ppi2_b;
wire [7:0] ppi2_c;

k580vv55 ppi2
(
	.reset(reset),
	.clk_sys(clk_sys),

	.addr(addrbus[1:0]), 
	.we_n(cpu_wr_n | ~ppi2_sel),
	.idata(cpu_o), 
	.odata(ppi2_o), 
	.ipa({ppi2_a[7:1], pit_out[2]}), 
	.opa(ppi2_a),
	.ipb(ppi2_b),
	.opb(ppi2_b),
	.ipc(ppi2_c),
	.opc(ppi2_c)
);


////////////////////   SOUND   ////////////////////
reg spk_out;
assign AUDIO_R = {16{(pit_out[0] | pit_o[2]) & ~spk_out}};
assign AUDIO_L = AUDIO_R;
assign AUDIO_MIX = 0;

wire [7:0] pit_o;
wire [2:0] pit_out;

k580vi53 pit
(
	.reset(reset),
	.clk_sys(clk_sys),
	.clk_timer({ce_pit,ce_pit,pit_out[1]}),

	.addr(addrbus[1:0]),
	.wr(~cpu_wr_n & pit_sel),
	.rd(cpu_rd & pit_sel),
	.din(cpu_o),
	.dout(pit_o),
	.gate(3'b111),
	.out(pit_out)
);


/////////////////////   FDD   /////////////////////
wire  [7:0] fdd_o;
reg         fdd_drive;
reg         fdd_side;
reg         fdd_ready = 0;
wire        fdd_drq;
wire        fdd_busy;

always @(posedge clk_sys) begin
	reg old_mounted;

	old_mounted <= img_mounted;
	if(~old_mounted & img_mounted) fdd_ready <= 1;
end

wd1793 #(1) fdd
(
	.clk_sys(clk_sys),
	.ce(ce_f1),
	.reset(reset),
	.io_en(fdd_sel),
	.rd(cpu_rd),
	.wr(~cpu_wr_n),
	.addr(addrbus[1:0]),
	.din(cpu_o),
	.dout(fdd_o),
	.drq(fdd_drq),
	.busy(fdd_busy),

	.img_mounted(img_mounted),
	.img_size(img_size[31:0]),
	.sd_lba(sd_lba),
	.sd_rd(sd_rd),
	.sd_wr(sd_wr),
	.sd_ack(sd_ack),
	.sd_buff_addr(sd_buff_addr),
	.sd_buff_dout(sd_buff_dout),
	.sd_buff_din(sd_buff_din),
	.sd_buff_wr(sd_buff_wr),

	.wp(0),

	.size_code(3),
	.layout(0),
	.side(fdd_side),
	.ready(~fdd_drive & fdd_ready),
	.prepare(),

	.input_active(0),
	.input_addr(0),
	.input_data(0),
	.input_wr(0),
	.buff_din(0)
);

wire fdd2_we = ~cpu_wr_n & fdd2_sel;
always @(posedge clk_sys) begin
	reg old_we;

	old_we <= fdd2_we;
	if(reset) begin
		fdd_side  <= 0;
		fdd_drive <= 0;
		cpu_hold  <= 0;
		old_we    <= 0;
	end else begin
		if(~old_we & fdd2_we) begin
			case(addrbus[1:0])
				0: cpu_hold  <= 1;
				2: fdd_side  <= cpu_o[0];
				3: fdd_drive <= cpu_o[0];
				default: ;
			endcase
		end

		if(fdd_drq | ~fdd_busy) cpu_hold <= 0;
	end
end

/////////////////////////////////////////////////

wire       filling = (ioctl_download | erasing);
reg        erasing = 0;
reg        fill_wr;
reg [24:0] fill_addr;
reg  [7:0] fill_data;

reg  [24:0] erase_mask;
wire [24:0] next_erase = (fill_addr + 1'd1) & erase_mask;

wire       force_erase = status[6];

always@(posedge clk_sys) begin
	reg [24:0] addr;
	reg        old_force = 0;
	reg        wr;

	reg  [5:0] erase_clk_div;
	reg [24:0] end_addr;

	reg [15:0] start_addr;

	fill_wr <= wr;
	wr <= 0;

	if(ioctl_download) begin
		erasing <= 0;

		if(ioctl_wr) begin
			if(rks_load) begin
				case(ioctl_addr)
					0: begin
							start_addr[7:0] <= ioctl_dout;
							fill_data <= 8'hC3;
							fill_addr <= 0;
							wr <= 1;
						end

					1: begin
							start_addr[15:8] <= ioctl_dout;
							fill_data <= start_addr[7:0];
							fill_addr <= 1;
							wr <= 1;
						end

					2: begin
							fill_data <= start_addr[15:8];
							fill_addr <= 2;
							wr <= 1;
						end

					3: begin
							addr <= start_addr;
						end

					default:
						begin
							fill_addr <= addr;
							fill_data <= ioctl_dout;
							addr <= addr + 1'd1;
							wr <= 1;
						end
				endcase
			end
		end

	end else begin

		old_force <= force_erase;

		// start erasing
		if(force_erase & ~old_force) begin
			fill_addr     <= 25'h1FFFF;
			erase_mask    <= 25'h7FFFF;
			end_addr      <= 25'h10000;
			erase_clk_div <= 1;
			erasing       <= 1;
		end else if(erasing) begin
			erase_clk_div <= erase_clk_div + 1'd1;
			if(!erase_clk_div) begin
				if(next_erase == end_addr) erasing <= 0;
				else begin
					fill_addr <= next_erase;
					fill_data <= 0;
					wr <= 1;
				end
			end
		end
	end
end

endmodule

module memory
(
	input	       clock,

	input [18:0] address_a,
	input	 [7:0] data_a,
	input	       wren_a,
	output [7:0] q_a,

	input	[18:0] address_b,
	input	 [7:0] data_b,
	input	       wren_b,
	output [7:0] q_b
);

altsyncram	altsyncram_component (
			.address_a (address_a),
			.address_b (address_b),
			.clock0 (clock),
			.data_a (data_a),
			.data_b (data_b),
			.wren_a (wren_a),
			.wren_b (wren_b),
			.q_a (q_a),
			.q_b (q_b),
			.aclr0 (1'b0),
			.aclr1 (1'b0),
			.addressstall_a (1'b0),
			.addressstall_b (1'b0),
			.byteena_a (1'b1),
			.byteena_b (1'b1),
			.clock1 (1'b1),
			.clocken0 (1'b1),
			.clocken1 (1'b1),
			.clocken2 (1'b1),
			.clocken3 (1'b1),
			.eccstatus (),
			.rden_a (1'b1),
			.rden_b (1'b1));
defparam
	altsyncram_component.address_reg_b = "CLOCK0",
	altsyncram_component.clock_enable_input_a = "BYPASS",
	altsyncram_component.clock_enable_input_b = "BYPASS",
	altsyncram_component.clock_enable_output_a = "BYPASS",
	altsyncram_component.clock_enable_output_b = "BYPASS",
	altsyncram_component.indata_reg_b = "CLOCK0",
	altsyncram_component.init_file = "rtl/bios.mif",
	altsyncram_component.intended_device_family = "Cyclone V",
	altsyncram_component.lpm_type = "altsyncram",
	altsyncram_component.numwords_a = 393216,
	altsyncram_component.numwords_b = 393216,
	altsyncram_component.operation_mode = "BIDIR_DUAL_PORT",
	altsyncram_component.outdata_aclr_a = "NONE",
	altsyncram_component.outdata_aclr_b = "NONE",
	altsyncram_component.outdata_reg_a = "UNREGISTERED",
	altsyncram_component.outdata_reg_b = "UNREGISTERED",
	altsyncram_component.power_up_uninitialized = "FALSE",
	altsyncram_component.read_during_write_mode_mixed_ports = "DONT_CARE",
	altsyncram_component.read_during_write_mode_port_a = "NEW_DATA_NO_NBE_READ",
	altsyncram_component.read_during_write_mode_port_b = "NEW_DATA_NO_NBE_READ",
	altsyncram_component.widthad_a = 19,
	altsyncram_component.widthad_b = 19,
	altsyncram_component.width_a = 8,
	altsyncram_component.width_b = 8,
	altsyncram_component.width_byteena_a = 1,
	altsyncram_component.width_byteena_b = 1,
	altsyncram_component.wrcontrol_wraddress_reg_b = "CLOCK0";


endmodule
