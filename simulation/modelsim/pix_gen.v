module pix_gen
#(	parameter HREF, 
	parameter HREF_pause,
	parameter Line_max,
	parameter Vsync,
	parameter Vsync_pause,
	parameter Vsync_back,
	parameter COLOR_MODE,
	parameter SIMPLE_SIGNAL
)
(
	output reg		[7:0]	data_cam,
	output reg	 			VSYNC_cam,
	output reg	 			HREF_cam,
	input			 			PCLK_cam	
	
	
);

//////////////////
//generate cam sync signals
reg [15:0] pix_cnt = 0,line_cnt = 0;
reg [7:0] frame_cnt = 0;

always @ (posedge PCLK_cam)
	if (pix_cnt < HREF + HREF_pause)
		pix_cnt <= pix_cnt + 1'b1;
	else
		pix_cnt <= 0;

reg even_line = 0; 
always @ (posedge PCLK_cam)
	if (line_cnt == Line_max - 1)
		line_cnt <= 0;
	else if (pix_cnt == HREF + HREF_pause - 1) begin
		line_cnt <= line_cnt + 1'b1;
		even_line <= ~even_line;
		end

always @ (posedge PCLK_cam)
	VSYNC_cam <= (line_cnt < Vsync);
	
reg HREF_int = 0;
always @ (posedge PCLK_cam) begin
	HREF_int <= ((line_cnt > Vsync + Vsync_pause - 1) && (line_cnt < Line_max - Vsync_back ) && (pix_cnt < HREF));
	HREF_cam <= HREF_int; 
	end

//generate cam data_cam
reg second_byte = 0;
reg [7:0] red = 0, green = 0, blue = 0;
wire [7:0] W = {8{pix_cnt[7:0]==line_cnt[7:0]}};
wire [7:0] A = {8{pix_cnt[7:5]==3'h2 && line_cnt[7:5]==3'h2}};

always @(posedge PCLK_cam) 
	red <= ({pix_cnt[5:0] & {6{line_cnt[4:3]==~pix_cnt[4:3]}}, 2'b00} | W) & ~A;
always @(posedge PCLK_cam) 
	green <= (pix_cnt[7:0] & {8{line_cnt[6]}} | W) & ~A;
always @(posedge PCLK_cam) 
	blue <= line_cnt[7:0] | W | A;

wire [4:0] r = red * 31 / 255;
wire [5:0] g = green * 63 / 255;
wire [4:0] b = blue * 31 / 255;

always @ (posedge PCLK_cam)
	if (HREF_int) begin
		second_byte <= ~second_byte;
		if (COLOR_MODE == 2)
			if (second_byte)//second byte
				if (SIMPLE_SIGNAL == 1)
					data_cam <= 8'hBB;
				else if (SIMPLE_SIGNAL == 2) begin
						if (pix_cnt < HREF / 3) begin
							data_cam <= 0;
							end
						else if ((pix_cnt >= HREF / 3) & (pix_cnt < 2*HREF/3)) begin
							data_cam <= {3'b111, 5'b0};
							end
						else begin
							data_cam <= {3'b000, 5'b11111};
							end
						end
				else
					data_cam <= {g[2:0], b};
			else// first byte
				if (SIMPLE_SIGNAL == 1)
					data_cam <= 8'hAA;
				else if (SIMPLE_SIGNAL == 2) begin
						if (pix_cnt < HREF / 3) begin
							data_cam <= {5'b11111, 3'b0};
							end
						else if ((pix_cnt >= HREF / 3) & (pix_cnt < 2*HREF/3)) begin
							data_cam <= {5'b00000, 3'b111};
							end
						else begin
							data_cam <= 0;
							end
					end
				else
					data_cam <= {r , g[5:3]};
			
		else if (COLOR_MODE == 1)
			if (SIMPLE_SIGNAL == 1)
				data_cam <= 8'h55;
			else
				data_cam <= (red>>2)+(red>>5)+(green>>1)+(green>>4)+(blue>>4)+(blue>>5);
	end	
	else
		data_cam <= 0;
		
endmodule
