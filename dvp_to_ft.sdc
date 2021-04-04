#system clock
create_clock -name clk_50 -period "50 MHz" [get_ports clk_50]
#FT232H USB clock
create_clock -name clk -period "60 MHz" [get_ports clk]
#create the associated virtual input clock
create_clock -name virt_clk_usb -period "60 MHz"

#determine internal clock uncertainties
derive_clock_uncertainty

set_clock_groups -exclusive -group {clk virt_clk_usb}
#create the input delay referencing the virtual clock
#specify the maximum external clock delay from the external
#device
set CLKAs_max 0.0
#specify the minimum external clock delay from the external
#device
set CLKAs_min 0.0
#specify the maximum external clock delay to the FPGA
set CLKAd_max 0.200
#specify the minimum external clock delay to the FPGA
set CLKAd_min 0.2
#specify the maximum clock-to-out of the external device
set tCOa_max 9
#specify the minimum clock-to-out of the external device
set tCOa_min 0
#specify the maximum board delay
set BDa_max 0.2
#specify the minimum board delay
set BDa_min 0.2

set_input_delay -clock virt_clk_usb -max [expr $CLKAs_max + $tCOa_max + $BDa_max - $CLKAd_min] [get_ports {DATA[*]}]
set_input_delay -clock virt_clk_usb -max [expr $CLKAs_max + $tCOa_max + $BDa_max - $CLKAd_min] [get_ports {RXF_n}]
set_input_delay -clock virt_clk_usb -max [expr $CLKAs_max + $tCOa_max + $BDa_max - $CLKAd_min] [get_ports {TXE_n}]

set_input_delay -clock virt_clk_usb -min [expr $CLKAs_min + $tCOa_min + $BDa_min - $CLKAd_max] [get_ports {DATA[*]}]
set_input_delay -clock virt_clk_usb -min [expr $CLKAs_min + $tCOa_min + $BDa_min - $CLKAd_max] [get_ports {RXF_n}]
set_input_delay -clock virt_clk_usb -min [expr $CLKAs_min + $tCOa_min + $BDa_min - $CLKAd_max] [get_ports {TXE_n}]
#creating the output delay referencing the virtual clock
#specify the maximum external clock delay to the FPGA
set CLKBs_max 0.2
#specify the minimum external clock delay to the FPGA
set CLKBs_min 0.2
#specify the maximum external clock delay to the external device
set CLKBd_max 0.0
#specify the minimum external clock delay to the external device
set CLKBd_min 0.0
#specify the maximum setup time of the external device
set tSUb 7.5
#specify the hold time of the external device
set tHb 0.0
#specify the maximum board delay
set BDb_max 0.2
#specify the minimum board delay
set BDb_min 0.2

set_output_delay -clock virt_clk_usb -max [expr $CLKBs_max + $tSUb + $BDb_max - $CLKBd_min] [get_ports {DATA[*]}]
set_output_delay -clock virt_clk_usb -max [expr $CLKBs_max + $tSUb + $BDb_max - $CLKBd_min] [get_ports {OE_n}]
set_output_delay -clock virt_clk_usb -max [expr $CLKBs_max + $tSUb + $BDb_max - $CLKBd_min] [get_ports {RD_n}]
set_output_delay -clock virt_clk_usb -max [expr $CLKBs_max + $tSUb + $BDb_max - $CLKBd_min] [get_ports {WR_n}]
set_output_delay -clock virt_clk_usb -max [expr $CLKBs_max + $tSUb + $BDb_max - $CLKBd_min] [get_ports {SI_n}]

set_output_delay -clock virt_clk_usb -min [expr $CLKBs_min - $tHb + $BDb_min - $CLKBd_max] [get_ports {DATA[*]}]
set_output_delay -clock virt_clk_usb -min [expr $CLKBs_min - $tHb + $BDb_min - $CLKBd_max] [get_ports {OE_n}]
set_output_delay -clock virt_clk_usb -min [expr $CLKBs_min - $tHb + $BDb_min - $CLKBd_max] [get_ports {RD_n}]
set_output_delay -clock virt_clk_usb -min [expr $CLKBs_min - $tHb + $BDb_min - $CLKBd_max] [get_ports {WR_n}]
set_output_delay -clock virt_clk_usb -min [expr $CLKBs_min - $tHb + $BDb_min - $CLKBd_max] [get_ports {SI_n}]

set_false_path -from [get_ports {rst_n}] -to {*}
set_false_path -to [get_ports {sioc}]
set_false_path -to [get_ports {siod}]

#OV5642 camera clock
set PCLK_FREQ "96MHz"
set CAM_DATA_DELAY 2.500

create_clock -name {PCLK_cam} -period $PCLK_FREQ [get_ports {PCLK_cam}]
create_clock -name {virt_clk_cam} -period $PCLK_FREQ

set_clock_groups -exclusive -group [get_clocks {PCLK_cam virt_clk_cam}] 

set_clock_groups -asynchronous -group [get_clocks {PCLK_cam}] -group [get_clocks {clk}] -group [get_clocks {clk_50}] 

#create the input delay referencing the virtual clock
#specify the maximum external clock delay from the external
#device
set CLKAs_max 0.0
#specify the minimum external clock delay from the external
#device
set CLKAs_min 0.0
#specify the maximum external clock delay to the FPGA
set CLKAd_max [expr 50*0.007]
#specify the minimum external clock delay to the FPGA
set CLKAd_min [expr 50*0.007]
#specify the maximum clock-to-out of the external device
set tCOa_max $CAM_DATA_DELAY
#specify the minimum clock-to-out of the external device
set tCOa_min 0
#specify the maximum board delay
set BDa_max [expr 50*0.007]
#specify the minimum board delay
set BDa_min [expr 50*0.007]

set_input_delay -add_delay -min -clock_fall -clock [get_clocks {virt_clk_cam}]  [expr $CLKAs_min + $tCOa_min + $BDa_min - $CLKAd_max] [get_ports {HREF_cam}]
set_input_delay -add_delay -min -clock_fall -clock [get_clocks {virt_clk_cam}]  [expr $CLKAs_min + $tCOa_min + $BDa_min - $CLKAd_max] [get_ports {VSYNC_cam}]
set_input_delay -add_delay -min -clock_fall -clock [get_clocks {virt_clk_cam}]  [expr $CLKAs_min + $tCOa_min + $BDa_min - $CLKAd_max] [get_ports {data_cam[*]}]
set_input_delay -add_delay -max -clock_fall -clock [get_clocks {virt_clk_cam}]  [expr $CLKAs_max + $tCOa_max + $BDa_max - $CLKAd_min] [get_ports {HREF_cam}]
set_input_delay -add_delay -max -clock_fall -clock [get_clocks {virt_clk_cam}]  [expr $CLKAs_max + $tCOa_max + $BDa_max - $CLKAd_min] [get_ports {VSYNC_cam}]
set_input_delay -add_delay -max -clock_fall -clock [get_clocks {virt_clk_cam}]  [expr $CLKAs_max + $tCOa_max + $BDa_max - $CLKAd_min] [get_ports {data_cam[*]}]



