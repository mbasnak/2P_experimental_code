#!/usr/bin/env python3

#import relevant modules
import socket  # for delegating the task of listening to the socket to the OS
import select
import time
import datetime
from Phidget22.Phidget import *
from Phidget22.Devices.VoltageOutput import *
import serial
import numpy as np
from h5_logger import H5Logger


class SocketClient(object):

    DefaultParam = {
        'experiment': 1,
        'experiment_time': 30,
        'logfile_name': 'Z:/Wilson Lab/Mel/FlyOnTheBall/data',
        'logfile_auto_incr': True,
        'logfile_auto_incr_format': '{0:06d}',
        'logfile_dt': 0.01,
    }

    def __init__(self, param=DefaultParam):

        self.param = param
        self.experiment = self.param['experiment']
        self.experiment_time = self.param['experiment_time']
        self.time_start = time.time()  # get the current time and use it as a ref for elapsed time


        # Set up Phidget channels
        self.aout_channel_x = 1
        self.aout_channel_yaw = 2
        self.aout_channel_y = 3
        self.aout_max_volt = 10.0
        self.aout_min_volt = 0.0

        # Setup analog output X
        self.aout_x = VoltageOutput()
        self.aout_x.setChannel(self.aout_channel_x)
        self.aout_x.openWaitForAttachment(5000)
        self.aout_x.setVoltage(0.0)

        # Setup analog output YAW
        self.aout_yaw = VoltageOutput()
        self.aout_yaw.setChannel(self.aout_channel_yaw)
        self.aout_yaw.openWaitForAttachment(5000)
        self.aout_yaw.setVoltage(0.0)

        # Setup analog output Y
        self.aout_y = VoltageOutput()
        self.aout_y.setChannel(self.aout_channel_y)
        self.aout_y.openWaitForAttachment(5000)
        self.aout_y.setVoltage(0.0)

        self.print = True;

        # Set up socket info for connecting with the FicTrac
        self.HOST = '127.0.0.1'  # The (receiving) host IP address (sock_host)
        self.PORT = 65432         # The (receiving) host port (sock_port)

        # Set up Arduino connection
        self.COM = 'COM6'  # serial port
        self.baudrate = 115200  # 9600
        self.serialTimeout = 0.001 # blocking timeout for readline()

        # log for Arduino
        self.file_path = "C:\\Users\\Tots\\Documents\\Python\\CLwind\\log\\"
        now = datetime.datetime.now()
        date_str = now.strftime("%Y%m%d_%H%M%S")
        self.file_name_arduino = self.file_path + date_str + "_arduino.csv"

        # log for FicTrac
        self.file_name_fictrac = self.file_path + date_str + "_fictrac.csv"

        # flag for indicating when the trial is done
        self.done = False

        #set up logger to save hd5f file
        self.logger = H5Logger(
                filename = self.param['logfile_name'],
                auto_incr = self.param['logfile_auto_incr'],
                auto_incr_format = self.param['logfile_auto_incr_format'],
                param_attr = self.param
        )


    def run(self, gain_x = 1):

        # connect to socket via UDP, not TCP!
        # connect to Arduino via serial
        # open file for logging Arduino outputs
        with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as sock,\
         serial.Serial(self.COM, self.baudrate, timeout=self.serialTimeout) as ser, \
         open(self.file_name_arduino, mode='w') as f_arduino, \
         open(self.file_name_fictrac, mode='w') as f_fictrac:
            sock.bind((self.HOST, self.PORT))  # takes one argument, give it as a tuple
            sock.setblocking(False)  # make it non-blocking
    
            # Keep receiving data until FicTrac closes
            data = ""
            timeout_in_seconds = 1

            while not self.done:  # main loop

                # listening to Arduino
                msg = ser.readline()  # read from serial until there's a \n
                time_now = time.time() 
                if len(msg) > 0:
                    try:
                        arduino_line = msg.decode('utf-8')[:-2]  # decode and remove \r and \n
                        motor_info = arduino_line.split(", ")
                        log_arduino = str("{:.7f}".format(time_now)) + "," + motor_info[0] + "\n"  # remove empty spaces
                        #log_arduino = str("{:.7f}".format(time_now)) + "," + motor_info[0].strip() + "," + motor_info[1].strip() + "," + motor_info[2].strip() + "\n"  # if the Arduino is outputting 3 vals
                        f_arduino.writelines(log_arduino)
                        #print("worked:", log_arduino)
                    except:
                        print("failed:", str("{:.7f}".format(time_now)), msg)
                
                # ask the OS whether the socket is readable
                # give 3 lists of sockets for reading, writing, and checking for errors; we only care about the first one
                # https://docs.python.org/3/howto/sockets.html#socket-programming-howto
                ready = select.select([sock], [], [], timeout_in_seconds)  # returns the subset of sockets that are actually readable
    
                # Only try to receive data if there is data waiting
                if ready[0]:
                    # Receive one data frame
                    new_data = sock.recv(1024)  # buffer size, should be a relatively small power of 2
            
                    # Uh oh?
                    if not new_data:
                        break
            
                    # Decode received data
                    data += new_data.decode('UTF-8')
                    #get time
                    time_now = time.time() 
                    self.time_elapsed = time_now - self.time_start  # (s)
            
                    # Find the first frame of data
                    endline = data.find("\n")
                    line = data[:endline]       # copy first frame
                    data = data[endline+1:]     # delete first frame
            
                    # Tokenise
                    toks = line.split(", ")
            
                    # Check that we have sensible tokens
                    if ((len(toks) < 24) | (toks[0] != "FT")):
                        print('Bad read')
                        continue
            
                    # Extract FicTrac variables
                    # (see https://github.com/rjdmoore/fictrac/blob/master/doc/data_header.txt for descriptions)
                    self.frame = int(toks[1])
                    self.posx = float(toks[15])
                    self.posy = float(toks[16])
                    self.heading = float(toks[17])  # integrated heading direction of the animal in lab coords (rads)
                    self.intx = float(toks[20])
                    self.inty = float(toks[21])
                    self.timestamp = float(toks[22])

                    # send the heading signal to Arduino
                    animal_heading_360 = int(self.heading * (360 / (2 * np.pi)))  # convert from rad to deg
                    arduino_str = "H " + str(animal_heading_360) + "\n"  # "H is a command used in the Arduino code to indicate heading
                    arduino_byte = arduino_str.encode()  # convert unicode string to byte string
                    ser.write(arduino_byte)  # send to serial port  

                    # write to FicTrac log file
                    time_now = time.time()
                    log_fictrac = str("{:.7f}".format(time_now)) + "," + str(animal_heading_360) + "\n"
                    f_fictrac.writelines(log_fictrac)

                    #Set Phidget voltages using FicTrac data
                    # Set analog output voltage X
                    wrapped_intx = (self.intx % (2 * np.pi))
                    output_voltage_x = wrapped_intx * (self.aout_max_volt - self.aout_min_volt) / (2 * np.pi)
                    self.aout_x.setVoltage(output_voltage_x)

                    # Set analog output voltage YAW
                    output_voltage_yaw = (self.heading)*(self.aout_max_volt-self.aout_min_volt)/(2 * np.pi)
                    self.aout_yaw.setVoltage(output_voltage_yaw) 

                    # Set analog output voltage Y
                    wrapped_inty = self.inty % (2 * np.pi)
                    output_voltage_y = wrapped_inty * (self.aout_max_volt - self.aout_min_volt) / (
                                2 * np.pi)
                    self.aout_y.setVoltage(output_voltage_y)

                    # Save data in log file
                    self.write_logfile() 

                    # Display status message
                    if self.print:
                        #print('frame:  {0}'.format(self.frame))
                        print('time elapsed:   {0:1.3f}'.format(self.time_elapsed))
                        #print('yaw:   {0:1.3f}'.format(animal_heading_360))                  
                        #print('volt:   {0:1.3f}'.format(output_voltage_yaw))
                        #print('int x:   {0:1.3f}'.format(wrapped_intx))
                        #print('volt:   {0:1.3f}'.format(output_voltage_x))
                        #print('int y:   {0:1.3f}'.format(wrapped_inty))
                        #print('volt:   {0:1.3f}'.format(output_voltage_y))
                        #print()

                    if self.time_elapsed > self.experiment_time:
                        self.done = True
                        break

            # END OF EXPERIMENT
            print('Trial finished - quitting!')


    #define function to log data to hdf5 file
    def write_logfile(self):
            log_data = {
                'time': self.time_elapsed,
                'frame': self.frame,
                'posx': self.posx,
                'posy': self.posy,
                'intx': self.intx,
                'inty': self.inty,
                'heading': self.heading
            }
            self.logger.add(log_data)