module statem(
	input 	wire    	clk,
	input 	wire    	rst,
	input 	wire[15:0] 	sw,
	output 	wire[15:0] 	Fout
    );

	reg[3:0]	op0 = 0;
	reg[15:0]	A0 = 0;
	reg[15:0]	B0 = 0;
	integer 	i = 0; 
	
  	wire			SF;		// sign flag
	wire			OF;		// overflow flag
  	wire			ZF;		// zero flag
	wire     		CF; 	// carry flag

	always @(posedge clk or negedge rst) begin
		if (rst == 0) begin
			i = 0;
			op0 = 0;
		end else if (i == 0) begin
			A0 = sw[15:0];
			i = i + 1;
		end else if (i == 1) begin
			B0 = sw[15:0];
			i = i + 1;
		end else if (i == 2) begin
			op0 = sw[3:0];
			i = i + 1;
		end else if (i == 3) begin
			op0 = 4'b0001;
			i = 0;
			A0 = {SF, OF, ZF, CF};
			B0 = 0;
		end
	end
	
	alu a(.op(op0), .A(A0), .B(B0), .out(Fout), .CF_out(CF), .OF_out(OF), .SF_out(SF), .ZF_out(ZF));

endmodule
