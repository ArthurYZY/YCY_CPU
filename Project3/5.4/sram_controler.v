module SRAM_CONTROLER(
	input wire CLK,
	input wire RST,
	input wire[15:0] SW,
	output reg OE,
	output reg WE,
	output wire EN,
	output wire[17:0] address,
	inout wire[15:0] data,
	output reg[15:0] data_in);

	integer i = 0; 
	reg[17:0] address_reg = 8; 
	reg[15:0] data_out = 2;
	reg data_write_mode = 1 ;
	assign address = address_reg;
	assign data = data_write_mode? data_out : 16'bZ;
	// assign WE = data_write_mode;
	assign EN = 0;

	always @(posedge CLK or negedge RST) begin
		if (!RST) begin
			i <= 0;
			data_write_mode <= 1;
			data_in <= 1;
			data_out <= 5;
			OE <= 1;
			WE <= 1;
			// EN <= 1;
		end else begin
			case(i)
				0: begin
					// data_write_mode <= 0;
					WE <= 0;
					// EN <= 0;
				end
				1: begin
					WE <= 1;
					// EN <= 1;
				end
				2 : begin
					data_write_mode <= 0;
					OE <= 0;
					// EN <= 0;
				end
				3: begin
					data_in <= data;
				end
			endcase
			i <= i + 1;
		end
	end

endmodule
