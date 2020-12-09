module Decode(
	input clk;
	input [31:0]instr,
	input [18:0]PC;
	input run,
	input [31:0]MMemory_data,
	input [31:0]REG_data,
	output ok,
	output [18:0]MMemory_addr,
	output [4:0]REG_addr
	);
	wire [5:0]opcode;
	wire [4:0]rs;
	wire [4:0]rt;
	wire [4:0]rd;
	wire [4:0]shamt;
	wire [5:0]funct;
	wire [15:0]imm16;
	wire [25:0]imm26;
	
	assign opcode = instr[31:26];
	assign rs = instr[25:21];
	assign rt = instr[20:16];
	assign rd = instr[15:11];
	assign shamt = instr[10:6];
	assign funct = instr[5:0];
	assign imm16 = instr[15:0];
	assign imm26 = instr[25:0];
	
	reg [31:0]ALU_rs;
	reg [31:0]ALU_rt;
	reg [3:0]ALU_ctrl;
	wire [31:0]ALU_rd;
	wire ALU_overflow;
	
	ALU a(ALU_rs, ALU_rt, ALU_ctrl, ALU_rd, ALU_overflow);
	
	reg [2:0]decoding;
	
	always @ (posedge clk)
	begin
		case (opcode)
			6'h0: begin
				//opcode rd, rs, rt
			end
			6'h8: begin
				//addi rt, rs, imm
			end
			6'h9: begin
				//addiu rt, rs, imm
			end
			6'he: begin
				//xor rt, rs, imm
			end
			6'ha: begin
				//slti rt, rs, imm
			end
			6'hb: begin
				//sltiu rt, rs, imm
			end
			6'h6 begin
				//blez rs, imm
			end
			6'h2: begin
				//j target
			end
			6'h23: begin
				//lw rt, offset(base)
			end
			6'h2b: begin
				//sw rt, offset(base)
			end
		endcase
	end

endmodule
