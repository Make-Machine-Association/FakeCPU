module PC_register(
	input clk,
	//Init
	input [31:0]init_wdata,
	input init_wren,
	//For Instr_Reciver
	input [31:0]instr_wdata,
	input instr_wren,
	//For Decode
	input [31:0]decode_wdata,
	input decode_wren,
	output [31:0]rdata
	);
	reg [31:0]PC;
	
	assign rdata = PC;
	
	always @ (posedge clk)
	begin
		if (init_wren) PC <= init_wdata;
		else if (instr_wren) PC <= instr_wdata;
		else if (decode_wren) PC <= decode_wdata;
	end
	
endmodule
