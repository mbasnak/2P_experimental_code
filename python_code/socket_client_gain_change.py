#!/usr/bin/env python3

#import relevant modules
import socket
import select
import time
from Phidget22.Phidget import *
from Phidget22.Devices.VoltageOutput import *
import numpy as np
from h5_logger import H5Logger
import random
import math


class SocketClientGainChange(object):

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
        self.time_start = time.time()

        self.phidget_vision = 525577  # written on the back of the Phidget

        # Set up Phidget channels
        self.aout_channel_yaw = 0
        self.aout_channel_x = 1
        self.aout_channel_yaw_gain = 2
        self.aout_channel_y = 3
        self.aout_max_volt = 10.0
        self.aout_min_volt = 0.0

        # Setup analog output YAW
        self.aout_yaw = VoltageOutput()
        self.aout_yaw.setDeviceSerialNumber(self.phidget_vision)
        self.aout_yaw.setChannel(self.aout_channel_yaw)
        self.aout_yaw.openWaitForAttachment(5000)
        self.aout_yaw.setVoltage(0.0)

        # Setup analog output X
        self.aout_x = VoltageOutput()
        self.aout_x.setDeviceSerialNumber(self.phidget_vision)
        self.aout_x.setChannel(self.aout_channel_x)
        self.aout_x.openWaitForAttachment(5000)
        self.aout_x.setVoltage(0.0)

        # Setup analog output YAW gain
        self.aout_yaw_gain = VoltageOutput()
        self.aout_yaw_gain.setDeviceSerialNumber(self.phidget_vision)
        self.aout_yaw_gain.setChannel(self.aout_channel_yaw_gain)
        self.aout_yaw_gain.openWaitForAttachment(5000)
        self.aout_yaw_gain.setVoltage(0.0)

        # Setup analog output Y
        self.aout_y = VoltageOutput()
        self.aout_y.setDeviceSerialNumber(self.phidget_vision)
        self.aout_y.setChannel(self.aout_channel_y)
        self.aout_y.openWaitForAttachment(5000)
        self.aout_y.setVoltage(0.0)

        self.print = True;

        # Set up socket info
        self.HOST = '127.0.0.1'  # The (receiving) host IP address (sock_host)
        self.PORT = 65432         # The (receiving) host port (sock_port)

        self.done = False
		
        self.gain_yaw = 1
        self.gain_change = True
        self.heading_with_gain = 0

        #set up logger to save hd5f file
        self.logger = H5Logger(
                filename = self.param['logfile_name'],
                auto_incr = self.param['logfile_auto_incr'],
                auto_incr_format = self.param['logfile_auto_incr_format'],
                param_attr = self.param
        )


    def run(self):

        # UDP
        # Open the connection (ctrl-c / ctrl-break to quit)
        with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as sock:
            sock.bind((self.HOST, self.PORT))
            sock.setblocking(0)
    
            # Keep receiving data until FicTrac closes
            data = ""
            timeout_in_seconds = 1

            while not self.done:
                # Check to see whether there is data waiting
                ready = select.select([sock], [], [], timeout_in_seconds)
    
                # Only try to receive data if there is data waiting
                if ready[0]:
                    # Receive one data frame
                    new_data = sock.recv(1024)
            
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
                    self.frame = int(toks[1])
                    self.posx = float(toks[15])
                    self.posy = float(toks[16])
                    self.heading = float(toks[17])
                    self.deltaheading = float(toks[8])
                    self.intx = float(toks[20])
                    self.inty = float(toks[21])
                    self.timestamp = float(toks[22])

                    #Set Phidget voltages using FicTrac data
                    
                    # Set analog output voltage yaw
                    output_voltage_yaw = (self.heading)*(self.aout_max_volt-self.aout_min_volt)/(2 * np.pi)
                    self.aout_yaw.setVoltage(output_voltage_yaw) 


                    # Set analog output voltage X
                    wrapped_intx = (self.intx % (2 * np.pi))
                    output_voltage_x = wrapped_intx * (self.aout_max_volt - self.aout_min_volt) / (2 * np.pi)
                    self.aout_x.setVoltage(output_voltage_x)


                    # Set analog output voltage YAW_gain
                    #set yaw gain depending on how much time has elapsed
                    if ((self.time_elapsed > 200) and (self.gain_change == True)):
                            self.gain_yaw = -1
                            self.gain_change = False
                    elif self.time_elapsed > 1000:
                            self.gain_yaw = 1


                    self.heading_with_gain = (self.heading_with_gain + self.deltaheading*self.gain_yaw) % (2*np.pi)
                    output_voltage_yaw_gain = (self.heading_with_gain)*(self.aout_max_volt-self.aout_min_volt)/(2 * np.pi)
                    self.aout_yaw_gain.setVoltage(10-output_voltage_yaw_gain) 


                    # Set analog output voltage Y
                    wrapped_inty = self.inty % (2 * np.pi)
                    output_voltage_y = wrapped_inty * (self.aout_max_volt - self.aout_min_volt) / (
                                2 * np.pi)
                    self.aout_y.setVoltage(output_voltage_y)

                    # Save data in log file
                    self.write_logfile() 

                    # Display status message
                    if self.print:
                        print('frame:  {0}'.format(self.frame))
                        print('time elapsed:   {0:1.3f}'.format(self.time_elapsed))
                        print('gain yaw: {0}'.format(self.gain_yaw))
                        print('gain change: {0}'.format(self.gain_change))
                        print('yaw:   {0:1.3f}'.format(self.heading*360/(2*np.pi)))                   
                        print('volt:   {0:1.3f}'.format(output_voltage_yaw_gain))
                        print('int x:   {0:1.3f}'.format(wrapped_intx))
                        print('volt:   {0:1.3f}'.format(output_voltage_x))
                        print('int y:   {0:1.3f}'.format(wrapped_inty))
                        print('volt:   {0:1.3f}'.format(output_voltage_y))
                        print()

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
                'heading': self.heading,
                'heading_with_gain': self.heading_with_gain,
                'deltaheading': self.deltaheading,
                'gain_yaw': self.gain_yaw
            }
            self.logger.add(log_data)