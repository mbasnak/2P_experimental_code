#!/usr/bin/env python3

"""
commented by Tatsuo Okubo
2021/01/07

The first line makes this code an executable script
It uses the operating system env comand to search Python in the PATH env variable.
"""


# currently using PhidgetAnalog 4-Output (10002_0B)
# https://www.phidgets.com/?view=api&product_id=1002_0&lang=Python

#import relevant modules
import socket  # for establishing connection with FicTrac 
import select
import time
from Phidget22.Phidget import *
from Phidget22.Devices.VoltageOutput import *
import numpy as np
from h5_logger import H5Logger


class SocketClient(object):

	# class variable shared across all instances
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
        self.aout_x = VoltageOutput()  # VoltageOutput class controls the variable DC voltage output
        self.aout_x.setChannel(self.aout_channel_x)
        self.aout_x.openWaitForAttachment(5000)  # waits for a defined amount of time [ms]
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

        self.print = True;  # whether to print status to the console

        # Set up socket info
        self.HOST = '127.0.0.1'  # The (receiving) host IP address (sock_host)
        self.PORT = 65432         # The (receiving) host port (sock_port)

        self.done = False

        #set up logger to save hd5f file
        self.logger = H5Logger(
                filename = self.param['logfile_name'],
                auto_incr = self.param['logfile_auto_incr'],
                auto_incr_format = self.param['logfile_auto_incr_format'],
                param_attr = self.param
        )


    def run(self, gain_x = 1):

        # UDP
        # Open the connection (ctrl-c / ctrl-break to quit)
        with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as sock:  # UDP and not TCP
            sock.bind((self.HOST, self.PORT))
            sock.setblocking(0)  # non-blocking mode!
    
            # Keep receiving data until FicTrac closes
            data = ""
            timeout_in_seconds = 1

            while not self.done:
                # Check to see whether there is data waiting
                ready = select.select([sock], [], [], timeout_in_seconds)
    
                # Only try to receive data if there is data waiting
                if ready[0]:
                    # Receive one data frame
                    new_data = sock.recv(1024)  # 1024: maximum amount of data received at once
            
                    # Uh oh?
                    if not new_data:
                        break
            
                    # Decode received data
                    data += new_data.decode('UTF-8')
                    
                    #get time
                    time_now = time.time() 
                    self.time_elapsed = time_now - self.time_start
            
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
                    self.frame = int(toks[1])  # frame counter
                    self.posx = float(toks[15])  # integrated x position (rad)
                    self.posy = float(toks[16])  # integrated y position (rad)
                    self.heading = float(toks[17])  # integrated animal heading (rad)
                    self.intx = float(toks[20])  # integrated forward position neglecting heading (rad)
                    self.inty = float(toks[21])  # integrated side positino neglecting heading (rad)
                    self.timestamp = float(toks[22])  # position in video file (ms0)

                    # Set Phidget voltages using FicTrac data
                    # Set analog output voltage X
                    wrapped_intx = (self.intx % (2 * np.pi))  # take the remainder
                    output_voltage_x = wrapped_intx * (self.aout_max_volt - self.aout_min_volt) / (2 * np.pi)
                    self.aout_x.setVoltage(output_voltage_x)


                    # Set analog output voltage YAW
                    output_voltage_yaw = (self.heading)*(self.aout_max_volt-self.aout_min_volt) / (2 * np.pi)
                    self.aout_yaw.setVoltage(output_voltage_yaw) 


                    # Set analog output voltage Y
                    wrapped_inty = self.inty % (2 * np.pi)
                    output_voltage_y = wrapped_inty * (self.aout_max_volt - self.aout_min_volt) / (2 * np.pi)
                    self.aout_y.setVoltage(output_voltage_y)

                    # Save data in log file
                    self.write_logfile() 

                    # Display status message
                    if self.print:
                        print('frame:  {0}'.format(self.frame))
                        print('time elapsed:   {0:1.3f}'.format(self.time_elapsed))
                        print('yaw:   {0:1.3f}'.format(self.heading*360/(2*np.pi)))                   
                        print('volt:   {0:1.3f}'.format(output_voltage_yaw))
                        print('int x:   {0:1.3f}'.format(wrapped_intx))
                        print('volt:   {0:1.3f}'.format(output_voltage_x))
                        print('int y:   {0:1.3f}'.format(wrapped_inty))
                        print('volt:   {0:1.3f}'.format(output_voltage_y))
                        print()

                    # end experiment after the elapsed time has exceeded the specified time
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