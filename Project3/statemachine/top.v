`define READ 0
`define WRITE 1
`define RAM 2
`define HIGH 16'bz

module top(
	input wire CLK, // 11MHz时钟
	input wire RST,
	output reg Ram1_OE,
	output reg Ram1_WE,
	output reg Ram1_EN,
	input wire data_ready,
	output reg rdn,
	input wire tbre,
	input wire tsre,
	output reg wrn,
	inout wire[15:0] data,
	output reg[15:0] data_in,
	// input wire CLK1, // 50MHz时钟
	output wire[17:0] Ram1_address
    );

	integer i = 0;
	reg get_data = 1;
	reg func = 0;
	reg[15:0] data_tmp; 
	integer state = 0;
	integer delay = 0; // 记录延迟情况
	integer mark = 0; // 记录是否开始延�

	// RAM状�
	parameter _DEFAULT = -1;
	parameter _WRITE = 0;
	parameter _WRITE1 = 1;
	parameter _READ = 2;
	parameter _END = 3;
	parameter _WRITE0 = 4;

	assign data = (get_data)? data_tmp : `HIGH ;
	assign Ram1_address = 9; // Ram1地址

	always @(posedge CLK or negedge RST) begin
		if (!RST) begin
			Ram1_EN <= 1;
			Ram1_OE <= 1;
			Ram1_WE <= 1;

			wrn <= 1;
			rdn <= 1;

			state <= 1;
			data_in <= 16'h00;
			func <= `READ;
			
		end
		else if(func == `READ) begin
			case (state)
				1:begin
					rdn <= 1;
					state <= state + 1;
					get_data <= 0;
				end
				2:begin
					if(data_ready == 1)begin
						rdn <= 0;
						state <= 3;
					end else state <= 1;
				end
				3:begin
					data_in <= data;
					rdn <= 1;
					// func <= `RAM;
					// state <= _WRITE0;
					// get_data <= 1;
					func <= `WRITE;
					state <= 1;
				end
			endcase
		end
		else if (func == `RAM) begin
			case (state)
				_WRITE0: begin
					data_tmp <= data_in;
					Ram1_EN <= 0;
					Ram1_OE <= 1;
					Ram1_WE <= 1;
					state <= _WRITE;
				end
				_WRITE: begin
					Ram1_EN <= 0;
					Ram1_OE <= 1;
					Ram1_WE <= 0;
					state <= _WRITE1;
				end
				_WRITE1: begin
					Ram1_EN <= 0;
					Ram1_OE <= 1;
					Ram1_WE <= 1;
					state <= _READ;
				end
				_READ: begin
					Ram1_EN <= 0;
					Ram1_OE <= 0;
					Ram1_WE <= 1;
					get_data <= 0;
					// data_tmp <= data;
					state <= _END;
					// state <= 1;
					// func <= `WRITE;
				end
				_END: begin
					Ram1_EN <= 1;
					Ram1_OE <= 1;
					Ram1_WE <= 1;
					// get_data <= 1;
					func <= `WRITE;
					state <= 1;
				end
			endcase
		end
		else if(func == `WRITE) begin 		
			case (state)
				1:begin
					// data_out <= SW;
					wrn <= 0;	
					state <= 2;
				end
				2:begin
					wrn <= 1;
					state <= 3;
				end
				3:begin
					if(tbre == 1) begin 
						state <= 4;
					end
				end
				4:begin
					if(tsre == 1) begin
						Ram1_EN <= 1;
						Ram1_OE <= 1;
						Ram1_WE <= 1;

						wrn <= 1;
						rdn <= 1;

						state <= 1;
						data_in <= 16'h00;
						func <= `READ;
					end
				end
			endcase

		end
	end

endmodule