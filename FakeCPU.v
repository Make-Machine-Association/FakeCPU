module FakeCPU(
	input clk,
	//Test
	input [31:0]init_pc,
	input init_wren,
	input go,
	input [31:0]test_mmemory_addr,
	input test_intr,
	output finish,
	output [31:0]data_pc,
	output [31:0]test_instr,
	output clk_instr,
	output [4:0]test_decoding,
	output test_run,
	output test_ok,
	output [31:0]test_mmemory_data,
	output [31:0]test_reg_rdata,
	output [31:0]test_reg_wdata,
	output [4:0]test_reg_raddr,
	output [4:0]test_reg_waddr,
	output test_reg_wren
	);
	
	wire instr_clk;
	clkgen #(10000000) instr_clkgen(clk, 1'b0, 1'b1, instr_clk);
	
	wire [7:0]instr_1B;
	wire [31:0]instr_addr;
	fib_rom fib(instr_addr[9:0], clk, instr_1B);
	
	//Interupt
	wire intr;
	
	wire [7:0]MMemory_rdata;
	wire [31:0]MMemory_raddr;
	wire [7:0]MMemory_wdata;
	wire [31:0]MMemory_waddr;
	wire MMemory_wren;
	wire [31:0]MMemory_VGA_raddr;
	MM_Manager mm_m(clk, MMemory_wdata, MMemory_wren, MMemory_waddr, MMemory_raddr, MMemory_VGA_raddr, intr, MMemory_rdata,
		test_mmemory_addr, test_intr);
	
	wire [31:0]REG_rdata;
	wire [4:0]REG_raddr;
	wire [31:0]REG_wdata;
	wire [4:0]REG_waddr;
	wire REG_wren;
	REG register(clk, REG_wren, REG_waddr, REG_raddr, REG_wdata, REG_rdata);
	
	wire [31:0]PC_init_data;
	wire PC_init_wren;
	wire [31:0]PC_instr_wdata;
	wire PC_instr_wren;
	wire [31:0]PC_decode_wdata;
	wire PC_decode_wren;
	wire [31:0]PC_rdata;
	PC_register pc(clk, PC_init_data, PC_init_wren, PC_instr_wdata, PC_instr_wren, PC_decode_wdata, PC_decode_wren, PC_rdata);
	
	wire instr_go;
	wire instr_finish;
	Instr_Reciver i_r(instr_clk, instr_1B, MMemory_rdata, MMemory_wdata, REG_rdata, REG_wdata, instr_addr, MMemory_raddr, MMemory_waddr, MMemory_wren,
		REG_raddr, REG_waddr, REG_wren, PC_rdata, PC_instr_wdata, PC_instr_wren, PC_decode_wdata, PC_decode_wren, intr, instr_go, instr_finish, 
		test_instr, test_decoding, test_run, test_ok);
	
	//Test
	assign PC_init_data = init_pc;
	assign PC_init_wren = init_wren;
	assign instr_go = go;
	assign finish = instr_finish;
	assign data_pc = PC_rdata;
	assign clk_instr = instr_clk;
	assign test_mmemory_data = MMemory_rdata;
	assign test_reg_rdata = REG_rdata;
	assign test_reg_wdata = REG_wdata;
	assign test_reg_raddr = REG_raddr;
	assign test_reg_waddr = REG_waddr;
	assign test_reg_wren = REG_wren;
	
endmodule
