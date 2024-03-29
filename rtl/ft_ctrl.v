`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Dmitry Koroteev
// korob14@gmail.com
//////////////////////////////////////////////////////////////////////////////////
module ft_ctrl
#(	//Image params
	parameter IM_X = 640,
	parameter IM_Y = 480,
	parameter COLOR_MODE = 1
)
(
	input wire 			clk,
	input wire 			wrclk,
	input wire 			rst_n,
	input wire			in_valid,
	input wire	[7:0]	in_data,
	output wire			in_ready,
	output reg			start_stream,
	input wire 			rd_ready,
	input wire			wr_ready,
	input wire			data_valid,
	input wire	[7:0] read_data,
	output reg			read,
	output reg 			write,
	output reg   [7:0] write_data,
	output reg 			error
);
//Ctrl params
localparam GET_CFG = 8'h01;
localparam STRT_ST = 8'h11;
localparam STOP_ST = 8'h0f;
//FSM params
localparam IDLE = 0;
localparam RECV_CMD = 6'b000001;
localparam SEND_CFG = 6'b000010;
localparam WAIT_FIF = 6'b000100;
localparam SEND_CNT = 6'b001000;
localparam SEND_PIX = 6'b010000;
localparam PAUSE_SD = 6'b100000;
//Packet params
localparam PacketID = (COLOR_MODE == 1) ? 8'hAA : ((COLOR_MODE == 2) ? 8'hBB : 0);
localparam BYTES = COLOR_MODE * IM_X + 2;
localparam XBITS = $clog2(2*BYTES);

//declarations
wire [7:0] fifo_data;
wire fifo_full;
wire fifo_empty;
wire [XBITS - 1 : 0] usedw;
reg [15 : 0] line_cnt;
reg [XBITS - 1 : 0] send_cnt;
reg [5:0] ctrl_state;
reg [7:0] pkt_data;
reg [2:0] rdaddress;
wire rd_fifo = (ctrl_state == SEND_PIX) & wr_ready & !fifo_empty & (send_cnt < BYTES - 2);
reg wr_data;
reg sent_lcnt;

//pixel data fifo
assign in_ready = ~fifo_full;

dc_data_fifo #(.ADDR_W(XBITS)) dc_data_fifo_inst
(
	.rdclk(clk),
	.wrclk(wrclk),
	.rst_n(start_stream),
	.rdreq(rd_fifo),
	.wrreq(in_valid & !fifo_full),
	.data_in(in_data),
	.data_out(fifo_data),
	.rdempty(fifo_empty),
	.wrfull(fifo_full),
	.rdusedw(usedw)
);
//Stream params rom
always @(*)
case(rdaddress)
	'h00	:	pkt_data = PacketID; // Packet ID
	'h01	: 	pkt_data = IM_X ; // IM_X
	'h02	: 	pkt_data = IM_X>> 8; // IM_X
	'h03	: 	pkt_data = IM_Y ; // IM_Y
	'h04	: 	pkt_data = IM_Y>> 8; // IM_Y
	default: pkt_data = 8'h00;
endcase
//write to FT232H
always @ (posedge clk or negedge rst_n)
if (!rst_n)
	write <= 0;
else
	write <= ((ctrl_state == SEND_CFG) | (wr_data & (send_cnt <= BYTES - 2)) | ((ctrl_state == PAUSE_SD) |  (ctrl_state == SEND_CNT))) & wr_ready;
//FSM
always @ (posedge clk or negedge rst_n)
if (!rst_n) begin
	ctrl_state <= IDLE;
	rdaddress <= 0;
	read <= 0;
	start_stream <= 0;
	write_data <= 0;
	wr_data <= 0;
	sent_lcnt <= 0;
end
else begin
	case (ctrl_state)
		IDLE		:	begin
							start_stream <= 0;
							if (rd_ready) begin
								read <= 1'b1;
								ctrl_state <= RECV_CMD;
							end
						end
		RECV_CMD	:	begin
							read <= 0;
							if (data_valid) begin
								case (read_data)
									GET_CFG	:	ctrl_state <= SEND_CFG;
									STRT_ST	:	ctrl_state <= WAIT_FIF;
									STOP_ST	:	ctrl_state <= IDLE;
									default	:	ctrl_state <= IDLE;
								endcase
							end
						end
		SEND_CFG	:	begin
							if (wr_ready) begin
								
								rdaddress <= rdaddress + 1'b1;
								write_data <= pkt_data;
							end
							
							if (rdaddress == 'h04) begin
								rdaddress <= 0;
								ctrl_state <= IDLE;
							end
						end
		WAIT_FIF	:	begin
							start_stream <= 1'b1;
							if (rd_ready) begin
								read <= 1'b1;
								ctrl_state <= RECV_CMD;
							end
							if ((usedw >= BYTES -2) & wr_ready) begin
								ctrl_state <= SEND_CNT;
							end
						end
		SEND_CNT	:	begin
							if (wr_ready) begin
									sent_lcnt <= ~sent_lcnt;
									write_data <= sent_lcnt ? line_cnt[15:8] : line_cnt[7:0];
									if (sent_lcnt) begin
										ctrl_state <= SEND_PIX;
									end
							end
						end 
		SEND_PIX	:	begin
							if (wr_ready) begin
								if (send_cnt == BYTES - 1) begin
									wr_data <= 0;
									ctrl_state <= WAIT_FIF;
									end
								else begin
									wr_data <= 1'b1;
									write_data <= fifo_data;	
									end
								end
							else begin
								wr_data <= 0;
								ctrl_state <= PAUSE_SD;
								
								end
						end
		PAUSE_SD	:	begin
							if (wr_ready) begin
								if (send_cnt == 2) begin
									write_data <= fifo_data;
									ctrl_state <= SEND_PIX;
									end
								else begin
									wr_data <= 1'b1;
									ctrl_state <= SEND_PIX;
								end
								
							end
						end
		default	:	ctrl_state <= IDLE;
	
	endcase
end
//Send Cnt
always @ (posedge clk or negedge rst_n)
if (!rst_n)
	send_cnt <= 0;
else if (write & wr_ready)
	send_cnt <= send_cnt + 1'b1;
else if (ctrl_state == IDLE || ctrl_state == WAIT_FIF)
	send_cnt <= 0;
//line cnt
always @ (posedge clk or negedge rst_n)
if (!rst_n)
	line_cnt <= 0;
else if (((send_cnt == BYTES) && (line_cnt == IM_Y - 1)) || (ctrl_state == IDLE))
	line_cnt <= 0;
else if (send_cnt == BYTES)
	line_cnt <= line_cnt + 1'b1;
//error indication
wire err_rst = rst_n & start_stream;
always @ (posedge wrclk or negedge err_rst)
if (!err_rst)
	error <= 0;
else if (fifo_full && in_valid)
	error <= 1'b1;

	
endmodule
