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

	// RAM状态
	parameter DEFAULT = -1;
	parameter WRITE = 0;
	parameter READ = 1;

	// 用户控制状态机状态
	parameter WRITE_ADD1 = 2;
	parameter WRITE_DATA1 = 3;
	parameter INCREASE_DATA1 = 4;
	parameter READ_DATA1 = 5;

	integer ram1_state = DEFAULT; // 记录ram1的状态
	integer state = WRITE_ADD1; // 记录用户输入状态机的状态
	integer count = 10; // 对输入数据个数计数
	integer delay = 0; // 记录延迟情况
	reg[15:0] data_to_write = 0; // 要写入RAM的数据
	reg[17:0] Ram1_first_address = 0; // 记录Ram1数据的首地址
	reg ram1_data_write = 1; // 标记数据线是否为写入Ram1的状态
	reg CLK_mark = 1; // 记录CLK的按下情况

	assign rdn = 1; // 关闭读串口
	assign wrn = 1; // 关闭写串口
	assign Ram1_data = ram1_data_write? data_to_write : 16'bZ;

	// 50MHz时钟，每跳一下记录CLK的按下情况，用于后续判断CLK的上升沿
	always @(posedge CLK1) begin
		CLK_mark <= CLK;
	end

	// CLK上升沿触发的计数器，非上升沿时不断加1
	always @(posedge CLK1) begin
		if (CLK < CLK_mark) begin // CLK下降沿，初始化为0
			delay <= 0;
		end else begin // 否则每个周期加1
			delay <= delay + 1;
		end
	end

	// 控制RAM1逻辑
	always @(posedge CLK1 or negedge RST) begin
		if (!RST) begin
			ram1_data_write <= 1; // 非高阻态
			Ram1_EN <= 1;
			Ram1_OE <= 1;
			Ram1_WE <= 1;
		end else if (CLK < CLK_mark) begin // CLK下降沿
			case (ram1_state)
				WRITE: begin
					ram1_data_write <= 1; // 非高阻态
					Ram1_EN <= 0;
					Ram1_OE <= 1;
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
		end else if (ram1_state == WRITE) begin // 写操作需要单独处理延时
			if (delay == 2) begin // Ram1开始写数据
				Ram1_WE <= 0;
			end else if (delay == 4) begin // Ram1写结束
				Ram1_WE <= 1;
			end
		end
	end

	// 用户输入控制逻辑
	always @(posedge CLK1 or negedge RST) begin
		if (!RST) begin
			state <= WRITE_ADD1;
			ram1_state <= DEFAULT;
			L <= 0;
			count <= 10;
			data_to_write <= 0;
		end else if (CLK < CLK_mark) begin // CLK下降沿
			case (state)
				WRITE_ADD1: begin
					Ram1_address <= {2'b0, SW};
					Ram1_first_address <= {2'b0, SW};
					L <= SW; // LED显示地址
					count <= 10;
					state <= WRITE_DATA1; // 状态转移
					ram1_state <= WRITE;
				end
				WRITE_DATA1: begin
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
					count <= count - 1;
				end
				READ_DATA1: begin
					Ram1_address <= Ram1_address + 1;
					count <= count - 1;
				end
				default: begin
					state <= WRITE_ADD1;
					ram1_state <= DEFAULT;
					L <= 0;
					count <= 10;
					data_to_write <= 0;
				end
			endcase
		end else if (state == INCREASE_DATA1) begin
			if (count == 0 && delay == 6) begin // 需要转移状态
				count <= 10;
				Ram1_address <= Ram1_first_address - 1;
				data_to_write <= 0;
				state <= READ_DATA1;
				ram1_state <= READ; // 读状态需要RAM提前做准备
			end
		end else if (state == READ_DATA1) begin
			if (delay == 2) begin // LED延迟显示数据，经测试不能省略，最短为2个50MHz周期
				L <= Ram1_data;
			end else if (count == 0 && delay == 4) begin // 需要转移状态
				count <= 10;
				state <= WRITE_ADD1;
			end
		end
	end

endmodule
