module REG(
	input clk,
	input wren,
	input [4:0]inaddr,
	input [4:0]outaddr,
	input [31:0]din,
	output [31:0]dout
	);
	reg [31:0]register[31:0];
	
	assign dout = register[outaddr];
	
	always @ (posedge clk)
	begin
		if (wren) register[inaddr] <= din;
	end
	
endmodule
