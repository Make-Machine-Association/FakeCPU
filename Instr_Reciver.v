module Instr_Reciver(
	input clk,
	input [7:0]instr_1B,
	input [7:0]MMemory_rdata,
	output [7:0]MMemory_wdata,
	input [31:0]REG_rdata,
	output [31:0]REG_wdata,
	output reg [31:0]instr_addr,
	output [31:0]MMemory_raddr,
	output [31:0]MMemory_waddr,
	output MMemory_wren,
	output [4:0]REG_raddr,
	output [4:0]REG_waddr,
	output REG_wren,
	input [31:0]PC_rdata,
	output reg [31:0]PC_instr_wdata,
	output reg PC_instr_wren,
	output [31:0]PC_decode_wdata,
	output PC_decode_wren,
	output intr,
	input go,
	output reg finish,
	//Test
	output [31:0]test_instr,
	output [4:0]test_decoding,
	output [2:0]test_solving,
	output test_run,
	output test_ok
	);
	reg [31:0]instr;
	reg [2:0]solving;
	reg run;
	wire ok;
	
	assign test_instr = instr;
	assign test_solving = solving;
	
	Decode dc(clk, instr, run, MMemory_rdata, MMemory_wdata, REG_rdata, REG_wdata, ok, 
		MMemory_raddr, MMemory_waddr, MMemory_wren, REG_raddr, REG_waddr, REG_wren, PC_decode_wdata, PC_decode_wren, PC_rdata, intr, 
		test_decoding);
	
	initial
	begin
		instr = 32'd0;
		solving = 3'b000;
		run = 1'b0;
		finish = 1'b0;
	end
	
	always @ (posedge clk)
	begin
		if (go && !finish) begin
			case (solving)
				3'b000: begin
					instr_addr <= PC_rdata;
					PC_instr_wdata <= PC_rdata+32'd1;
					PC_instr_wren <= 1'b1;
					solving <= 3'b001;
				end
				3'b001: begin
					instr_addr <= PC_rdata;
					instr <= {instr[23:0], instr_1B};
					PC_instr_wdata <= PC_rdata+32'd1;
					solving <= 3'b010;
				end
				3'b010: begin
					instr_addr <= PC_rdata;
					instr <= {instr[23:0], instr_1B};
					PC_instr_wdata <= PC_rdata+32'd1;
					solving <= 3'b011;
				end
				3'b011: begin
					instr_addr <= PC_rdata;
					instr <= {instr[23:0], instr_1B};
					PC_instr_wdata <= PC_rdata+32'd1;
					solving <= 3'b100;
				end
				3'b100: begin
					instr <= {instr[23:0], instr_1B};
					PC_instr_wren <= 1'b0;
					solving <= 3'b101;
				end
				3'b101: begin
					/*
					if (instr == 32'h00000000) begin
						solving <= 3'b000;
						finish <= 1'b1;
					end else begin
						run <= 1'b1;
						solving <= 3'b110;
					end
					*/
					run <= 1'b1;
					solving <= 3'b110;
				end
				3'b110: begin
					if (ok) begin
						run <= 1'b0;
						solving <= 3'b000;
					end
				end
			endcase
		end else if (!go) begin
			solving <= 3'b000;
			finish <= 1'b0;
		end
	end
	
	//Test
	assign test_run = run;
	assign test_ok = ok;
	
endmodule
