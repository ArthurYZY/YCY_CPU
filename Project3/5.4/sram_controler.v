module SRAM_CONTROLER(
	input wire RST,
	input wire[15:0] SW, // 拨码开关信号
	input wire CLK, // 手动控制的时钟信号
	input wire CLK1, // 50MHz时钟晶振
	output reg[15:0] L, // LED灯显示
	output reg Ram1_EN, // Ram1使能
	output reg Ram1_OE, // Ram1读使能
	output reg Ram1_WE, // Ram1写使能
	output reg[17:0] Ram1_address, // Ram1地址
	inout wire[15:0] Ram1_data, // Ram1数据
	output wire rdn, // 读串口，要关闭
	output wire wrn // 写串口，要关闭
	);

	parameter STOP = -1;

	parameter WRITE = 0;
	parameter READ = 1;

	parameter WRITE_ADD1 = 2;
	parameter WRITE_DATA1 = 3;
	parameter INCREASE_DATA1 = 4;
	parameter READ_DATA1 = 5;


	integer ram1_state; // 记录ram1的状态
	integer state; // 记录用户输入状态机的状态
	reg[15:0] data_to_write; // 要写入RAM的数据
	reg ram1_data_write = 1; // 标记数据线是否为写入Ram1的状态
	reg [17:0] Ram1_first_address; // 记录Ram1数据的首地址
	reg CLK_mark; // 记录CLK的按下情况
	reg [3:0] delay; // 记录延迟情况
	integer count = 10; // 对输入数据个数计数

	assign rdn = 1; // 关闭读串口
	assign wrn = 1; // 关闭写串口
	assign Ram1_data = ram1_data_write? data_to_write : 16'bZ;


	// 50MHz时钟，每跳一下记录CLK的按下情况，用于后续判断CLK的上升沿
	always @(posedge CLK1) begin
		CLK_mark <= CLK;
	end

	// CLK上升沿触发的计数器，非上升沿时不断加1
	always @(posedge CLK1) begin
		if (CLK > CLK_mark) begin // CLK上升沿，初始化为0
			delay <= 0;
		end else begin // 否则每个周期加1
			delay <= delay + 1; // TODO 是否需要判断
		end
	end

	// 控制RAM1逻辑
	always @(negedge RST or negedge CLK1) begin
		if (!RST) begin
			// TODO 初始化
			ram1_data_write <= 1; // 非高阻态
			Ram1_EN <= 1;
			Ram1_OE <= 1;
			Ram1_WE <= 1;
		end else if (CLK > CLK_mark) begin // CLK上升沿
			case (ram1_state)
				WRITE: begin
					ram1_data_write <= 1; // 非高阻态
				end
				READ: begin
					ram1_data_write <= 0; // 高阻态
					Ram1_EN <= 0;
					Ram1_OE <= 0;
					Ram1_WE <= 1;
				end
				default: begin
					ram1_data_write <= 1; // 非高阻态
					Ram1_EN <= 1;
					Ram1_OE <= 1;
					Ram1_WE <= 1;
				end
			endcase
		end else if (ram1_state == WRITE && delay > 0) begin // 写操作需要单独处理延时
			if (delay == 2) begin // Ram1开始写数据
				Ram1_EN <= 0;
				Ram1_WE <= 0;
				Ram1_OE <= 1;
			end else if (delay == 4) begin // Ram1写结束
				Ram1_EN <= 0;
				Ram1_WE <= 1;
				Ram1_OE <= 1;
			end
		end
	end


	// 用户输入控制逻辑
	always @(posedge CLK1 or negedge RST) begin
		if (!RST) begin // TODO 初始化
			state <= WRITE_ADD1;
			ram1_state <= STOP;
			L <= 0;
			count <= 10;
		end else if (CLK > CLK1) begin // CLK上升沿
			case (state)
				WRITE_ADD1: begin
					Ram1_address <= {2'b0, SW};
					Ram1_first_address <= {2'b0, SW};
					// data_to_write <= 0;
					L <= SW; // LED显示地址
					count <= 10;
					state <= WRITE_DATA1; // 状态转移
				end

				WRITE_DATA1: begin
					ram1_state <= WRITE; // TODO check correctness
					data_to_write <= SW;
					L <= SW; // LED显示数据
					state <= INCREASE_DATA1; // 状态转移
					count <= count - 1;
				end

				INCREASE_DATA1: begin
					data_to_write <= data_to_write + 1;
					Ram1_address <= Ram1_address + 1;
					L[7:0] <= data_to_write[7:0] + 1;
					L[15:8] <= Ram1_address[7:0] + 1;
					if (count > 0) begin // 一直写数据，直到规定数目
						count <= count - 1;
					end else begin
						count <= 10;
						Ram1_address <= Ram1_first_address;
						state <= READ_DATA1; // 状态转移
					end
				end

				READ_DATA1: begin
					if (count > 0) begin
						count <= count - 1;
						Ram1_address <= Ram1_address + 1;
					end else begin
						state <= WRITE_ADD1;
						count <= 10;
						ram1_state <= STOP;
						L <= 0;
					end
				end

				default: begin
					state <= WRITE_ADD1;
					ram1_state <= STOP;
					L <= 0;
					count <= 10;
				end
			endcase
		end else if (state == READ_DATA1 && delay == 4) begin
			L <= Ram1_data; // 读取数据有延时，等一会儿才会显示正确
		end else if (state == READ_DATA1 && delay == 7) begin
			ram1_state <= READ; // ram从写到读状态转换需要一定延时
		end
	end
endmodule
