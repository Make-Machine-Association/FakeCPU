module Decode(
	input clk,
	input [31:0]instr,
	input run,
	input [7:0]MMemory_rdata,
	output reg [7:0]MMemory_wdata,
	input [31:0]REG_rdata,
	output reg [31:0]REG_wdata,
	output reg ok,
	output reg [31:0]MMemory_raddr,
	output reg [31:0]MMemory_waddr,
	output reg MMemory_wren,
	output reg [4:0]REG_raddr,
	output reg [4:0]REG_waddr,
	output reg REG_wren,
	output reg [31:0]PC_decode_wdata,
	output reg PC_decode_wren,
	input [31:0]PC_rdata,
	output reg intr,
	//Test
	output [6:0]test_decoding
	);
	wire [5:0]opcode;
	wire [4:0]rs;
	wire [4:0]rt;
	wire [4:0]rd;
	wire [4:0]sa;
	wire [4:0]shamt;
	wire [5:0]funct;
	wire [15:0]imm16;
	wire [25:0]imm26;
	
	assign opcode = instr[31:26];
	assign rs = instr[25:21];
	assign rt = instr[20:16];
	assign rd = instr[15:11];
	assign sa = instr[10:6];
	assign shamt = instr[10:6];
	assign funct = instr[5:0];
	assign imm16 = instr[15:0];
	assign imm26 = instr[25:0];
	
	reg [31:0]ALU_rs;
	reg [31:0]ALU_rt;
	reg [3:0]ALU_ctrl;
	wire [31:0]ALU_rd;
	wire ALU_overflow;

	// MULT/DIV
	reg  [31:0] md_op1, md_op2;
	reg  [31:0] lo, hi;
	wire [63:0] mul_result, mulu_result, div_result, divu_result;

	LPM_DIVIDE_Unsigned diver_u(
		.numer       (ALU_rs),
		.denom       (ALU_rt),
		.remain      (divu_result[63:32]),
		.quotient    (divu_result[31:0])
	);

	LPM_DIVIDE_Signed diver (
		.numer       (ALU_rs),
		.denom       (ALU_rt),
		.remain      (div_result[63:32]),
		.quotient    (div_result[31:0])
	);

	LPM_MULT_Unsigned muler_u (
		.dataa       (ALU_rs),
		.datab       (ALU_rt),
		.result      (mulu_result)
	);

	LPM_MULT_Signed   muler (
		.dataa       (ALU_rs),
		.datab       (ALU_rt),
		.result      (mul_result)
	);

	// for b*
	reg  [31:0] br_rs, br_rt;
	wire br_cond = 
		// bgtz
		( opcode == 6'b000111 && !REG_rdata[31] && REG_rdata)
		||
		// blez
		( opcode == 6'b000110 && (REG_rdata[31] || REG_rdata == 32'd0))
		||
		// bltz
		( opcode == 6'b000001 &&  REG_rdata[31] && REG_rdata)
		||
		// beq
		( opcode == 6'b000100 &&  br_rs == br_rt )
		||
		// bne
		( opcode == 6'b000101 &&  br_rs != br_rt )
	;

	// for lb, lbu, sw, lw
	reg sgn_ext; // lb vs lbu
	reg ls_byte; // 0 -> byte, 1 -> word

	ALU a(
		.rs       (ALU_rs),
		.rt       (ALU_rt),
		.ctrl     (ALU_ctrl),
		.sa       (sa),
		.rd       (ALU_rd),
		.overflow (ALU_overflow)
	);
	
	reg [5:0]decoding;
	reg [2:0]alu_wait;
	
	initial
	begin
		decoding = 6'd0;
		ok = 1'b0;
		intr = 1'b0;
		REG_raddr = 5'd0;
		REG_waddr = 5'd0;
		REG_wdata = 32'd0;
		REG_wren = 1'b0;
		MMemory_raddr = 32'd0;
		MMemory_waddr = 32'd0;
		MMemory_wdata = 8'd0;
		MMemory_wren = 1'b0;
	end
	
	always @ (posedge clk)
	begin
		if (run && !ok) begin
			case (decoding)
				6'd0: begin
					case (opcode)
						6'h0: begin
							decoding <= 6'd43;
						end
						6'h8: begin
							//addi rt, rs, imm
							ALU_ctrl <= 4'b0001;
							decoding <= 6'd6;
						end
						6'h9: begin
							//addiu rt, rs, imm
							ALU_ctrl <= 4'b0000;
							decoding <= 6'd6;
						end
						6'he: begin
							//xor rt, rs, imm
							ALU_ctrl <= 4'b0110;
							decoding <= 6'd6;
						end
						6'ha: begin
							//slti rt, rs, imm
							ALU_ctrl <= 4'b1011;
							decoding <= 6'd6;
						end
						6'hb: begin
							//sltiu rt, rs, imm
							ALU_ctrl <= 4'b1010;
							decoding <= 6'd6;
						end
						6'hc: begin
							// andi rt, rs, imm
							ALU_ctrl <= 4'b0010;
							REG_raddr <= rs;
							decoding <= 6'd29;
						end
						6'hd: begin
							// ori rt, rs, imm
							ALU_ctrl <= 4'b0011;
							REG_raddr <= rs;
							decoding <= 6'd29;
						end
						6'he: begin
							// xori rt, rs, imm
							ALU_ctrl <= 4'b0110;
							REG_raddr <= rs;
							decoding <= 6'd29;
						end
						6'h1: begin
							//bltz rs, imm
							decoding <= 6'd10;
						end
						6'h4: begin
							//beq rs, rt, imm
							decoding <= 6'd37;
						end
						6'h5: begin
							//bne rs, rt, imm
							decoding <= 6'd37;
						end
						6'h6: begin
							//blez rs, imm
							decoding <= 6'd10;
						end
						6'h7: begin
							//bgtz rs, imm
							decoding <= 6'd10;
						end
						6'h2: begin
							//j target
							decoding <= 6'd13;
						end
						6'h3: begin
							//jal target
							decoding <= 6'd33;
						end
						6'hf: begin
							//lui rt, imm
							decoding <= 6'd27;
						end
						6'h20: begin
							//lb rt, offset(base)
							sgn_ext <= 1'b1;
							ls_byte <= 1'b1;
							decoding <= 6'd14;
						end
						6'h23: begin
							//lw rt, offset(base)
							ls_byte <= 1'b0;
							decoding <= 6'd14;
						end
						6'h24: begin
							//lbu rt, offset(base)
							sgn_ext <= 1'b0;
							ls_byte <= 1'b1;
							decoding <= 6'd14;
						end
						6'h2b: begin
							//sw rt, offset(base)
							ls_byte <= 1'b0;
							decoding <= 6'd20;
						end
						6'h28: begin
							//sb rt, offset(base)
							ls_byte <= 1'b1;
							decoding <= 6'd20;
						end
						default: begin
							//unknown, error!
							decoding <= 6'd63;
						end
					endcase
				end
				6'd1: begin
					//Read rs
					ALU_rs <= REG_rdata;
					REG_raddr <= rt;
					decoding <= 6'd2;
				end
				6'd2: begin
					//Read rt
					ALU_rt <= REG_rdata;
					// wait a little longer for division/multiplication
					if (funct == 6'h18 || funct == 6'h19 || funct == 6'h1a || funct == 6'h1b) begin
						alu_wait <= 3'd3;
					end else begin
						alu_wait <= 3'd0;
					end
					decoding <= 6'd3;
				end
				6'd3: begin
					//Calculate
					if ($signed(alu_wait) <= 0)
						decoding <= 6'd4;
					else
						alu_wait <= alu_wait - 3'd1;
				end
				6'd4: begin
					//Write rd
					case (funct)
					6'h18:
						{hi, lo} <= mul_result;
					6'h19:
						{hi, lo} <= mulu_result;
					6'h1a:
						{hi, lo} <= div_result;
					6'h1b:
						{hi, lo} <= divu_result;
					default:
						if (!ALU_overflow) begin
							REG_waddr <= rd;
							REG_wdata <= ALU_rd;
							REG_wren <= 1'b1;
						end
					endcase
					decoding <= 6'd5;
				end
				6'd5: begin
					//Finish
					REG_wren <= 1'b0;
					decoding <= 6'd0;
					ok <= 1'b1;
				end
				6'd6: begin
					//Read rs
					REG_raddr <= rs;
					decoding <= 6'd7;
				end
				6'd7: begin
					//Read imm
					ALU_rs <= REG_rdata;
					ALU_rt <= {{16{imm16[15]}},imm16};
					decoding <= 6'd8;
				end
				6'd8: begin
					//Calculate
					decoding <= 6'd9;
				end
				6'd9: begin
					//Write rt
					if (!ALU_overflow) begin
						REG_waddr <= rt;
						REG_wdata <= ALU_rd;
						REG_wren <= 1'b1;
					end
					decoding <= 6'd5;
				end
				6'd10: begin
					//Read rs;
					REG_raddr <= rs;
					decoding <= 6'd11;
				end
				6'd11: begin
					//Branch or not?
					if (br_cond) begin
						PC_decode_wdata <= PC_rdata+{{14{imm16[15]}}, imm16, 2'b00};
						PC_decode_wren <= 1'b1;
					end
					decoding <= 6'd12;
				end
				6'd12: begin
					//Finish jumping/branching
					PC_decode_wren <= 1'b0;
					decoding <= 6'd0;
					ok <= 1'b1;
				end
				6'd13: begin
					//Jump
					PC_decode_wdata <= {{4{imm26[25]}},imm26, 2'b00};
					PC_decode_wren <= 1'b1;
					decoding <= 6'd12;
				end
				6'd14: begin
					//Read base
					REG_raddr <= rs;
					decoding <= 6'd15;
				end
				6'd15: begin
					//Load MMemory
					MMemory_raddr <= REG_rdata+{{16{imm16[15]}}, imm16};
					decoding <= 6'd16;
				end
				6'd16: begin
					//Load MMemory[7:0]
					REG_wdata[7:0] <= MMemory_rdata;
					if (ls_byte) begin
						decoding <= 6'd19;
					end else begin
						MMemory_raddr <= MMemory_raddr+19'd1;
						decoding <= 6'd17;
					end
				end
				6'd17: begin
					//Load MMemory[15:8]
					REG_wdata[15:8] <= MMemory_rdata;
					MMemory_raddr <= MMemory_raddr+19'd1;
					decoding <= 6'd18;
				end
				6'd18: begin
					//Load MMemory[23:16]
					REG_wdata[23:16] <= MMemory_rdata;
					MMemory_raddr <= MMemory_raddr+19'd1;
					decoding <= 6'd19;
				end
				6'd19: begin
					//Load to rt
					if (ls_byte) begin
						REG_wdata[31:8] <= { 24 { sgn_ext ? REG_wdata[7] : 1'b0 } };
					end else begin
						REG_wdata[31:24] <= MMemory_rdata;
					end
					REG_waddr <= rt;
					REG_wren <= 1'b1;
					decoding <= 6'd5;
				end
				6'd20: begin
					//Read base
					REG_raddr <= rs;
					decoding <= 6'd21;
				end
				6'd21: begin
					//Save rt
					MMemory_waddr <= REG_rdata+{{16{imm16[15]}},imm16};
					REG_raddr <= rt;
					decoding <= 6'd22;
				end
				6'd22: begin
					//Save rt[7:0]
					MMemory_wdata <= REG_rdata[7:0];
					MMemory_wren <= 1'b1;
					if (ls_byte) begin
						decoding <= 6'd26;
					end else begin
						decoding <= 6'd23;
					end
				end
				6'd23: begin
					//Save rt[15:8]
					MMemory_waddr <= MMemory_waddr+19'd1;
					MMemory_wdata <= REG_rdata[15:8];
					decoding <= 6'd24;
				end
				6'd24: begin
					//Save rt[23:16]
					MMemory_waddr <= MMemory_waddr+19'd1;
					MMemory_wdata <= REG_rdata[23:16];
					decoding <= 6'd25;
				end
				6'd25: begin
					//Save rt[31:24]
					MMemory_waddr <= MMemory_waddr+19'd1;
					MMemory_wdata <= REG_rdata[31:24];
					decoding <= 6'd26;
				end
				6'd26: begin
					//Finish
					MMemory_wren <= 1'b0;
					decoding <= 6'd0;
					ok <= 1'b1;
				end
				// ====BEGIN lui====
				6'd27: begin
					REG_wdata <= {imm16[15:0], 16'h0};
					REG_waddr <= rt;
					REG_wren  <= 1'b1;
					decoding <= 6'd28;
				end
				6'd28: begin
					//Finish
					REG_wren <= 1'b0;
					decoding <= 6'd0;
					ok <= 1'b1;
				end
				// ====END lui====
				// ====BEGIN andi, ori, xori====
				6'd29: begin
					//Operands
					ALU_rs <= REG_rdata;
					ALU_rt <= {16'h0, imm16[15:0]};
					decoding <= 6'd30;
				end
				6'd30: begin
					//Calculate
					decoding <= 6'd31;
				end
				6'd31: begin
					//Write rt
					REG_waddr <= rt;
					REG_wdata <= ALU_rd;
					REG_wren <= 1'b1;
					decoding <= 6'd32;
				end
				6'd32: begin
					//Finish
					REG_wren <= 1'b0;
					decoding <= 6'd0;
					ok <= 1'b1;
				end
				// ====END andi, ori, xori====
				// ====BEGIN jal====
				6'd33: begin
					REG_waddr <= 5'd31; // $ra
					REG_wdata <= PC_rdata;
					REG_wren <= 1'b1;
					decoding <= 6'd34;
				end
				6'd34: begin
					REG_wren <= 1'b0;
					decoding <= 6'd13;
				end
				// ====END jal====
				// ====BEGIN jr====
				6'd35: begin
					REG_raddr <= rs;
					decoding <= 6'd36;
				end
				6'd36: begin
					PC_decode_wren  <= 1'b1;
					PC_decode_wdata <= REG_rdata;
					decoding        <= 6'd12;
				end
				// ====END jr====
				// ====BEGIN beq, bne====
				6'd37: begin
					REG_raddr <= rs;
					decoding  <= 6'd38;
				end
				6'd38: begin
					REG_raddr <= rt;
					br_rs     <= REG_rdata;
					decoding  <= 6'd39;
				end
				6'd39: begin
					br_rt     <= REG_rdata;
					decoding  <= 6'd11;
				end
				// ====END beq, bne====
				// ====BEGIN mfhi, mflo====
				6'd40: begin
					REG_waddr <= rd;
					REG_wdata <= hi;
					REG_wren  <= 1'b1;
					decoding <= 6'd42;
				end
				6'd41: begin
					REG_waddr <= rd;
					REG_wdata <= lo;
					REG_wren  <= 1'b1;
					decoding <= 6'd42;
				end
				6'd42: begin
					REG_wren <= 1'b0;
					decoding <= 6'd0;
					ok <= 1'b1;
				end
				// ====END mfhi, mflo====
				6'd43: begin
					// opcode  == 0
					REG_raddr <= rs;
					if (funct == 6'd8) begin
						// jr rs
						decoding <= 6'd35;
					end else if (funct == 6'd16) begin
						//mfhi rd
						decoding <= 6'd40;
					end else if (funct == 6'd18) begin
						//mflo rd
						decoding <= 6'd41;
					end else begin
						//opcode rd, rs, rt
						case (funct)
							6'h00: ALU_ctrl <= 4'b1100;
							6'h02: ALU_ctrl <= 4'b1101;
							6'h20: ALU_ctrl <= 4'b0001;
							6'h21: ALU_ctrl <= 4'b0000;
							6'h22: ALU_ctrl <= 4'b1001;
							6'h23: ALU_ctrl <= 4'b1000;
							6'h27: ALU_ctrl <= 4'b0101;
							6'h2a: ALU_ctrl <= 4'b1011;
							6'h2b: ALU_ctrl <= 4'b1010;
						endcase
						decoding <= 6'd1;
					end
				end
				6'd63: begin
					// error, be trapped here
				end
			endcase
		end else if (!run) begin
			decoding <= 6'd0;
			REG_wren <= 1'b0;
			PC_decode_wren <= 1'b0;
			MMemory_wren <= 1'b0;
			intr <= 1'b0;
			ok <= 1'b0;
		end
	end

	//Test
	assign test_decoding = decoding;
	
endmodule
