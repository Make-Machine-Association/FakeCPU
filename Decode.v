module Decode(
	input clk,
	input [31:0]instr,
	input run,
	input [7:0]MMemory_rdata,
	output reg [7:0]MMemory_wdata,
	input [31:0]REG_rdata,
	output reg [31:0]REG_wdata,
	output reg ok,
	output reg [18:0]MMemory_raddr,
	output reg [18:0]MMemory_waddr,
	output reg MMemory_wren,
	output reg [4:0]REG_raddr,
	output reg [4:0]REG_waddr,
	output reg REG_wren,
	output reg [31:0]PC_decode_wdata,
	output reg PC_decode_wren,
	output reg intr
	);
	wire [5:0]opcode;
	wire [4:0]rs;
	wire [4:0]rt;
	wire [4:0]rd;
	wire [4:0]shamt;
	wire [5:0]funct;
	wire [15:0]imm16;
	wire [25:0]imm26;
	
	assign opcode = instr[5:0];
	assign rs = instr[10:6];
	assign rt = instr[15:11];
	assign rd = instr[20:16];
	assign shamt = instr[25:21];
	assign funct = instr[31:26];
	assign imm16 = instr[31:16];
	assign imm26 = instr[31:6];
	
	reg [31:0]ALU_rs;
	reg [31:0]ALU_rt;
	reg [3:0]ALU_ctrl;
	wire [31:0]ALU_rd;
	wire ALU_overflow;
	
	ALU a(ALU_rs, ALU_rt, ALU_ctrl, ALU_rd, ALU_overflow);
	
	reg [4:0]decoding;
	
	always @ (posedge clk)
	begin
		if (run && !ok) begin
			case (decoding)
				5'd0: begin
					case (opcode)
						6'h0: begin
							//opcode rd, rs, rt
							case (funct)
								6'h0: ALU_ctrl <= 4'b0001;
								6'h1: ALU_ctrl <= 4'b0000;
								6'h2: ALU_ctrl <= 4'b1001;
								6'h3: ALU_ctrl <= 4'b1000;
								6'h7: ALU_ctrl <= 4'b0101;
								6'ha: ALU_ctrl <= 4'b1011;
								6'hb: ALU_ctrl <= 4'b1010;
							endcase
							decoding <= 5'd1;
						end
						6'h8: begin
							//addi rt, rs, imm
							ALU_ctrl <= 4'b0001;
							decoding <= 5'd6;
						end
						6'h9: begin
							//addiu rt, rs, imm
							ALU_ctrl <= 4'b0000;
							decoding <= 5'd6;
						end
						6'he: begin
							//xor rt, rs, imm
							ALU_ctrl <= 4'b0110;
							decoding <= 5'd6;
						end
						6'ha: begin
							//slti rt, rs, imm
							ALU_ctrl <= 4'b1011;
							decoding <= 5'd6;
						end
						6'hb: begin
							//sltiu rt, rs, imm
							ALU_ctrl <= 4'b1010;
							decoding <= 5'd6;
						end
						6'h6: begin
							//blez rs, imm
							decoding <= 5'd10;
						end
						6'h2: begin
							//j target
							decoding <= 5'd13;
						end
						6'h23: begin
							//lw rt, offset(base)
							decoding <= 5'd14;
						end
						6'h2b: begin
							//sw rt, offset(base)
							decoding <= 5'd18;
						end
					endcase
				end
				5'd1: begin
					//Read rs
					REG_raddr <= rs;
					ALU_rs <= REG_rdata;
					decoding <= 5'd2;
				end
				5'd2: begin
					//Read rt
					REG_raddr <= rt;
					ALU_rt <= REG_rdata;
					decoding <= 5'd3;
				end
				5'd3: begin
					//Calculate
					decoding <= 5'd4;
				end
				5'd4: begin
					//Write rd
					case (funct)
						6'h0, 6'h2: begin
							if (!ALU_overflow) begin
								REG_waddr <= rd;
								REG_wdata <= ALU_rd;
								REG_wren <= 1'b1;
							end
						end
						default: begin
							REG_waddr <= rd;
							REG_wdata <= ALU_rd;
							REG_wren <= 1'b1;
						end
					endcase
					decoding <= 5'd5;
				end
				5'd5: begin
					//Finish
					REG_wren <= 1'b0;
					decoding <= 5'd0;
					ok <= 1'b1;
				end
				5'd6: begin
					//Read rs
					REG_raddr <= rs;
					ALU_rs <= REG_rdata;
					decoding <= 5'd7;
				end
				5'd7: begin
					//Read imm
					ALU_rt <= {{16{imm16[15]}},imm16};
					decoding <= 5'd8;
				end
				5'd8: begin
					//Calculate
					decoding <= 5'd9;
				end
				5'd9: begin
					//Write rt
					case (opcode)
						6'h8: begin
							if (!ALU_overflow) begin
								REG_waddr <= rt;
								REG_wdata <= ALU_rd;
								REG_wren <= 1'b1;
							end
						end
						default: begin
							REG_waddr <= rt;
							REG_wdata <= ALU_rd;
							REG_wren <= 1'b1;
						end
					endcase
					decoding <= 5'd5;
				end
				5'd10: begin
					//Read rs;
					REG_raddr <= rs;
					decoding <= 5'd11;
				end
				5'd11: begin
					//Blez
					if (REG_rdata <= 0) begin
						PC_decode_wdata <= {imm16, 2'b00};
						PC_decode_wren <= 1'b1;
					end
					decoding <= 5'd12;
				end
				5'd12: begin
					//Finish
					PC_decode_wren <= 1'b0;
					decoding <= 5'd0;
					ok <= 1'b1;
				end
				5'd13: begin
					//Jump
					PC_decode_wdata <= {imm26, 2'b00};
					PC_decode_wren <= 1'b1;
					decoding <= 5'd12;
				end
				5'd14: begin
					//Load MMemory[7:0]
					MMemory_raddr <= rs+imm16;
					REG_wdata[7:0] <= MMemory_rdata;
					decoding <= 5'd15;
				end
				5'd15: begin
					//Load MMemory[15:8]
					MMemory_raddr <= MMemory_raddr+19'd1;
					REG_wdata[15:8] <= MMemory_rdata;
					decoding <= 5'd16;
				end
				5'd16: begin
					//Load MMemory[23:16]
					MMemory_raddr <= MMemory_raddr+19'd1;
					REG_wdata[23:16] <= MMemory_rdata;
					decoding <= 5'd17;
				end
				5'd17: begin
					//Load MMemory[31:24]
					MMemory_raddr <= MMemory_raddr+19'd1;
					REG_wdata[31:24] <= MMemory_rdata;
					REG_waddr <= rt;
					REG_wren <= 1'b1;
					decoding <= 5'd5;
				end
				5'd18: begin
					//Save rt[7:0]
					REG_raddr <= rt;
					MMemory_waddr <= rs+imm16;
					MMemory_wdata <= REG_rdata[7:0];
					MMemory_wren <= 1'b1;
					decoding <= 5'd19;
				end
				5'd19: begin
					//Save rt[15:8]
					MMemory_waddr <= MMemory_waddr+19'd1;
					MMemory_wdata <= REG_rdata[15:8];
					decoding <= 5'd20;
				end
				5'd20: begin
					//Save rt[23:16]
					MMemory_waddr <= MMemory_waddr+19'd1;
					MMemory_wdata <= REG_rdata[23:16];
					decoding <= 5'd21;
				end
				5'd21: begin
					//Save rt[31:24]
					MMemory_waddr <= MMemory_waddr+19'd1;
					MMemory_wdata <= REG_rdata[31:24];
					decoding <= 5'd22;
				end
				5'd22: begin
					//Finish
					MMemory_wren <= 1'b0;
					decoding <= 5'd0;
					ok <= 1'b1;
				end
			endcase
		end else if (!run) begin
			decoding <= 5'd0;
			REG_wren <= 1'b0;
			PC_decode_wren <= 1'b0;
			MMemory_wren <= 1'b0;
			intr <= 1'b0;
			ok <= 1'b0;
		end
	end

endmodule
