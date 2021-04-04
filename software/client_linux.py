#!/usr/bin/env python
# coding: utf-8

from ctypes import *
import numpy as np
import cv2
import threading
import usb1
#
#Press "s" to save the frame. Press "q" to quit. 
#

#RGB565 to RGB888
def ProcessImageRGB(im_to_show, im_array):
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
                    
        key = cv2.waitKey(10)
            
        if key == ord('s'):
            filename = "Img_" + str(im_cnt)+".png"
            im_to_save = np.array(im_to_show).copy()
            cv2.imwrite(filename,im_to_save)
            im_cnt += 1
            print ("Saved image " + filename)
            
        if key == ord('q'):
            h._controlTransfer(0x40, 0x0B,0x40FF,0x01,None,0,1000)#sync fifo out
            h._bulkTransfer(0x02, byref(STOP_ST),1, 1000)#send 
            break

def main():
    #FSM commands
    GET_CFG = c_ubyte(0x01) #Get image params
    STRT_ST = c_ubyte(0x11) #Start stream
    STOP_ST = c_ubyte(0x0f) #Stop stream
    #Number of usb transfers
    USB_NUM_TRANSFERS = 16
    #Device name
    init_string = "FPGA Video Stream"
    im_type = 0
    started = False
    global im_array1
    global im_array2
    global SecondFrame
    global DataReady
    global ShowImageThread
    global LineError
    
    r_buf = create_string_buffer(1024)
    
    handle = None
    context = usb1.USBContext()
    #FT232H
    idVendor = 0x0403
    idProduct = 0x6014
    
    for device in context.getDeviceIterator(skip_on_error=True):
        if (device.getVendorID() == idVendor and device.getProductID() == idProduct):
            handle = device.open()
            if (handle.getProduct() == init_string): #Check device name
                break
            else:
                handle.close()
                handle = None
   
    
    if (handle is None):
        print ("Failed to open device")
        return
    
    handle.claimInterface(0)
    handle._controlTransfer(0x40, 0x09,0x0010,0x01,None,0,1000)#set latency timer
    handle._controlTransfer(0x40, 0,2,0x01,None,0,1000)#tcireset
    handle._controlTransfer(0x40, 0,1,0x01,None,0,1000)#tcoreset
    handle._controlTransfer(0x40, 0x0B,0x00FF,0x01,None,0,1000)#reset MPSSE
    
    handle._controlTransfer(0x40, 0x0B,0x40FF,0x01,None,0,1000)#sync fifo out
    handle._bulkTransfer(0x02, byref(GET_CFG),1, 1000)#send 
    handle._controlTransfer(0x40, 0x0B,0x4000,0x01,None,0,1000)#sync fifo in
    
    
    r_cnt = handle._bulkTransfer(0x81, byref(r_buf),7, 1000)#receive     
    recv_data = r_buf[2:r_cnt]  #skip status bytes
      
    if (recv_data[0] == 0xAA):
        im_type = 1
    elif (recv_data[0] == 0xBB):
        im_type = 2
    print ("Im type", im_type)
    IM_X = recv_data[1] + (recv_data[2] << 8)
    print ("Im X", IM_X)
    IM_Y = recv_data[3] + (recv_data[4] << 8)
    print ("Im Y", IM_Y)
       
    DataReady = threading.Event()
    if (im_type == 1):
        im_array1 = np.zeros((IM_Y,IM_X),np.uint8)
        im_array2 = np.zeros((IM_Y,IM_X),np.uint8)
        
    elif (im_type == 2):
        im_array1 = np.zeros((IM_Y,IM_X),np.uint16)
        im_array2 = np.zeros((IM_Y,IM_X),np.uint16)
    
    SecondFrame = False
    #Start show image thread
    ShowImageThread = threading.Thread(target=ShowImage, args = (im_type, IM_X, IM_Y, handle))
    ShowImageThread.daemon = True
    ShowImageThread.start()
    
    LineError = False
    transfer_list = []
    #Init static variables
    ProcessData.newline = True
    ProcessData.buf_ptr = 0
    ProcessData.line_cnt = 0
    ProcessData.IM_X = IM_X
    ProcessData.IM_Y = IM_Y
    ProcessData.im_type = im_type
    ProcessData.im_ptr = 0
    ProcessData.rem_ptr = 0
    while (True):
        if (not started):
            handle._controlTransfer(0x40, 0x0B,0x40FF,0x01,None,0,1000)#sync fifo out
            handle._bulkTransfer(0x02, byref(STRT_ST),1, 1000)#send 
            handle._controlTransfer(0x40, 0x0B,0x4000,0x01,None,0,1000)#sync fifo in
            print("Starting stream")
            started = True
            LineError = False
        else:
            for _ in range(USB_NUM_TRANSFERS): #fill the transfer queue 
                transfer = handle.getTransfer()
                transfer.setBulk(
                    0x81,
                    16384,
                    callback=ProcessData, #Buffer processing callback function
                    timeout = 1000)
                transfer.submit()
                transfer_list.append(transfer)
        
        
            while  any(x.isSubmitted() for x in transfer_list) and not LineError:
                context.handleEvents()
            break    
                    
    handle._controlTransfer(0x40, 0x0B,0x40FF,0x01,None,0,1000)#sync fifo out
    handle._bulkTransfer(0x02, byref(STOP_ST),1, 1000)#send 
    handle.close()

#Buffer processing callback function    
def ProcessData(transfer):
    
    global SecondFrame
    global LineError
    buflen = transfer.getActualLength()
    data = transfer.getBuffer()[:buflen]
    buf_step = 512 #Bulk packet size
    skip = 2 #skip status bytes
    if (buflen == 16384):
        for pack_ptr in range(0, buflen, buf_step):
            if (SecondFrame):
                im_array = im_array2
            else:
                im_array = im_array1
            if (ProcessData.newline):
                line_cnt_old = ProcessData.line_cnt
                ProcessData.line_cnt = data[pack_ptr + skip + ProcessData.im_ptr] + (data[pack_ptr + skip + ProcessData.im_ptr + 1] << 8)
                if (ProcessData.line_cnt > ProcessData.IM_Y - 1):
                    ProcessData.line_cnt = line_cnt_old
                    print("Error in line counter", ProcessData.line_cnt)
                    LineError = True
                    return
                ProcessData.im_ptr += 2 #skip line counter bytes
                ProcessData.newline = False
            im_buf_step = buf_step - skip - ProcessData.im_ptr - ProcessData.rem_ptr
            im_array[ProcessData.line_cnt, ProcessData.buf_ptr//ProcessData.im_type:(ProcessData.buf_ptr + im_buf_step)//ProcessData.im_type] = np.frombuffer(data[pack_ptr + skip + ProcessData.im_ptr:pack_ptr + buf_step - ProcessData.rem_ptr],  dtype='>u2' if ProcessData.im_type == 2 else np.uint8 )
            ProcessData.buf_ptr += im_buf_step
            ProcessData.rem = ProcessData.IM_X - ProcessData.buf_ptr//ProcessData.im_type
            ProcessData.im_ptr = 0
        
            if (ProcessData.rem == 0):
                if (ProcessData.line_cnt == ProcessData.IM_Y - 1):
                    SecondFrame = not SecondFrame
                    DataReady.set()
                    
                ProcessData.newline = True
                ProcessData.buf_ptr = 0         
                if (ProcessData.rem_ptr != 0):
                    
                    line_cnt_old = ProcessData.line_cnt
                    ProcessData.line_cnt = data[pack_ptr + buf_step - ProcessData.rem_ptr] + (data[pack_ptr + buf_step - ProcessData.rem_ptr + 1] << 8)
                    ProcessData.newline = False
                    if (ProcessData.line_cnt > ProcessData.IM_Y - 1):
                        ProcessData.line_cnt = line_cnt_old
                        print("Error in line counter", ProcessData.line_cnt)
                        LineError = True
                        return
                    ProcessData.im_ptr += 2             
                    im_buf_step = ProcessData.rem_ptr - ProcessData.im_ptr 
                    im_array[ProcessData.line_cnt, ProcessData.buf_ptr//ProcessData.im_type:(ProcessData.buf_ptr + im_buf_step)//ProcessData.im_type] = np.frombuffer(data[pack_ptr + buf_step + ProcessData.im_ptr - ProcessData.rem_ptr:pack_ptr + buf_step ],  dtype='>u2' if ProcessData.im_type == 2 else np.uint8)
                    ProcessData.buf_ptr += im_buf_step
                    ProcessData.rem = ProcessData.IM_X - ProcessData.buf_ptr//ProcessData.im_type
                    ProcessData.rem_ptr = 0
                    ProcessData.im_ptr = 0
                    
            elif (ProcessData.rem < (buf_step-skip)//ProcessData.im_type):
                ProcessData.rem_ptr = buf_step - (ProcessData.rem+(3-ProcessData.im_type))*ProcessData.im_type 
            
    
    if (ShowImageThread.is_alive() and not LineError):
        transfer.submit()   


if __name__ == '__main__':
    main()
    
    