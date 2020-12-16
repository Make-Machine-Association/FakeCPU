module PC_register(
	input clk,
	input [31:0]wdata,
	input wren,
	output [31:0]rdata
	);
	reg [31:0]PC;
	
	assign rdata = PC;
	
	always @ (posedge clk)
	begin
		if (wren) PC <= wdata;
	end
	
endmodule
