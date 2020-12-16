module Instr_Reciver(
	input clk,
	input [31:0]instr_1B,
	input [31:0]MMemory_rdata,
	output [31:0]MMemory_wdata,
	input [31:0]REG_rdata,
	output [31:0]REG_wdata,
	output reg [16:0]instr_addr,
	output [16:0]MMemory_raddr,
	output [16:0]MMemory_waddr,
	output MMemory_wren,
	output [4:0]REG_raddr,
	output [4:0]REG_waddr,
	output REG_wren,
	input [31:0]PC_rdata,
	output [31:0]PC_wdata,
	output PC_wren
	);
	reg [31:0]instr;
	reg [1:0]solving;
	reg run;
	wire ok;
	
	Decode dc(clk, instr, PC, run, MMemory_rdata, MMemory_wdata, REG_rdata, REG_wdata, ok, 
		MMemory_raddr, MMemory_waddr, MMemory_wren, REG_raddr, REG_waddr, REG_wren, PC_wdata, PC_wren);
	
	always @ (posedge clk)
	begin
		case (solving)
			2'b00: begin
				instr_addr <= PC_rdata[16:0];
				instr <= instr_1B;
				solving <= 2'b01;
			end
			2'b01: begin
				if (instr == 32'h00000000) begin
					solving <= 2'b11;
				end else begin
					run <= 1'b1;
					solving <= 2'b10;
				end
			end
			2'b10: begin
				if (ok) begin
					run <= 1'b0;
					solving <= 2'b00;
				end
			end
			2'b11: begin
				//TODO
			end
		endcase
	end
	
endmodule
