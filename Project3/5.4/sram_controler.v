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

	// RAM״̬
	parameter DEFAULT = -1;
	parameter WRITE = 0;
	parameter READ = 1;

	// �û�����״̬��״̬
	parameter WRITE_ADD1 = 2;
	parameter WRITE_DATA1 = 3;
	parameter INCREASE_DATA1 = 4;
	parameter READ_DATA1 = 5;

	integer ram1_state = DEFAULT; // ��¼ram1��״̬
	integer state = WRITE_ADD1; // ��¼�û�����״̬����״̬
	integer count = 10; // ���������ݸ�������
	integer delay = 0; // ��¼�ӳ����
	reg[15:0] data_to_write = 0; // Ҫд��RAM������
	reg[17:0] Ram1_first_address = 0; // ��¼Ram1���ݵ��׵�ַ
	reg ram1_data_write = 1; // ����������Ƿ�Ϊд��Ram1��״̬
	reg CLK_mark = 1; // ��¼CLK�İ������

	assign rdn = 1; // �رն�����
	assign wrn = 1; // �ر�д����
	assign Ram1_data = ram1_data_write? data_to_write : 16'bZ;

	// 50MHzʱ�ӣ�ÿ��һ�¼�¼CLK�İ�����������ں����ж�CLK��������
	always @(posedge CLK1) begin
		CLK_mark <= CLK;
	end

	// CLK�����ش����ļ���������������ʱ���ϼ�1
	always @(posedge CLK1) begin
		if (CLK < CLK_mark) begin // CLK�½��أ���ʼ��Ϊ0
			delay <= 0;
		end else begin // ����ÿ�����ڼ�1
			delay <= delay + 1;
		end
	end

	// ����RAM1�߼�
	always @(posedge CLK1 or negedge RST) begin
		if (!RST) begin
			ram1_data_write <= 1; // �Ǹ���̬
			Ram1_EN <= 1;
			Ram1_OE <= 1;
			Ram1_WE <= 1;
		end else if (CLK < CLK_mark) begin // CLK�½���
			case (ram1_state)
				WRITE: begin
					ram1_data_write <= 1; // �Ǹ���̬
					Ram1_EN <= 0;
					Ram1_OE <= 1;
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
		end else if (ram1_state == WRITE) begin // д������Ҫ����������ʱ
			if (delay == 2) begin // Ram1��ʼд����
				Ram1_WE <= 0;
			end else if (delay == 4) begin // Ram1д����
				Ram1_WE <= 1;
			end
		end
	end

	// �û���������߼�
	always @(posedge CLK1 or negedge RST) begin
		if (!RST) begin
			state <= WRITE_ADD1;
			ram1_state <= DEFAULT;
			L <= 0;
			count <= 10;
			data_to_write <= 0;
		end else if (CLK < CLK_mark) begin // CLK�½���
			case (state)
				WRITE_ADD1: begin
					Ram1_address <= {2'b0, SW};
					Ram1_first_address <= {2'b0, SW};
					L <= SW; // LED��ʾ��ַ
					count <= 10;
					state <= WRITE_DATA1; // ״̬ת��
					ram1_state <= WRITE;
				end
				WRITE_DATA1: begin
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
			if (count == 0 && delay == 6) begin // ��Ҫת��״̬
				count <= 10;
				Ram1_address <= Ram1_first_address - 1;
				data_to_write <= 0;
				state <= READ_DATA1;
				ram1_state <= READ; // ��״̬��ҪRAM��ǰ��׼��
			end
		end else if (state == READ_DATA1) begin
			if (delay == 2) begin // LED�ӳ���ʾ���ݣ������Բ���ʡ�ԣ����Ϊ2��50MHz����
				L <= Ram1_data;
			end else if (count == 0 && delay == 4) begin // ��Ҫת��״̬
				count <= 10;
				state <= WRITE_ADD1;
			end
		end
	end

endmodule
