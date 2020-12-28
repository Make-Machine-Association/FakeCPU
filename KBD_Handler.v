module KBD_Handler (
	input ps2_clk,
	input ps2_dat,
	input clk_50,
	input mem_clk,
	input [7:0] kbd_en,
	output reg [7:0] kbd_buflen,
	input [7:0] kbd_ra,
	output reg [7:0] kbd_char
);

	//// Part 1: Communication with keyboard ////

	reg        is_release;
	wire [7:0] _key_data;
	reg  [7:0] key_data;
	wire       overflow;
	wire       ready;

	reg [3:0] kbd_state;

	reg shift, ctrl, caps_lock;

	reg nextdata_n;
	reg pressed [255:0];

	PS2_Keyboard ps2_kbd_controller (
		.clk        (clk_50),
		.clrn       (1'b1),
		.ps2_clk    (ps2_clk),
		.ps2_data   (ps2_dat),
		.data       (_key_data),
		.ready      (ready),
		.nextdata_n (nextdata_n),
		.overflow   (overflow)
	);

	initial begin
		shift      <= 1'b0;
		ctrl       <= 1'b0;
		caps_lock  <= 1'b0;
		nextdata_n <= 1'b1;
		is_release <= 1'b0;
	end

	always @(negedge clk_50) begin
		case (kbd_state)
		4'd0: begin
			// wait for ready
			if (ready) begin
				nextdata_n <= 1'b1;
				key_data <= _key_data;
				kbd_state <= 4'd1;
			end
		end
		4'd1: begin
			// reserved
			kbd_state <= 4'd2;
		end
		4'd2: begin
			if (key_data == 8'hF0) begin
				is_release <= 1'b1;
			end else begin
				is_release <= 1'b0;
				pressed[key_data] <= !is_release;
				if (key_data == 8'h12)
					shift <= !is_release;
				if (key_data == 8'h14)
					ctrl  <= !is_release;
				if (pressed[key_data] && is_release) begin
					if (key_data == 8'h58)
						caps_lock <= !caps_lock;
				end
			end
			kbd_state <= 4'd3;
		end
		4'd3: begin
			// move pointer
			nextdata_n <= 1'b0;
			kbd_state <= 4'd0;
		end
		default: begin
			kbd_state <= 4'd3;
		end
		endcase
	end

	//// Part 2: Handle "keypress events" & output ////

	parameter KBD_BUFSIZ = 16;
	parameter kp_intv_first = 18'd84000, kp_intv_norm = 18'd32000;

	parameter kp_off = 2'd0, kp_wait = 2'd1, kp_exec = 2'd2;
	reg [1:0] kp_state [127:0];
	reg kp_not_first [127:0];
	reg [17:0] kp_intv [127:0];
	reg [6:0] kp_cur_i;

	reg [7:0] kbd_buf [KBD_BUFSIZ-1:0];

	wire [7:0] ascii_noshift, ascii_shifted, ascii_nocaps, ascii_caps, ascii;
	assign ascii_nocaps = shift ? ascii_shifted : ascii_noshift;
	assign ascii_caps   = 
		(ascii_nocaps >= 8'd97 && ascii_nocaps <= 8'd122) ? ascii_nocaps - 8'd32 :
		(ascii_nocaps >= 8'd65 && ascii_nocaps <= 8'd90)  ? ascii_nocaps + 8'd32 :
		ascii_nocaps;
	assign ascii = caps_lock ? ascii_caps : ascii_nocaps;

	wire modifier = ascii_noshift == 0;

	initial begin
		kbd_state   <= 0;
		kbd_buflen  <= 0;
	end

	KeyTable kt (
		.clock     ( clk_50 ),
		.address   ( {1'b0, kp_cur_i} ),
		.q         ( ascii_noshift )
	);
	KeyTable_Shift kt_shift (
		.clock     ( clk_50 ),
		.address   ( {1'b0, kp_cur_i}) ,
		.q         ( ascii_shifted )
	);

	always @(negedge mem_clk) begin
		// FSM
		case (kp_state[kp_cur_i])
		kp_off: begin
			if (pressed[kp_cur_i]) begin
				// let's handle this keypress
				kp_state[kp_cur_i] <= kp_exec;
				kp_not_first[kp_cur_i] <= 0;
			end else begin
				// otherwise, move on to check the next key
				kp_cur_i <= kp_cur_i + 1;
			end
		end
		kp_exec: begin
			// skip modifier keys
			if (modifier) begin
				kp_state[kp_cur_i] <= kp_off;
				kp_cur_i <= kp_cur_i + 1;
			end else begin
				// first, reset the interval
				kp_not_first[kp_cur_i] <= 1;
				if (kp_not_first[kp_cur_i])
					kp_intv[kp_cur_i] <= kp_intv_norm;
				else
					kp_intv[kp_cur_i] <= kp_intv_first;
				// then, handle this keypress
				if (kbd_en && kbd_buflen < KBD_BUFSIZ) begin
					kbd_buf[kbd_buflen] <= ascii;
					kbd_buflen <= kbd_buflen + 8'd1;
				end
				// move to the next state
				kp_state[kp_cur_i] <= kp_wait;
				kp_cur_i <= kp_cur_i + 1;
			end
		end
		kp_wait: begin
			if (pressed[kp_cur_i]) begin
				if ($signed(kp_intv[kp_cur_i]) <= 0) begin
					kp_state[kp_cur_i] <= kp_exec;
				end else begin
					kp_intv[kp_cur_i] <= kp_intv[kp_cur_i] - 32'd1;
					kp_cur_i <= kp_cur_i + 1;
				end
			end else
				kp_state[kp_cur_i] <= kp_off;
		end
		endcase
		//
		if (!kbd_en) begin
			// invalidate buffer
			kbd_buflen <= 0;
		end
		kbd_char <= kbd_buf[kbd_ra];
	end

endmodule
