module GFX_Controller (
	input clk_50,
	input mem_clk,
	output [31:0] cmd_lo,
	input  [31:0] cmd_hi,
	input  [31:0] cmd,
	output [7:0] vga_r, vga_g, vga_b,
	output vga_clk,
	output vga_hs,
	output vga_vs,
	output vga_sync_n,
	output vga_blank_n,
	// Simulation
	output [7:0]  test_gfx_cmd_state
);

	parameter NROWS = 30, NCOLS = 70, NCHR = NROWS * NCOLS;

	wire rev_clk_50 = ~clk_50;
	clkgen #( .orig_freq ( 50000000 ), .dest_freq ( 25000000 ) ) vga_clkgen(clk_50, 1'b0, 1'b1, vga_clk);

	wire [11:0] chr_addr;
	wire [9:0] haddr, vaddr;
	wire [7:0] chr_addr_x, chr_addr_y;
	wire [3:0] cur_chr_x, cur_chr_y;
	wire addr_valid, chr_disp_valid;

		// a global counter, for cursor
	reg [23:0] glob_ticks;

	// screen buffer information
	reg [7:0]  next_x, next_y, base_addr_y;
	reg [7:0]  line_size [NROWS];
	reg [7:0]  row_to_clear;
	reg [11:0] next_chr, base_addr, prev_base_addr, wr_addr;

	VGA_Controller vga_ctrl (
		.pclk           (vga_clk),
		.reset          (1'b0),
		.h_addr         (haddr),
		.v_addr         (vaddr),
		.chr_addr_x     (chr_addr_x),
		.cur_chr_x      (cur_chr_x),
		.chr_addr_y     (chr_addr_y),
		.cur_chr_y      (cur_chr_y),
		.base_addr      (base_addr),
		.base_addr_y    (base_addr_y),
		.chr_addr       (chr_addr),
		.hsync          (vga_hs),
		.vsync          (vga_vs),
		.valid          (addr_valid),
		.chr_disp_valid (chr_disp_valid)
	);
	assign vga_sync_n  = 1'b0;
	assign vga_blank_n = addr_valid;

	wire [11:0] gfx_raddr = chr_addr;
	wire [7:0]  gfx_rdata;
	reg         gfx_wren;
	reg  [7:0]  gfx_wdata;
	reg  [11:0] gfx_waddr;
	GFXMemory gfx_mem (
		.data      (gfx_wdata),
		.wraddress (gfx_waddr),
		.wren      (gfx_wren),
		.rdaddress (gfx_raddr),
		.wrclock   (mem_clk),
		.rdclock   (rev_clk_50),
		.q         (gfx_rdata)
	);

	initial begin
		glob_ticks  <= 32'd0;
		next_x      <= 0;
		next_y      <= 0;
		next_chr    <= 0;
		base_addr   <= 0;
		base_addr_y <= 0;
	end

	wire [7:0] char_asc = gfx_rdata;
	wire [11:0] char_bmp_ln;
	//
	reg [23:0] fgcolor, bgcolor;
	wire [23:0] _vga_data =
		char_bmp_ln[cur_chr_x] ?
		fgcolor :
		bgcolor
	;

	FontROM font_rom (
		.address ( {char_asc[7:0], cur_chr_y[3:0]} ),
		.clock   ( clk_50 ),
		.q       ( char_bmp_ln )
	);

	initial begin
		bgcolor <= 24'h000000;
		fgcolor <= 24'hFFFFFF;
	end

	always @(posedge vga_clk)
		glob_ticks <= glob_ticks + 32'd1;

	wire at_cursor = chr_addr == next_chr;
	wire cursor_shown = glob_ticks[23];
	wire data_discarded = line_size[chr_addr_y] <= chr_addr_x;
	wire [23:0] vga_data = 
		(!chr_disp_valid) ? bgcolor :
		(at_cursor && cursor_shown) ? fgcolor :
		(data_discarded) ? bgcolor :
		_vga_data
	;

	assign vga_r = vga_data[23:16];
	assign vga_g = vga_data[15:8];
	assign vga_b = vga_data[7:0];

	//////////////// handle commands ////////////////

	reg  [5:0]  cmd_state;
	reg  [31:0] current_cmd;
	wire [7:0]  cmd_op    = current_cmd[7:0];
	wire [7:0]  cmd_char  = current_cmd[15:8];
	wire [23:0] cmd_color = current_cmd[31:8];

	reg  need_wrap;

	assign test_gfx_cmd_state = cmd_state;

	reg  [7:0]  _cmd_lo;
	assign cmd_lo[31:0] = { 24'h0, _cmd_lo[7:0] };

	initial begin
		gfx_wren  <= 1'b0;
		cmd_state <= 6'd0;
		_cmd_lo   <= 0;
		need_wrap <= 1'b0;
	end

	parameter CMD_ST = 7'd0, CMD_FIN = 6'd63;

	always @(negedge mem_clk) begin
		case (cmd_state)
		6'd0: begin
			// check for new commands
			if (cmd_lo != cmd_hi[7:0]) begin
				current_cmd <= cmd;
				cmd_state <= 6'd1;
			end
		end
		6'd1: begin
			case (cmd_op)
			8'h01: begin
				// append character
				cmd_state <= 6'd10;
			end
			/*
			8'h02: begin
				// <-- cursor
				cmd_state <= 7'd20;
			end
			8'h03: begin
				// cursor -->
				cmd_state <= 7'd30;
			end
			*/
			8'h04: begin
				// clear screen
				cmd_state <= 6'd40;
			end
			8'h05: begin
				// set foreground color
				cmd_state <= 6'd50;
			end
			8'h06: begin
				// set background color
				cmd_state <= 6'd60;
			end
			endcase
		end
		// BEGIN: append character
		6'd10: begin
			if (cmd_char == 8'h0A || cmd_char == 8'h0D) begin
				cmd_state <= 6'd11;
			end else if (cmd_char == 8'h08) begin
				if (line_size[next_y])
					line_size[next_y] <= line_size[next_y] - 1;
				gfx_waddr <= next_chr - 1;
				gfx_wdata <= 0;
				gfx_wren  <= 1'b1;
				cmd_state <= 6'd12;
			end else begin
				line_size[next_y] <= line_size[next_y] + 1;
				gfx_waddr <= next_chr;
				gfx_wdata <= cmd_char;
				gfx_wren  <= 1'b1;
				cmd_state <= 6'd11;
			end
		end
		6'd11: begin
			// advance the pointers as usual
			if (next_x >= NCOLS - 1 || cmd_char == 8'h0D || cmd_char == 8'h0A) begin
				// newline
				next_chr <= next_chr + (NCOLS - next_x);
				next_x <= 0;
				if (next_y >= NROWS - 1)
					next_y <= 0;
				else
					next_y <= next_y + 1;
				cmd_state <= 6'd13;
			end else begin
				next_chr  <= next_chr + 1;
				next_x <= next_x + 1;
				cmd_state <= 6'd19;
			end
		end
		6'd12: begin
			// back the pointers
			next_chr <= next_chr - 1;
			if (next_x) begin
				next_x <= next_x - 1;
			end else begin
				if (next_y) begin
					next_y <= NROWS - 1;
				end else begin
					next_y <= next_y - 1;
				end
				next_x <= NCOLS - 1;
			end
			cmd_state <= 6'd19;
		end
		6'd13: begin
			// check after newline
			line_size[next_y] <= 0;
			if (next_chr >= NCHR)
				next_chr <= next_chr - NCHR;
			if (need_wrap || next_chr >= NCHR) begin
				need_wrap <= 1'b1;
				prev_base_addr <= base_addr;
				if (base_addr >= NCHR - NCOLS)
					base_addr <= base_addr + NCOLS - NCHR;
				else
					base_addr <= base_addr + NCOLS;
				if (base_addr_y >= NROWS - 1)
					base_addr_y <= 0;
				else
					base_addr_y <= base_addr_y + 1;
			end
			cmd_state <= 6'd19;
		end
		6'd19: begin
			gfx_wren  <= 1'b0;
			cmd_state <= CMD_FIN;
		end
		// END
		// BEGIN: move cursor left
		// ...
		// END
		// BEGIN: move cursor right
		// ...
		// END
		// BEGIN: clear screen
		6'd40: begin
			next_x      <= 0;
			next_y      <= 0;
			next_chr    <= 0;
			base_addr   <= 0;
			base_addr_y <= 0;
			need_wrap   <= 0;
			//
			row_to_clear <= 0;
			cmd_state    <= 6'd41;
		end
		6'd41: begin
			// reset all line_size's
			if (row_to_clear >= NROWS) begin
				cmd_state <= CMD_FIN;
			end else begin
				line_size[row_to_clear] <= 0;
				row_to_clear <= row_to_clear + 8'd1;
			end
		end
		// END
		// BEGIN: set fgcolor
		6'd50: begin
			fgcolor <= cmd_color;
			cmd_state <= CMD_FIN;
		end
		// END
		// BEGIN: set bgcolor
		6'd60: begin
			bgcolor <= cmd_color;
			cmd_state <= CMD_FIN;
		end
		// END
		CMD_FIN: begin
			// Finish
			_cmd_lo <= _cmd_lo + 1;
			cmd_state <= CMD_ST;
		end
		default: begin
			// unknown command. pretend as if I've seen nothing...
			cmd_state <= CMD_FIN;
		end
		endcase
	end

endmodule
