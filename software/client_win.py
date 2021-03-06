#!/usr/bin/env python
# coding: utf-8

from ctypes import *
import numpy as np
import cv2
import threading
#
#Press "s" to save the frame. Press "q" to quit. 
#

###############################################
# Open driver dll
ftd2xx = cdll.LoadLibrary('ftd2xx.dll')

ftd2xx.FT_OpenEx.argtypes = [c_void_p, c_ulong, POINTER(c_void_p)]
ftd2xx.FT_OpenEx.restype = c_ulong
ftd2xx.FT_SetTimeouts.argtypes = [c_void_p, c_ulong, c_ulong]
ftd2xx.FT_SetTimeouts.restype = c_ulong
ftd2xx.FT_SetBitMode.argtypes = [c_void_p, c_ubyte, c_ubyte]
ftd2xx.FT_SetBitMode.restype = c_ulong
ftd2xx.FT_Write.argtypes = [c_void_p, c_void_p, c_ulong, POINTER(c_ulong)]
ftd2xx.FT_Write.restype = c_ulong
ftd2xx.FT_Read.argtypes = [c_void_p, c_void_p, c_ulong, POINTER(c_ulong)]
ftd2xx.FT_Read.restype = c_ulong
ftd2xx.FT_Close.argtypes = [c_void_p]
ftd2xx.FT_Close.restype = c_ulong
ftd2xx.FT_SetLatencyTimer.argtypes = [c_void_p, c_ubyte]
ftd2xx.FT_SetLatencyTimer.restype = c_ulong
ftd2xx.FT_SetUSBParameters.argtypes = [c_void_p, c_ulong, c_ulong]
ftd2xx.FT_SetUSBParameters.restype = c_ulong
###############################################

#RGB565 to RGB888
def ProcessImageRGB (im_to_show, im_array):
    mask = [0X1F, 0X7E0, 0XF800]
    shift = [3, 3, 8]
    shift2 = [2, 9, 13]
    for i in range(3):
        im = (im_array & mask[i])
        if (i == 0):
            im_to_show[:,:,i] = (im << shift[i]) |  (im >> shift2[i])
        else:
            im_to_show[:,:,i] = (im >> shift[i]) |  (im >> shift2[i])
            
      

        
def ShowImage(im_type, IM_X, IM_Y, h):
    global im_array1
    global im_array2
    global SecondFrame
    global DataReady
    STOP_ST = c_ubyte(0x0f) #Stop stream command
    im_cnt = 0
    if (im_type == 2):
        im_to_show = np.zeros((IM_Y,IM_X,3),np.uint8)
        win_name = "FPGA video - " + str(IM_X) + "x" + str(IM_Y) + " RGB"
    elif (im_type == 1):
        im_to_show = np.zeros((IM_Y,IM_X),np.uint8)
        win_name = "FPGA video - " + str(IM_X) + "x" + str(IM_Y) + " grayscale"
   
    while (True):
        if (DataReady.isSet()):
            if (SecondFrame):
                if (im_type == 2):
                    ProcessImageRGB(im_to_show, im_array1)
                elif (im_type == 1):
                    im_to_show = im_array1
            else:
                if (im_type == 2):
                    ProcessImageRGB(im_to_show, im_array2)
                elif (im_type == 1):
                    im_to_show = im_array2
            DataReady.clear()                 
        
        cv2.imshow(win_name, im_to_show)
                    
        key = cv2.waitKey(5)
            
        if key == ord('s'):
            filename = "Img_" + str(im_cnt)+".png"
            im_to_save = np.array(im_to_show).copy()
            cv2.imwrite(filename,im_to_save)
            im_cnt += 1
            print ("Saved image " + filename)
            
        if key == ord('q'):
            c = c_ulong(0)
            ftd2xx.FT_SetBitMode(h, 0xff, 0x40) #sync fifo out
            ftd2xx.FT_Write(h, byref(STOP_ST), 1, byref(c))
            break

def main():
    #FSM commands
    GET_CFG = c_ubyte(0x01) #Get image params
    STRT_ST = c_ubyte(0x11) #Start stream
    STOP_ST = c_ubyte(0x0f) #Stop stream
   
    global im_array1
    global im_array2
    global SecondFrame
    global DataReady
    
    h = c_void_p()
    #Device name
    init_string = create_string_buffer(b"FPGA Video Stream")
    c = ftd2xx.FT_OpenEx(init_string, 2, byref(h))
    if (c != 0):
        print ("Failed to open device")
        return
        
    im_type = 0
    line_cnt = 0
    started = False
    ftd2xx.FT_SetTimeouts(h,1000,1000)
    ftd2xx.FT_SetLatencyTimer(h, 0x10)
    ftd2xx.FT_SetUSBParameters(h, 16384, 16384)
    ftd2xx.FT_SetBitMode(h, 0xff, 0x00) #reset
    ftd2xx.FT_SetBitMode(h, 0xff, 0x40) #sync fifo out
    
    
    recv_data = create_string_buffer(5)
    c = c_ulong(0)
    ftd2xx.FT_Write(h, byref(GET_CFG), 1, byref(c)) #send 
    
    ftd2xx.FT_SetBitMode(h, 0x00, 0x40) #sync fifo in    
    ftd2xx.FT_Read(h, recv_data, 5, byref(c)) #receive  
    
    recv_data = recv_data.raw
    if (recv_data[0] == 0xAA):
        im_type = 1
    elif (recv_data[0] == 0xBB):
        im_type = 2
    print ("Im type", im_type)
    IM_X = recv_data[1] + (recv_data[2] << 8)
    print ("Im X", IM_X)
    IM_Y = recv_data[3] + (recv_data[4] << 8)
    print ("Im Y", IM_Y)
    
    recv_count = c_ulong((im_type*IM_X + 2))
    
    recv_data = create_string_buffer(recv_count.value)
       
    DataReady = threading.Event()
    if (im_type == 1):
        im_array1 = np.zeros((IM_Y,IM_X),np.uint8)
        im_array2 = np.zeros((IM_Y,IM_X),np.uint8)
        
    elif (im_type == 2):
        im_array1 = np.zeros((IM_Y,IM_X),np.uint16)
        im_array2 = np.zeros((IM_Y,IM_X),np.uint16)
    
    SecondFrame = False
    #Start show image thread
    ShowImageThread = threading.Thread(target=ShowImage, args = (im_type, IM_X, IM_Y, h))
    ShowImageThread.daemon = True
    ShowImageThread.start()
    
    while (True):
        if (not started):
            ftd2xx.FT_SetBitMode(h, 0xff, 0x40) #sync fifo out
            print("Starting stream") 
            ftd2xx.FT_Write(h, byref(STRT_ST), 1, byref(c)) #send
            ftd2xx.FT_SetBitMode(h, 0x00, 0x40) #sync fifo in  
            started = True
        
        
        ftd2xx.FT_Read(h, recv_data, recv_count, byref(c)) #receive
        line_cnt = recv_data.raw[0] + (recv_data.raw[1] << 8)
        if (line_cnt > IM_Y - 1):
            print("Error", line_cnt)
            ftd2xx.FT_SetBitMode(h, 0xff, 0x40) #sync fifo out
            ftd2xx.FT_Write(h, byref(STOP_ST), 1, byref(c)) #send
            started = False
            line_cnt = 0
        
        if (SecondFrame):
            if (im_type == 2):
                im_array2[line_cnt] = np.frombuffer(recv_data[2:], dtype='>u2')
            elif (im_type == 1):
                im_array2[line_cnt] = np.frombuffer(recv_data[2:], dtype=np.uint8)
        else:
            if (im_type == 2):
                im_array1[line_cnt] = np.frombuffer(recv_data[2:], dtype='>u2')
            elif (im_type == 1):
                im_array1[line_cnt] = np.frombuffer(recv_data[2:], dtype=np.uint8)
        
        if (line_cnt == IM_Y - 1):
            SecondFrame = not SecondFrame
            DataReady.set()
            
        if (not ShowImageThread.is_alive()):
            break            
        
            
        
    ftd2xx.FT_Close(h)    
    
if __name__ == '__main__':
    main()
    
    