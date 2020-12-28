module VGA_Controller(
	input pclk,
	input reset,
	output hsync,
	output vsync,
	output valid,
	// character display related
	input  [11:0] base_addr,
	input  [7:0]  base_addr_y,
	output [9:0]  h_addr,
	output [9:0]  v_addr,
	output [7:0]  chr_addr_x,
	output [3:0]  cur_chr_x,
	output [7:0]  chr_addr_y,
	output [3:0]  cur_chr_y,
	output [11:0] chr_addr,
	output chr_disp_valid
);

	parameter h_frontporch = 96;
	parameter h_active = 144;
	parameter h_backporch = 784;
	parameter h_total = 800;

	parameter v_frontporch = 2;
	parameter v_active = 35;
	parameter v_backporch = 515;
	parameter v_total = 525;

	parameter chr_width = 9;
	parameter chr_height = 16;
	parameter chr_cols = 70;
	parameter chr_rows = 30;
	parameter chr_count = chr_cols * chr_rows;

	reg [9:0] x_cnt;
	reg [9:0] y_cnt;
	reg [3:0] _cur_chr_x, _cur_chr_y;
	reg [7:0] _chr_addr_x, _chr_addr_y;
	reg [11:0] _chr_addr;
	reg wait_nl;

	wire h_valid;
	wire v_valid;

	initial begin
		x_cnt <= 10'd0;
		y_cnt <= 10'd0;
		_cur_chr_x <= 10'd0;
		_cur_chr_y <= 10'd0;
		_chr_addr <= 12'd0;
		wait_nl <= 1'b0;
	end

	always @(posedge pclk) begin
		if (!v_valid) begin
			// reset everything
			_cur_chr_x <= 0;
			_cur_chr_y <= 0;
			_chr_addr_x <= 0;
			_chr_addr_y <= base_addr_y;
			_chr_addr <= base_addr;
			wait_nl <= 0;
		end else begin
			if (h_valid) begin
				if (_chr_addr_x <= 68 || (_chr_addr_x == 69 && _cur_chr_x <= 8)) begin
					if (_cur_chr_x >= chr_width - 1) begin
						_cur_chr_x <= 0;
						// next character
						_chr_addr_x <= _chr_addr_x + 10'd1;
						_chr_addr <= _chr_addr + 12'd1;
					end else begin
						_cur_chr_x <= _cur_chr_x + 4'd1;
					end
					wait_nl <= 1;
				end
			end else if (wait_nl) begin
				// new line; increase y
				wait_nl <= 0;
				_cur_chr_x <= 0;
				_chr_addr_x <= 0;
				if (_cur_chr_y >= chr_height - 1) begin
					_cur_chr_y <= 0;
					if (_chr_addr_y == chr_rows - 1)
						_chr_addr_y <= 0;
					else
						_chr_addr_y <= _chr_addr_y + 8'd1;
					if (_chr_addr >= chr_rows * chr_cols)
						_chr_addr <= _chr_addr - chr_rows * chr_cols;
				end else begin
					_cur_chr_y <= _cur_chr_y + 10'd1;
					_chr_addr <= _chr_addr - chr_cols;
				end
			end
		end
	end

	always @(posedge pclk) begin
		if (reset == 1'b1) begin
			x_cnt <= 1;
		end else begin
			if (x_cnt == h_total) begin
				x_cnt <= 1;
			end else begin
				x_cnt <= x_cnt + 10'd1;
			end
		end

		if (reset == 1'b1)
			y_cnt <= 1;
		else begin
			if (y_cnt == v_total & x_cnt == h_total)
				y_cnt <= 1;
			else if (x_cnt == h_total)
				y_cnt <= y_cnt + 10'd1;
		end
	end

	assign hsync = (x_cnt > h_frontporch);
	assign vsync = (y_cnt > v_frontporch);

	assign h_valid = (x_cnt > h_active) & (x_cnt <= h_backporch);
	assign v_valid = (y_cnt > v_active) & (y_cnt <= v_backporch);
	assign valid = h_valid & v_valid;

	assign h_addr = h_valid ? (x_cnt - 10'd145) : {10{1'b0}};
	assign v_addr = v_valid ? (y_cnt - 10'd36 ) : {10{1'b0}};

	assign cur_chr_x = _cur_chr_x;
	assign cur_chr_y = _cur_chr_y;
	assign chr_addr_x = _chr_addr_x;
	assign chr_addr_y = _chr_addr_y;
	assign chr_addr = _chr_addr;

	assign chr_disp_valid = (x_cnt > h_active) & (x_cnt <= h_backporch - 10);

endmodule
