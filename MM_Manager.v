module MM_Manager(
	input clk,
	input [7:0]MMemory_wdata,
	input MMemory_wren,
	input [31:0]MMemory_waddr,
	input [31:0]MMemory_raddr,
	input [9:0] sw,
	output reg [9:0] ledr,	
	input  [31:0] gfx_cmd_lo,
	output [31:0] gfx_cmd_hi,
	output [31:0] gfx_cmd,
	output reg [7:0] kbd_en,
	input [7:0] kbd_buflen,
	output [7:0] kbd_ra,
	input [7:0] kbd_char,
	input  [7:0] instr_rom_rdata,
	output [31:0] instr_rom_raddr,
	output [7:0] MMemory_rdata
	);

	reg [7:0] _gfx_cmd_hi [3:0];
	reg [7:0] _gfx_cmd    [3:0];

	assign gfx_cmd_hi = {_gfx_cmd_hi[3], _gfx_cmd_hi[2], _gfx_cmd_hi[1], _gfx_cmd_hi[0]};
	assign gfx_cmd    = {_gfx_cmd[3], _gfx_cmd[2], _gfx_cmd[1], _gfx_cmd[0]};

	integer i;
	initial begin
		ledr <= 10'h0;
		for (i=0; i<4; i=i+1) begin
			_gfx_cmd_hi[i] <= 8'h0;
			_gfx_cmd   [i] <= 8'h0;
		end
	end

	// Ranges of mapped areas
	// Instruction ROM (RD)
	parameter instr_rom_st = 32'h00000, instr_rom_end = 32'h2ffff;
	// LEDR (RDWR)
	parameter ledr_st = 32'h100000, ledr_end = 32'h100009;
	// Switches (RD)
	parameter sw_st = 32'h100010, sw_end = 32'h100019;
	// 7-seg display (RDWR)
	// ?
	// Graphics: hi, lo, cmd
	parameter gfx_lo_st  = 32'h100100, gfx_lo_end  = 32'h100103;
	parameter gfx_hi_st  = 32'h100104, gfx_hi_end  = 32'h100107;
	parameter gfx_cmd_st = 32'h100108, gfx_cmd_end = 32'h10010b;
	// Keyboard: en, len, buf
	parameter kbd_en_st  = 32'h100200, kbd_en_end  = 32'h100200;
	parameter kbd_len_st = 32'h100201, kbd_len_end = 32'h100201;
	parameter kbd_buf_st = 32'h100210, kbd_buf_end = 32'h1002ff;

	// Main Memory (RDWR)
	parameter main_st = 32'h30000, main_end = 32'h7ffff;
	
	//reg [18:0]raddr;
	
	wire r_is_rom  = MMemory_raddr >= instr_rom_st && MMemory_raddr <= instr_rom_end;
	wire r_is_main = MMemory_raddr >= main_st      && MMemory_raddr <= main_end;
	wire w_is_main = MMemory_waddr >= main_st      && MMemory_waddr <= main_end;
	wire r_is_ledr = MMemory_raddr >= ledr_st      && MMemory_raddr <= ledr_end;
	wire w_is_ledr = MMemory_waddr >= ledr_st      && MMemory_waddr <= ledr_end;
	wire r_is_sw   = MMemory_raddr >= sw_st        && MMemory_waddr <= sw_end;
	// Graphics areas
	wire r_is_gfx_lo
		= MMemory_raddr >= gfx_lo_st  && MMemory_raddr <= gfx_lo_end;
	wire w_is_gfx_hi
		= MMemory_waddr >= gfx_hi_st  && MMemory_waddr <= gfx_hi_end;
	wire r_is_gfx_hi
		= MMemory_raddr >= gfx_hi_st  && MMemory_raddr <= gfx_hi_end;
	wire r_is_gfx_cmd
		= MMemory_raddr >= gfx_cmd_st && MMemory_raddr <= gfx_cmd_end;
	wire w_is_gfx_cmd
		= MMemory_waddr >= gfx_cmd_st && MMemory_waddr <= gfx_cmd_end;
	// End graphics areas
	// Keyboard areas
	wire r_is_kbd_en
		= MMemory_raddr >= kbd_en_st  && MMemory_raddr <= kbd_en_end;
	wire w_is_kbd_en
		= MMemory_waddr >= kbd_en_st  && MMemory_waddr <= kbd_en_end;
	wire r_is_kbd_len
		= MMemory_raddr >= kbd_len_st && MMemory_raddr <= kbd_len_end;
	wire r_is_kbd_buf
		= MMemory_raddr >= kbd_buf_st && MMemory_raddr <= kbd_buf_end;
	// End keyboard areas
	wire main_wr   = w_is_main && MMemory_wren;
	wire ledr_wr   = w_is_ledr && MMemory_wren;

	wire [31:0]
		_instr_rom_raddr = MMemory_raddr - instr_rom_st,
		main_raddr       = MMemory_raddr - main_st,
		main_waddr       = MMemory_waddr - main_st,
		ledr_raddr       = MMemory_raddr - ledr_st,
		ledr_waddr       = MMemory_waddr - ledr_st,
		sw_raddr         = MMemory_raddr - sw_st,
		gfx_hi_raddr     = MMemory_raddr - gfx_hi_st,
		gfx_hi_waddr     = MMemory_waddr - gfx_hi_st,
		gfx_cmd_raddr    = MMemory_raddr - gfx_cmd_st,
		gfx_cmd_waddr    = MMemory_waddr - gfx_cmd_st,
		gfx_lo_raddr     = MMemory_raddr - gfx_lo_st,
		kbd_len_raddr    = MMemory_raddr - kbd_len_st, // unused: 1-byte
		kbd_buf_raddr    = MMemory_raddr - kbd_buf_st
	;
	assign instr_rom_raddr = _instr_rom_raddr;
	assign kbd_ra          = kbd_buf_raddr[7:0];

	wire [7:0] main_rdata, ledr_rdata, sw_rdata;
	wire [7:0] gfx_lo_rdata, gfx_hi_rdata, gfx_cmd_rdata;

	assign ledr_rdata    = ledr[ledr_raddr];
	assign sw_rdata      = sw[sw_raddr];
	// So ugly... What to do about this :-(
	wire [7:0] gfx_lo_bytes [3:0];
	assign gfx_lo_bytes[0] = gfx_cmd_lo[7:0];
	assign gfx_lo_bytes[1] = gfx_cmd_lo[15:8];
	assign gfx_lo_bytes[2] = gfx_cmd_lo[23:16];
	assign gfx_lo_bytes[3] = gfx_cmd_lo[31:24];
	assign gfx_lo_rdata  = gfx_lo_bytes[gfx_lo_raddr];
	//
	assign gfx_hi_rdata  = _gfx_cmd_hi[gfx_hi_raddr ];
	assign gfx_cmd_rdata = _gfx_cmd   [gfx_cmd_raddr];

	MMemory main_ram (
			.clock     (clk),
			.data      (MMemory_wdata),
			.rdaddress (main_raddr[18:0]),
			.wraddress (main_waddr[18:0]),
			.wren      (main_wr),
			.q         (main_rdata)
	);

	assign MMemory_rdata =
		r_is_rom     ? instr_rom_rdata :
		r_is_main    ? main_rdata :
		r_is_ledr    ? ledr_rdata :
		r_is_sw      ? sw_rdata :
		r_is_gfx_lo  ? gfx_lo_rdata :
		r_is_gfx_hi  ? gfx_hi_rdata :
		r_is_gfx_cmd ? gfx_cmd_rdata :
		r_is_kbd_buf ? kbd_char :
		r_is_kbd_len ? kbd_buflen :
		r_is_kbd_en  ? kbd_en :
		// TODO: errors
		8'h0
	;

	initial begin
		kbd_en <= 8'd0;
	end

	always @ (posedge clk)
	begin
		// Set LEDR
		if (ledr_wr) begin
			ledr[ledr_waddr] <= |MMemory_wdata;
		end

		// Writes to graphics controller
		if (w_is_gfx_hi)
			_gfx_cmd_hi[gfx_hi_waddr ] <= MMemory_wdata;
		if (w_is_gfx_cmd)
			_gfx_cmd   [gfx_cmd_waddr] <= MMemory_wdata;

		// Writes to keyboard controller
		if (w_is_kbd_en)
			kbd_en <= MMemory_wdata;
	end
	
endmodule
