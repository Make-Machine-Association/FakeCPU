module clkgen(
	input clkin,
	input rst,
	input clken,
	output reg clkout
	);
	parameter dest_freq = 1000;
	parameter orig_freq = 50000000;
	parameter countlimit = orig_freq/2/dest_freq;
	reg[31:0] clkcount;
	
	initial
	begin
		clkout = 1'b0;
		clkcount = 32'd0;
	end
	
	always @ (posedge clkin)
	begin
		if (rst) begin
			clkcount = 0;
			clkout = 1'b0;
		end else begin
			if (clken)
			begin
				clkcount = clkcount+1;
				if (clkcount >= countlimit) begin
					clkcount = 32'd0;
					clkout = ~clkout;
				end else clkout = clkout;
			end else begin
				clkcount = clkcount;
				clkout = clkout;
			end
		end
	end
	
endmodule
