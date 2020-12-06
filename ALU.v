module ALU(
	input [25:0]rs,
	input [25:0]rt,
	input [3:0]ctrl,
	output reg [25:0]rd,
	output reg overflow
	);
	wire [25:0]addu;
	wire [25:0]add;
	wire [25:0]and_;
	wire [25:0]or_;
	wire [25:0]not_;
	wire [25:0]nor_;
	wire [25:0]xor_;
	wire [25:0]neg;
	wire [25:0]subu;
	wire [25:0]sub;
	wire [25:0]sltu;
	wire [25:0]slt;
	wire [25:0]neg_rt;
	wire addOF;
	wire subOF;
	wire subSF;
	wire subZF;
	
	assign neg_rt = ~rt;
	
	assign addu = rs+rt;
	assign add = rs+rt;
	assign and_ = rs & rt;
	assign or_ = rs | rt;
	assign not_ = ~rs;
	assign nor_ = ~(rs | rt);
	assign xor_ = rs ^ rt;
	assign neg = -rs;
	assign subu = rs+neg_rt+1'b1;
	assign sub = rs+neg_rt+1'b1;
	assign sltu = rs < rt;
	
	assign addOF = (rs[25] == rt[25]) && (add[25] != rs[25]);
	
	assign subOF = (rs[25] == neg_rt[25]) && (sub[25] != rs[25]);
	assign subSF = sub[25];
	assign subZF = ~(|sub);
	
	assign slt = (subOF != subSF) && (!subZF);
	
	always @ (*)
	begin
		overflow = 1'b0;
		case (ctrl)
			4'b0000: rd = addu;
			4'b0001: begin
				rd = add;
				overflow = addOF;
			end
			4'b0010: rd = and_;
			4'b0011: rd = or_;
			4'b0100: rd = not_;
			4'b0101: rd = nor_;
			4'b0110: rd = xor_;
			4'b0111: rd = neg;
			4'b1000: rd = subu;
			4'b1001: begin
				rd = sub;
				overflow = subOF;
			end
			4'b1010: rd = sltu;
			4'b1011: rd = slt;
			default: rd = 26'd0;
		endcase
	end
	
endmodule