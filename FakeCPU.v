module FakeCPU(
	//Peripherals
	// Basic
	input clk_50,
	input [3:0]key,
	input [9:0]sw,
	output [9:0]ledr,
	output [6:0]hex5, hex4, hex3, hex2, hex1, hex0,
	// PS/2
	input ps2_clk,
	input ps2_dat,
	// VGA
	output [7:0] vga_r,
	output [7:0] vga_g,
	output [7:0] vga_b,
	output vga_clk,
	output vga_hs,
	output vga_vs,
	output vga_sync_n,
	output vga_blank_n
	//Test
	//output finish,
	//output [17:0]test_instr_addr,
	//output [31:0]test_instr,
	//output clk_instr,
	//output [4:0]test_decoding,
	//output [2:0]test_solving,
	//output [7:0]test_gfx_cmd_state,
	//output test_run,
	//output test_ok
	);
	
	// Debugging: use KEY3 as clock source
	parameter debugging = 0;
	
	// Generate CPU & memory clock
	wire prod_clk = clk_50;
	wire debug_clk = key[3];
	wire real_clk = debugging ? debug_clk : prod_clk;
	wire mem_clk = real_clk;
	wire instr_clk;
	// 1/5
	clkgen #( .orig_freq ( 50000000 ), .dest_freq ( 10000000 ) ) instr_clkgen(mem_clk, 1'b0, 1'b1, instr_clk);

	// VGA module instantiation

	wire [31:0] gfx_cmd_lo, gfx_cmd_hi;
	wire [31:0] gfx_cmd;

	GFX_Controller gfx_controller (
		.clk_50      (clk_50),
		.mem_clk     (mem_clk),
		.cmd_lo      (gfx_cmd_lo),
		.cmd_hi      (gfx_cmd_hi),
		.cmd         (gfx_cmd),
		.vga_r       (vga_r),
		.vga_g       (vga_g),
		.vga_b       (vga_b),
		.vga_clk     (vga_clk),
		.vga_hs      (vga_hs),
		.vga_vs      (vga_vs),
		.vga_sync_n  (vga_sync_n),
		.vga_blank_n (vga_blank_n),
		.test_gfx_cmd_state (test_gfx_cmd_state)
	);

	// ----

	// Keyboard module instantiation

	wire [7:0] kbd_en;
	wire [7:0] kbd_buflen;
	wire [7:0] kbd_ra;
	wire [7:0] kbd_char;

	KBD_Handler kbd_handler (
		.ps2_clk    (ps2_clk),
		.ps2_dat    (ps2_dat),
		.clk_50     (clk_50),
		.mem_clk    (mem_clk),
		.kbd_en     (kbd_en),
		.kbd_buflen (kbd_buflen),
		.kbd_ra     (kbd_ra),
		.kbd_char   (kbd_char)
	);

	// ----

	wire [7:0]MMemory_rdata;
	wire [31:0]MMemory_raddr;
	wire [7:0]MMemory_wdata;
	wire [31:0]MMemory_waddr;
	wire MMemory_wren;
	wire [7:0] MM_instr_rdata;
	wire [31:0] MM_instr_raddr;
	MM_Manager mm_m (
		.clk (mem_clk),
		.MMemory_wdata (MMemory_wdata),
		.MMemory_wren  (MMemory_wren),
		.MMemory_waddr (MMemory_waddr),
		.MMemory_raddr (MMemory_raddr),
		.sw (sw),
		.ledr (ledr),
		.gfx_cmd_lo (gfx_cmd_lo),
		.gfx_cmd_hi (gfx_cmd_hi),
		.gfx_cmd (gfx_cmd),
		.kbd_en     (kbd_en),
		.kbd_buflen (kbd_buflen),
		.kbd_ra     (kbd_ra),
		.kbd_char   (kbd_char),
		.instr_rom_rdata (MM_instr_rdata),
		.instr_rom_raddr (MM_instr_raddr),
		.MMemory_rdata   (MMemory_rdata)
	);

	wire [7:0]instr_1B;
	wire [31:0]instr_addr;
	// S(oft)W(are)
	SW_Rom sw_rom (
		.clock (mem_clk),
		.address_a (instr_addr[17:0]),
		.address_b (MM_instr_raddr[17:0]),
		.q_a (instr_1B),
		.q_b (MM_instr_rdata)
	);
	
	//Interupt
	wire intr;

	wire [31:0]REG_rdata;
	wire [4:0]REG_raddr;
	wire [31:0]REG_wdata;
	wire [4:0]REG_waddr;
	wire REG_wren;
	//REG register(mem_clk, REG_wren, REG_waddr, REG_raddr, REG_wdata, REG_rdata);
	Registers registers (
		.data      (REG_wdata),
		.wraddress (REG_waddr),
		.wren      (REG_wren),
		.rdaddress (REG_raddr),
		.q         (REG_rdata),
		.clock     (mem_clk)
	);
	
	reg [31:0]PC_init_data;
	reg PC_init_wren;
	wire [31:0]PC_instr_wdata;
	wire PC_instr_wren;
	wire [31:0]PC_decode_wdata;
	wire PC_decode_wren;
	wire [31:0]PC_rdata;
	PC_register pc(mem_clk, PC_init_data, PC_init_wren, PC_instr_wdata, PC_instr_wren, PC_decode_wdata, PC_decode_wren, PC_rdata);
	
	reg instr_go;
	wire instr_finish;
	Instr_Reciver i_r(instr_clk, instr_1B, MMemory_rdata, MMemory_wdata, REG_rdata, REG_wdata, instr_addr, MMemory_raddr, MMemory_waddr, MMemory_wren,
		REG_raddr, REG_waddr, REG_wren, PC_rdata, PC_instr_wdata, PC_instr_wren, PC_decode_wdata, PC_decode_wren, intr, instr_go, instr_finish, 
		test_instr, test_decoding, test_solving, test_run, test_ok);

	assign finish = instr_finish;
	//assign data_pc = PC_rdata;
	assign clk_instr = instr_clk;
	assign test_instr_addr = instr_addr;

	reg [2:0] init_st;

	initial begin
		init_st <= 3'd0;
		instr_go <= 1'b0;
	end

	always @(posedge mem_clk) begin
		case (init_st)
		3'd0: begin
			// Explicitly initialize PC
			PC_init_data <= 32'h0;
			PC_init_wren <= 1'b1;
			init_st <= 3'd1;
		end
		3'd1: begin
			PC_init_wren <= 1'b0;
			init_st <= 3'd2;
		end
		3'd2: begin
			// Go!
			instr_go <= 1'b1;
			init_st <= 3'd3;
		end
		default: begin

		end
		endcase
	end

endmodule
