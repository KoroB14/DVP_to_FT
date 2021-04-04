//////////////////////////////////////////////////////////////////////////////////
// Dmitry Koroteev
// korob14@gmail.com
//////////////////////////////////////////////////////////////////////////////////
`timescale 1 ns / 1 ps

module FT_Sync
(
	input 				clk,
	input 				rst_n,
	input 				RXF_n,
	input 				TXE_n,
	output reg 			OE_n = 1'b1,
	output reg 			RD_n = 1'b1,
	output  				WR_n ,
	output reg 			SI_n = 1'b1,
	inout 		[7:0] DATA,
	input 		[7:0] write_data,
	input 				wr,
	input 				rd,
	output 				wr_ready,
	output				rd_ready,
	output reg	[7:0] read_data,
	output reg			data_valid
);
//params
parameter CNT_SI = 0;

localparam IDLE = 0;
localparam READ = 2'b01;
localparam WRITE = 2'b10;
//declarations
reg rd_r = 0;
reg [1:0] state;
reg [15:0] send_cnt;
//assignments
assign wr_ready = ~TXE_n & (state != READ);
assign rd_ready = ~RXF_n & (state != WRITE);
assign DATA = (wr) ? write_data : 8'bZ; //tristate bus
assign WR_n = ~wr;
//FSM
always @ (posedge clk or negedge rst_n)
if (!rst_n) begin
	state <= IDLE;
	RD_n <= 1'b1;
	OE_n <= 1'b1;
	SI_n <= 1'b1;
	rd_r <= 0;
	read_data <= 0;
	end
else begin
	case (state)
		IDLE 		 : begin
							RD_n <= 1'b1;
							OE_n <= 1'b1;
							SI_n <= 1'b1;
							if (wr & !TXE_n) begin
								state <= WRITE;
							end
							else if (rd & !RXF_n) begin
								OE_n <= 0;
								state <= READ;
								rd_r <= 1'b1;
							end
							
							
						end
		READ		 : begin
							if ((!RXF_n) & (rd | rd_r)) begin
								read_data <= DATA;
								RD_n <= 0;
								rd_r <= 0;
								end
							else begin
								state <= IDLE;
								RD_n <= 1'b1;
								OE_n <= 1'b1;
								end
							
						end
		
		WRITE		 : begin
							if (TXE_n | !wr) begin
								
								state <= IDLE;
							if (CNT_SI > 1) begin : Generate_Check_SI_Counter	
								if (send_cnt < CNT_SI - 1)
									SI_n <= 0;
								end
							end
							
						end
		default   : state <= IDLE;
		
	endcase
	
end

always @ (posedge clk or negedge rst_n)
if (!rst_n)
	data_valid <= 0;
else
	data_valid <= !(OE_n | RD_n | RXF_n);

generate	
if (CNT_SI > 1) begin : Generate_SI_Counter

always @ (posedge clk or negedge rst_n)
if (!rst_n)
	send_cnt <= 0;
else if (!WR_n & !TXE_n)
	send_cnt <= send_cnt + 1'b1;
else if ((state == IDLE) )
	send_cnt <= 0;

end
endgenerate	
endmodule
