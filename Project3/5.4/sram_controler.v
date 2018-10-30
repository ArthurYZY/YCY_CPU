module SRAM_CONTROLER(
	input wire RST,
	input wire[15:0] SW, // ���뿪���ź�
	input wire CLK, // �ֶ����Ƶ�ʱ���ź�
	input wire CLK1, // 50MHzʱ�Ӿ���
	output reg[15:0] L, // LED����ʾ
	output reg Ram1_EN, // Ram1ʹ��
	output reg Ram1_OE, // Ram1��ʹ��
	output reg Ram1_WE, // Ram1дʹ��
	output reg[17:0] Ram1_address, // Ram1��ַ
	inout wire[15:0] Ram1_data, // Ram1����
	output wire rdn, // �����ڣ�Ҫ�ر�
	output wire wrn // д���ڣ�Ҫ�ر�
	);

	parameter STOP = -1;

	parameter WRITE = 0;
	parameter READ = 1;

	parameter WRITE_ADD1 = 2;
	parameter WRITE_DATA1 = 3;
	parameter INCREASE_DATA1 = 4;
	parameter READ_DATA1 = 5;


	integer ram1_state; // ��¼ram1��״̬
	integer state; // ��¼�û�����״̬����״̬
	reg[15:0] data_to_write; // Ҫд��RAM������
	reg ram1_data_write = 1; // ����������Ƿ�Ϊд��Ram1��״̬
	reg [17:0] Ram1_first_address; // ��¼Ram1���ݵ��׵�ַ
	reg CLK_mark; // ��¼CLK�İ������
	reg [3:0] delay; // ��¼�ӳ����
	integer count = 10; // ���������ݸ�������

	assign rdn = 1; // �رն�����
	assign wrn = 1; // �ر�д����
	assign Ram1_data = ram1_data_write? data_to_write : 16'bZ;


	// 50MHzʱ�ӣ�ÿ��һ�¼�¼CLK�İ�����������ں����ж�CLK��������
	always @(posedge CLK1) begin
		CLK_mark <= CLK;
	end

	// CLK�����ش����ļ���������������ʱ���ϼ�1
	always @(posedge CLK1) begin
		if (CLK > CLK_mark) begin // CLK�����أ���ʼ��Ϊ0
			delay <= 0;
		end else begin // ����ÿ�����ڼ�1
			delay <= delay + 1; // TODO �Ƿ���Ҫ�ж�
		end
	end

	// ����RAM1�߼�
	always @(negedge RST or negedge CLK1) begin
		if (!RST) begin
			// TODO ��ʼ��
			ram1_data_write <= 1; // �Ǹ���̬
			Ram1_EN <= 1;
			Ram1_OE <= 1;
			Ram1_WE <= 1;
		end else if (CLK > CLK_mark) begin // CLK������
			case (ram1_state)
				WRITE: begin
					ram1_data_write <= 1; // �Ǹ���̬
				end
				READ: begin
					ram1_data_write <= 0; // ����̬
					Ram1_EN <= 0;
					Ram1_OE <= 0;
					Ram1_WE <= 1;
				end
				default: begin
					ram1_data_write <= 1; // �Ǹ���̬
					Ram1_EN <= 1;
					Ram1_OE <= 1;
					Ram1_WE <= 1;
				end
			endcase
		end else if (ram1_state == WRITE && delay > 0) begin // д������Ҫ����������ʱ
			if (delay == 2) begin // Ram1��ʼд����
				Ram1_EN <= 0;
				Ram1_WE <= 0;
				Ram1_OE <= 1;
			end else if (delay == 4) begin // Ram1д����
				Ram1_EN <= 0;
				Ram1_WE <= 1;
				Ram1_OE <= 1;
			end
		end
	end


	// �û���������߼�
	always @(posedge CLK1 or negedge RST) begin
		if (!RST) begin // TODO ��ʼ��
			state <= WRITE_ADD1;
			ram1_state <= STOP;
			L <= 0;
			count <= 10;
		end else if (CLK > CLK1) begin // CLK������
			case (state)
				WRITE_ADD1: begin
					Ram1_address <= {2'b0, SW};
					Ram1_first_address <= {2'b0, SW};
					// data_to_write <= 0;
					L <= SW; // LED��ʾ��ַ
					count <= 10;
					state <= WRITE_DATA1; // ״̬ת��
				end

				WRITE_DATA1: begin
					ram1_state <= WRITE; // TODO check correctness
					data_to_write <= SW;
					L <= SW; // LED��ʾ����
					state <= INCREASE_DATA1; // ״̬ת��
					count <= count - 1;
				end

				INCREASE_DATA1: begin
					data_to_write <= data_to_write + 1;
					Ram1_address <= Ram1_address + 1;
					L[7:0] <= data_to_write[7:0] + 1;
					L[15:8] <= Ram1_address[7:0] + 1;
					if (count > 0) begin // һֱд���ݣ�ֱ���涨��Ŀ
						count <= count - 1;
					end else begin
						count <= 10;
						Ram1_address <= Ram1_first_address;
						state <= READ_DATA1; // ״̬ת��
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
			L <= Ram1_data; // ��ȡ��������ʱ����һ����Ż���ʾ��ȷ
		end else if (state == READ_DATA1 && delay == 7) begin
			ram1_state <= READ; // ram��д����״̬ת����Ҫһ����ʱ
		end
	end
endmodule
