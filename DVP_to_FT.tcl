# Copyright (C) 2020  Intel Corporation. All rights reserved.
# Your use of Intel Corporation's design tools, logic functions 
# and other software and tools, and any partner logic 
# functions, and any output files from any of the foregoing 
# (including device programming or simulation files), and any 
# associated documentation or information are expressly subject 
# to the terms and conditions of the Intel Program License 
# Subscription Agreement, the Intel Quartus Prime License Agreement,
# the Intel FPGA IP License Agreement, or other applicable license
# agreement, including, without limitation, that your use is for
# the sole purpose of programming logic devices manufactured by
# Intel and sold by Intel or its authorized distributors.  Please
# refer to the applicable agreement for further details, at
# https://fpgasoftware.intel.com/eula.

# Quartus Prime Version 20.1.0 Build 711 06/05/2020 SJ Lite Edition
# File: C:\Users\KoroB\Documents\MEGA\FPGA\FT245_Sync_test\FT245_Sync_test.tcl
# Generated on: Fri Jan 08 15:22:51 2021

package require ::quartus::project

set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to DATA[7]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to DATA[6]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to DATA[5]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to DATA[4]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to DATA[3]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to DATA[2]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to DATA[1]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to DATA[0]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to OE_n
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to RD_n
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to RXF_n
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SI_n
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to TXE_n
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to WR_n
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to clk
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to rst_n
set_location_assignment PIN_J4 -to rst_n
set_location_assignment PIN_H19 -to DATA[7]
set_location_assignment PIN_F19 -to DATA[6]
set_location_assignment PIN_D20 -to DATA[5]
set_location_assignment PIN_D19 -to DATA[4]
set_location_assignment PIN_D17 -to DATA[3]
set_location_assignment PIN_B20 -to DATA[2]
set_location_assignment PIN_B19 -to DATA[1]
set_location_assignment PIN_B18 -to DATA[0]
set_location_assignment PIN_C22 -to RXF_n
set_location_assignment PIN_B22 -to TXE_n
set_location_assignment PIN_H20 -to RD_n
set_location_assignment PIN_F20 -to WR_n
set_location_assignment PIN_C20 -to SI_n
set_location_assignment PIN_C19 -to clk
set_location_assignment PIN_C17 -to OE_n
set_instance_assignment -name CURRENT_STRENGTH_NEW 8MA -to OE_n
set_instance_assignment -name CURRENT_STRENGTH_NEW 8MA -to DATA[0]
set_instance_assignment -name CURRENT_STRENGTH_NEW 8MA -to DATA[1]
set_instance_assignment -name CURRENT_STRENGTH_NEW 8MA -to DATA[2]
set_instance_assignment -name CURRENT_STRENGTH_NEW 8MA -to DATA[3]
set_instance_assignment -name CURRENT_STRENGTH_NEW 8MA -to DATA[4]
set_instance_assignment -name CURRENT_STRENGTH_NEW 8MA -to DATA[5]
set_instance_assignment -name CURRENT_STRENGTH_NEW 8MA -to DATA[6]
set_instance_assignment -name CURRENT_STRENGTH_NEW 8MA -to DATA[7]
set_instance_assignment -name CURRENT_STRENGTH_NEW 8MA -to rst_n
set_instance_assignment -name CURRENT_STRENGTH_NEW 8MA -to clk
set_instance_assignment -name CURRENT_STRENGTH_NEW 8MA -to TXE_n
set_instance_assignment -name CURRENT_STRENGTH_NEW 8MA -to RXF_n
set_instance_assignment -name CURRENT_STRENGTH_NEW 8MA -to WR_n
set_instance_assignment -name CURRENT_STRENGTH_NEW 8MA -to SI_n
set_instance_assignment -name CURRENT_STRENGTH_NEW 8MA -to RD_n
set_instance_assignment -name SLEW_RATE 2 -to WR_n
set_instance_assignment -name SLEW_RATE 2 -to DATA[0]
set_instance_assignment -name SLEW_RATE 2 -to DATA[1]
set_instance_assignment -name SLEW_RATE 2 -to DATA[2]
set_instance_assignment -name SLEW_RATE 2 -to DATA[3]
set_instance_assignment -name SLEW_RATE 2 -to DATA[4]
set_instance_assignment -name SLEW_RATE 2 -to DATA[5]
set_instance_assignment -name SLEW_RATE 2 -to DATA[6]
set_instance_assignment -name SLEW_RATE 2 -to DATA[7]
set_instance_assignment -name SLEW_RATE 2 -to rst_n
set_instance_assignment -name SLEW_RATE 2 -to clk
set_instance_assignment -name SLEW_RATE 2 -to TXE_n
set_instance_assignment -name SLEW_RATE 2 -to RXF_n
set_instance_assignment -name SLEW_RATE 2 -to SI_n
set_instance_assignment -name SLEW_RATE 2 -to RD_n
set_instance_assignment -name SLEW_RATE 2 -to OE_n
set_location_assignment PIN_A8 -to sioc
set_location_assignment PIN_B8 -to siod
set_location_assignment PIN_A7 -to VSYNC_cam
set_location_assignment PIN_B7 -to HREF_cam
set_location_assignment PIN_A6 -to PCLK_cam
set_location_assignment PIN_B6 -to XCLK_cam
set_location_assignment PIN_A5 -to data_cam[7]
set_location_assignment PIN_B5 -to data_cam[6]
set_location_assignment PIN_A4 -to data_cam[5]
set_location_assignment PIN_B4 -to data_cam[4]
set_location_assignment PIN_A3 -to data_cam[3]
set_location_assignment PIN_B3 -to data_cam[2]
set_location_assignment PIN_B1 -to data_cam[1]
set_location_assignment PIN_B2 -to data_cam[0]
set_location_assignment PIN_C1 -to res_cam
set_location_assignment PIN_C2 -to on_off_cam
set_instance_assignment -name IO_STANDARD "3.0-V LVCMOS" -to HREF_cam
set_instance_assignment -name IO_STANDARD "3.0-V LVCMOS" -to PCLK_cam
set_instance_assignment -name IO_STANDARD "3.0-V LVCMOS" -to VSYNC_cam
set_instance_assignment -name IO_STANDARD "3.0-V LVCMOS" -to XCLK_cam
set_instance_assignment -name IO_STANDARD "3.0-V LVCMOS" -to data_cam[7]
set_instance_assignment -name IO_STANDARD "3.0-V LVCMOS" -to data_cam[6]
set_instance_assignment -name IO_STANDARD "3.0-V LVCMOS" -to data_cam[5]
set_instance_assignment -name IO_STANDARD "3.0-V LVCMOS" -to data_cam[4]
set_instance_assignment -name IO_STANDARD "3.0-V LVCMOS" -to data_cam[3]
set_instance_assignment -name IO_STANDARD "3.0-V LVCMOS" -to data_cam[2]
set_instance_assignment -name IO_STANDARD "3.0-V LVCMOS" -to data_cam[1]
set_instance_assignment -name IO_STANDARD "3.0-V LVCMOS" -to data_cam[0]
set_instance_assignment -name IO_STANDARD "3.0-V LVCMOS" -to on_off_cam
set_instance_assignment -name IO_STANDARD "3.0-V LVCMOS" -to res_cam
set_instance_assignment -name IO_STANDARD "3.0-V LVCMOS" -to sioc
set_instance_assignment -name IO_STANDARD "3.0-V LVCMOS" -to siod
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to siod
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to sioc