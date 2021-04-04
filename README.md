# DVP_to_FT
Streaming video over USB using FT232H synchronous FIFO mode and Cyclone IV FPGA.

Video:
[![Video](https://img.youtube.com/vi/lO4OpQYNTs4/0.jpg)](https://youtu.be/lO4OpQYNTs4)

# Block diagram
                            ______________________________________________
                           |                    FPGA                      |
                ______     |  ________       __________      __________   |   ________
               |      |    | | CAMERA |     | MAIN FSM |    | FT232H   |  |  |        |
               |CAMERA|----->| CAPTURE|<--->| & FIFO   |<-->| SYNC     |<--->| FT232H |
               |______|    |  --------       ----------     | INTERFACE|  |  |________|
                   ^       |  ________            |          ----------   |
                   |       | | CAMERA |           |                       |
                   ----------| CONFIG |           |                       |
                           |  --------            |                       |
                           |          Pixel clock | USB clock             |
                           |          domain      | domain                |
                           |______________________|_______________________| 
                           
# Top level module parameters
Top level module parameters define image resolution, color mode (grayscale or RGB565), camera I2C address and camera registers memory init file.

| Parameter       | Description                                              							|
| ----------------| ------------------------------------------------------------------------------------|
| IM_X            | Image width                                              							|
| IM_Y            | Image height                                             							|
| COLOR_MODE      | 1 - Grayscale, 2 - RGB565                                							|
| FPGA_PROCESSING | 1 - Convert RGB565 -> 8-bit Grayscale, 2 - No processing                            |
| CAMERA_ADDR     | Camera I2C address                                       							|
| MIF_FILE        | Camera registers memory init file                        							|
| FAST_SIM        | 0 - Normal mode, 1 - Fast sim mode, skip camera initialization                      |

# Camera configuration module
The camera configuration module initializes camera registers based on mif file and I2C address.

# Camera capture module
When configuration is done and start_stream signal set by the main FSM, the module waits for VSYNC falling edge and then captures pixel data from the camera by parallel DVP interface. 
If grayscale mode has been selected, the module converts RGB565 -> RGB888 -> 8-bit grayscale using simple pipeline. Otherwise, pixel data is written straight to the FIFO.
A line counter value is pushed to the FIFO before each image line.

# Main FSM
The main FSM module handles the following commands from the PC:

| Command | Description          |
| --------| ---------------------|
| 0x01    | Get image parameters |
| 0x11    | Start video stream   |
| 0x0f    | Stop video stream    |

After receiving the get image parameters command, a five-byte image parameters packet will be sent to the PC.

| Byte | Parameter | Description                     |
| -----| ----------| --------------------------------|
| 0    | IM_TYPE   | Grayscale - 0xAA, RGB565 - 0xBB |
| 1-2  | IM_X      | Image width                     |
| 3-4  | IM_Y      | Image height                    |

# Hardware
This design is based on the QMTECH Cyclone IV starter kit and the CJMCU FT232H breakout board.
https://github.com/ChinaQMTECH/CYCLONE_IV_STARTER_KIT

# FT232H setup

The Synchronous FIFO mode requires the external EEPROM. Configure following settings using FT_Prog (or other software, capable to write EEPROM)

| Parameter                                     | Value              |                                 							
| ----------------------------------------------| -------------------|
| Port A -> Hardware                            | 245 FIFO           |
| Port A -> Driver                              | D2XX Direct        |
| USB String Descriptors -> Product Description | FPGA Video Stream  |

# Software
Simple python-based clients for Windows and Linux are included.  
Common dependencies: Python 3.7+, NumPy, OpenCV.
Windows client works with standart FTDI D2XX driver.
Linux dependencies: libusb-1.0, python-libusb1 (https://github.com/vpelletier/python-libusb1)
Also you need to grant user permissions to access the FT232H device and unload ftdi_sio kernel module. Check example udev rules file in the software folder.
