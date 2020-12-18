module MM_Manager(
	input clk,
	input [7:0]MMemory_wdata,
	input MMemory_wren,
	input [18:0]MMemory_waddr,
	input [18:0]MMemory_raddr,
	input [18:0]MMemory_VGA_raddr,
	input intr,
	output [7:0]MMemory_rdata
	);
	
	reg [18:0]raddr;
	
	MMemory mm_ram(clk, MMemory_wdata, raddr, MMemory_waddr, MMemory_wren, MMemory_rdata);
	
	always @ (posedge clk)
	begin
		if (intr) raddr <= MMemory_VGA_raddr;
		else raddr <= MMemory_raddr;
	end
	
endmodule
