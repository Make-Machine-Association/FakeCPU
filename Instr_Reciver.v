module Instr_Reciver(
	input clk;
	input [7:0]instr_1B,
	input [31:0]MMemory_data,
	input [31:0]REG_data,
	output [18:0]instr_addr,
	output [18:0]MMemory_addr,
	output [4:0]REG_addr
	);
	reg [31:0]instr;
	reg [18:0]PC;
	reg [2:0]solving;
	reg run;
	wire ok;
	
	Decode dc(clk, instr, PC, run, MMemory_data, REG_data, ok, MMemory_addr, REG_addr);
	
	always @ (posedge clk)
	begin
		case (solving)
			3'b000: begin
				instr_addr <= PC;
				instr <= {instr[23:0], instr_1B};
				solving <= 3'b001;
			end
			3'b001: begin
				instr_addr <= instr_addr+19'd1;
				instr <= {instr[23:0], instr_1B};
				solving <= 3'b010;
			end
			3'b010: begin
				instr_addr <= instr_addr+19'd1;
				instr <= {instr[23:0], instr_1B};
				solving <= 3'b011;
			end
			3'b011: begin
				instr_addr <= instr_addr+19'd1;
				instr <= {instr[23:0], instr_1B};
				solving <= 3'b100;
			end
			3'b100: begin
				if (instr == 32'h00000000) begin
					solving <= 3'b110;
				end else begin
					run <= 1'b1;
					solving <= 3'b101;
				end
			end
			3'b101: begin
				if (ok) begin
					run <= 1'b0;
					solving <= 3'b000;
				end
			end
			3'b110: begin
				//TODO
			end
		endcase
	end
	
endmodule
