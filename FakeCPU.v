module FakeCPU(
	input clk,
	//Test
	input [31:0]init_pc,
	input init_wren,
	input go,
	output finish,
	output [31:0]data_pc,
	output [31:0]test_instr
	);
	
	wire [7:0]instr_1B;
	wire [9:0]instr_addr;
	fib_rom fib(instr_addr, clk, instr_1B);
	
	//Interupt
	wire intr;
	
	wire [7:0]MMemory_rdata;
	wire [18:0]MMemory_raddr;
	wire [7:0]MMemory_wdata;
	wire [18:0]MMemory_waddr;
	wire MMemory_wren;
	wire [18:0]MMemory_VGA_raddr;
	MM_Manager mm_m(clk, MMemory_wdata, MMemory_wren, MMemory_waddr, MMemory_raddr, MMemory_VGA_raddr, intr, MMemory_rdata);
	
	wire [31:0]REG_rdata;
	wire [4:0]REG_raddr;
	wire [31:0]REG_wdata;
	wire [4:0]REG_waddr;
	wire REG_wren;
	REG register(clk, REG_wdata, REG_raddr, REG_wdata, REG_rdata);
	
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
	Instr_Reciver i_r(clk, instr_1B, MMemory_rdata, MMemory_wdata, REG_rdata, REG_wdata, instr_addr, MMemory_raddr, MMemory_waddr, MMemory_wren,
		REG_raddr, REG_waddr, REG_wren, PC_rdata, PC_instr_wdata, PC_instr_wren, PC_decode_wdata, PC_decode_wren, intr, instr_go, instr_finish, test_instr);
	
	//Test
	assign PC_init_data = init_pc;
	assign PC_init_wren = init_wren;
	assign instr_go = go;
	assign finish = instr_finish;
	assign data_pc = PC_rdata;
	
endmodule
