`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Dmitry Koroteev
// korob14@gmail.com
//////////////////////////////////////////////////////////////////////////////////
//
// 
// | reg settings              | COLOR_MODE | FPGA_PROCESSING |               Comment                     |
// | OV5642_1280p_20f_rgb.mif  |     2      |        2        | 1280 x 720 x 20 FPS RGB565                |
// | OV5642_1280p_30f_rgb.mif  |     1      |        1        | 1280 x 720 x 30 FPS GRAY8 FPGA processing |
// | OV5642_1920p_7.5f_rgb.mif |     2      |        2        | 1920 x 1080 x 7.5 FPS RGB565              |
// | OV5642_1920p_15f_gray.mif |     1      |        2        | 1920 x 1080 x 15 FPS GRAY8 Cam processing |
module dvp_to_ft
#(	parameter IM_X = 1280,
	parameter IM_Y = 720,
	parameter COLOR_MODE = 2,		// 1 - Grayscale, 2 - RGB565
	parameter FPGA_PROCESSING = 2, // 1 - Convert RGB565 -> 8-bit Grayscale, 2 - No processing
	parameter CAMERA_ADDR = 8'h78,// 8'h60 - OV2640, 8'h42 - OV7670, 8'h78 - OV5642
	parameter MIF_FILE = "./rtl/cam_config/OV5642_1280p_20f_rgb.mif", // Camera registers init file
	parameter FAST_SIM = 0			// 1- Fast simulation mode, skip camera initialization
)
(
	//System
	input 		clk_50,
	input 		rst_n,
	//FT232H
	input 		clk,
	input 		RXF_n,
	input 		TXE_n,
	output 		OE_n,
	output 		RD_n,
	output 		WR_n,
	output 		SI_n,
	inout	[7:0] DATA,
	//Cam DVP & SCCB
	input	[7:0]	data_cam,
	input 		VSYNC_cam,
	input 		HREF_cam,
	input 		PCLK_cam,	
	output		XCLK_cam,
	output		res_cam,
	output		on_off_cam,	
	output		sioc,
	output		siod
	
);
//declarations
wire  [7:0] write_data;
wire  [7:0] read_data;
wire write;
wire read;
wire wr_ready;
wire rd_ready;
wire data_valid;
wire rst_s;
wire			conf_done;
wire 	[7:0] pixdata;
wire 			pixdata_valid;
wire 			in_ready;
wire			start_stream;
wire			wrclk;
//assignments
assign res_cam = 0;
assign XCLK_cam = 1'bz;

//rst sync
sync rst_sync
(
	.in				(rst_n),
	.clk				(clk_50),
	.out				(rst_s)
);

//camera config
camera_configure 
#(	
    .CLK_FREQ		(50000000),
	 .CAMERA_ADDR	(CAMERA_ADDR),
	 .MIF_FILE		(MIF_FILE),
	 .I2C_ADDR_16	(1'b1),
	 .FAST_SIM		(FAST_SIM)
)
camera_configure_0
(
    .clk				(clk_50),	
	 .rst_n			(rst_s),
	 .sioc			(sioc),
    .siod			(siod),
	 .done			(conf_done)
	
);

//cam capture
cam_capture 
#(
	.COLOR_MODE		(FPGA_PROCESSING),
	.IM_X				(IM_X),
	.IM_Y				(IM_Y)
)
cam_capture_0
(
	.rst_n			(rst_s & conf_done),
	.data_cam		(data_cam),
	.VSYNC_cam		(VSYNC_cam),
	.HREF_cam		(HREF_cam),
	.PCLK_cam		(PCLK_cam),
	.pixel			(pixdata),
	.pixel_valid	(pixdata_valid),
	.out_ready		(in_ready),
	.start_stream	(start_stream)	

);

//FT232H interface
FT_Sync FT_Sync_inst
(
	.clk				(clk),
	.rst_n			(rst_s),
	.RXF_n			(RXF_n),
	.TXE_n			(TXE_n),
	.OE_n				(OE_n),
	.RD_n				(RD_n),
	.WR_n				(WR_n),
	.SI_n				(SI_n),
	.DATA				(DATA),
	.write_data		(write_data),
	.wr				(write),
	.rd				(read),
	.wr_ready		(wr_ready),
	.rd_ready		(rd_ready),
	.read_data		(read_data),
	.data_valid		(data_valid)
);
//main control
ft_ctrl
#(
	.IM_X				(IM_X),
	.IM_Y				(IM_Y),
	.COLOR_MODE		(COLOR_MODE)
) ft_ctrl_inst
(
	.clk				(clk),
	.wrclk			(PCLK_cam),
	.rst_n			(rst_s),
	.in_valid		(pixdata_valid),
	.in_data			(pixdata),
	.in_ready		(in_ready),
	.start_stream	(start_stream),
	.rd_ready		(rd_ready),
	.wr_ready		(wr_ready),
	.data_valid		(data_valid),
	.read_data		(read_data),
	.read				(read),
	.write			(write),
	.write_data		(write_data)
);
endmodule
