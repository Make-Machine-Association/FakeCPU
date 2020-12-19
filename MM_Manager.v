module MM_Manager(
	input clk,
	input [7:0]MMemory_wdata,
	input MMemory_wren,
	input [31:0]MMemory_waddr,
	input [31:0]MMemory_raddr,
	input [31:0]MMemory_VGA_raddr,
	input intr,
	output [7:0]MMemory_rdata,
	//Test
	input [31:0]MMemory_test_addr,
	input test_intr
	);
	
	reg [18:0]raddr;
	
	MMemory mm_ram(clk, MMemory_wdata, raddr, MMemory_waddr[18:0], MMemory_wren, MMemory_rdata);
	
	always @ (posedge clk)
	begin
		if (test_intr) raddr <= MMemory_test_addr[18:0];
		else if (intr) raddr <= MMemory_VGA_raddr[18:0];
		else raddr <= MMemory_raddr[18:0];
	end
	
endmodule
