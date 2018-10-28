module alu(
	input 	wire[3:0]	op,
	input	wire[15:0]	A,
	input	wire[15:0]	B,
	output	reg[15:0]	out,
	output wire     		CF_out, 	//��λ
  	output wire			ZF_out,		// zero flag
  	output wire			SF_out,		// sign flag
	output wire			OF_out		// overflow flag
	);
	
	reg 	SF; 	// sign flag
	reg 	OF; 	// overflow flag
	reg 	ZF; 	// zero flag
	reg 	CF; 	// carry flag
	
	assign SF_out = SF;
	assign OF_out = OF;
	assign ZF_out = ZF;
	assign CF_out = CF;

	always @(*) begin
		case(op)
			// �����룺ADD
			4'b0001: begin
				{CF, out} = {0, A} + {0, B}; // CF��ʾ��λ��Ϣ���н�λΪ1
				OF = ($signed(A) > 0 && $signed(B) > 0 && $signed(out) < 0)||($signed(A) < 0 && $signed(B) < 0 && $signed(out) >= 0);
			end
			// �����룺SUB
			4'b0010: begin
				{CF, out} = {1, A} - {0, B};
				CF = ~ CF; // CF��ʾ��λ��Ϣ���н�λΪ1
				OF = ($signed(out) < 0 && $signed(A) > 0 && $signed(B) < 0)||($signed(out) > 0 && $signed(A) < 0 && $signed(B) > 0);
			end
				
			// �����룺AND
			4'b0011: begin
				out = A & B;
				CF = 0;
				OF = 0;
			end
				
			// �����룺OR
			4'b0100: begin
				out = A | B;
				CF = 0;
				OF = 0;
			end
			
			// �����룺XOR
			4'b0101: begin
				out = A ^ B;
				CF = 0;
				OF = 0;
			end
			
			// �����룺NOT
			4'b0110: begin
				out = ~ A;
				CF = 0;
				OF = 0;
			end

			// �����룺SLL
			4'b0111: begin
				out = A << B;
				CF = 0;
				OF = 0;
			end

			// �����룺SRL
			4'b1000: begin
				out = A >> B;
				CF = 0;
				OF = 0;
			end

			// �����룺SRA
			4'b1001: begin
				out = $signed(A) >>> B;
				CF = 0;
				OF = 0;
			end

			// �����룺ROL
			4'b1010: begin
				out = (A << B) | (A >> (16 - B));
				CF = 0;
				OF = 0;
			end

			// �����룺NOP
			default: begin
				out = 0;
				CF = 0;
				OF = 0;
			end

		endcase
		SF = out[15];
		ZF = ($signed(out) == 0);
	end

endmodule
