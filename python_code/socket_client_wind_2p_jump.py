#!/usr/bin/env python3
from h5_logger import H5Logger
from Phidget22.Phidget import *
from Phidget22.Devices.VoltageOutput import *
import math
import numpy as np
import random
import select
import serial
import socket  # for delegating the task of listening to the socket to the OS
import time

class SocketClient(object):

    DefaultParam = {
        'experiment': 1,
        'experiment_time': 30,
        'logfile_name': 'Z:/Wilson Lab/Mel/FlyOnTheBall/data',
        'logfile_auto_incr': True,
        'logfile_auto_incr_format': '{0:06d}',
        'logfile_dt': 0.01,
        'offset': 0
    }

    def __init__(self, param=DefaultParam):

        self.param = param
        self.experiment = self.param['experiment']
        self.experiment_time = self.param['experiment_time']
        self.time_start = time.time()  # get the current time and use it as a ref for elapsed time

        #get gain for the panels and wind
        self.gain_panels = self.param['gain_panels']
        self.gain_wind = self.param['gain_wind']

        # Set up Phidget serial numbers for using two devices
        self.phidget_vision = 525577  # written on the back of the Phidget
        self.phidget_wind = 589946  # for sending the position of the motor to NI-DAQ

        # Set up Phidget channels in device 1 for vision (0-index)
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

        # Set up Phidget channels in device 2 for wind (0-index)
        self.aout_channel_motor = 0
        self.aout_channel_wind_valve = 2

        # Setup analog output motor
        self.aout_motor = VoltageOutput()
        self.aout_motor.setDeviceSerialNumber(self.phidget_wind)
        self.aout_motor.setChannel(self.aout_channel_motor)
        self.aout_motor.openWaitForAttachment(5000)
        self.aout_motor.setVoltage(0.0)

        # Setup analog output wind valve
        self.aout_wind_valve = VoltageOutput()
        self.aout_wind_valve.setDeviceSerialNumber(self.phidget_wind)
        self.aout_wind_valve.setChannel(self.aout_channel_wind_valve)
        self.aout_wind_valve.openWaitForAttachment(5000)
        self.aout_wind_valve.setVoltage(0.0)

        self.print = True

        # Set up socket info for connecting with the FicTrac
        self.HOST = '127.0.0.1'  # The (receiving) host IP address (sock_host)
        self.PORT = 65432         # The (receiving) host port (sock_port)

        # Set up Arduino connection
        self.COM = 'COM4'  # serial port
        self.baudrate = 115200  # 9600
        self.serialTimeout = 0.001 # blocking timeout for readline()

        # flag for indicating when the trial is done
        self.done = False

        #initialize heading with respect to panels to be starting position
        self.motor_command = 0
        self.bar_position = np.deg2rad(360 - self.param['offset'])

        self.jump = True
        self.time_between_jumps = 90  # [s]
        self.jump_mag = 90  # [deg] jump magnitude
        self.jump_size = 0  # default value is zero

        #set up logger to save hd5f file
        self.logger_fictrac = H5Logger(
            filename = self.param['logfile_name'],
            auto_incr = self.param['logfile_auto_incr'],
            auto_incr_format = self.param['logfile_auto_incr_format'],
            param_attr = self.param
        )

        #set up logger to save hd5f file
        self.logger_arduino = H5Logger(
            filename = (self.param['logfile_name']).replace('.hdf5', '_arduino.hdf5'),
            auto_incr = self.param['logfile_auto_incr'],
            auto_incr_format = self.param['logfile_auto_incr_format'],
            param_attr = self.param
        )

        #specify a variable for the first message being read
        self.first_time_in_loop = True



    def run(self):
        # connect to socket via UDP, not TCP!
        # connect to Arduino via serial
        with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as sock,\
         serial.Serial(self.COM, self.baudrate, timeout=self.serialTimeout) as ser:
            sock.bind((self.HOST, self.PORT))  # takes one argument, give it as a tuple
            sock.setblocking(False)  # make it non-blocking
    
            # Keep receiving data from socket until FicTrac closes
            data = ""
            timeout_in_seconds = 1

            while not self.done:  # main loop
                self.aout_wind_valve.setVoltage(5.0)  # keep the wind on for the duration of the trial

                motor_pos = np.nan
                self.motor_pos_rad = np.nan  # default value before receiving the data
                # listening to Arduino
                msg = ser.readline()  # read from serial until there's a \n
                self.time_arduino = time.time() - self.time_start  # (s) 
                if msg:  # received a non-empty message
                    try:
                        arduino_line = msg.decode('utf-8')[:-2]  # decode and remove \r and \n
                        #motor_info = arduino_line.split(", ")
                        #log_arduino = str("{:.7f}".format(time_now)) + "," + motor_info[0] + "\n"  # first element is the current motor position (0-360 deg)
                        #f_arduino.writelines(log_arduino)
                        motor_pos = int(arduino_line)  # current motor position (0-360 deg)
                        self.motor_pos_rad = np.deg2rad(motor_pos) 
                        
                         # Set analog output voltage of Phidget so that it could be recorded using NI-DAQ
                        output_voltage_motor = self.motor_pos_rad * (self.aout_max_volt-self.aout_min_volt) / (2 * np.pi)
                        self.aout_motor.setVoltage(output_voltage_motor)

                        # write to HDF5 file    
                        self.write_logfile_arduino()
    
                    except:
                        print("message from Arduino is not a number:", msg)
                
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
                    self.time_elapsed = time.time() - self.time_start  # (s)
            
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
                    self.intx = float(toks[20])  # integrated x position (rad) of the sphere in lab coord neglecting heading
                    self.inty = float(toks[21])  # integrated y position (rad) of the sphere in lab coord neglecting heading
                    self.timestamp = float(toks[22])  # frame capture time (ms) since epoch

                    # calculate delta heading by comparing it to the previous value
                    if self.first_time_in_loop:
                        self.prev_heading = float(toks[17])
                        self.first_time_in_loop = False
                    else:
                        self.prev_heading = self.heading
                    self.heading = float(toks[17])  # integrated heading direction of the animal in lab coords (rad)
                    self.deltaheading = self.heading - self.prev_heading

                    # Set analog output voltage YAW_gain
                    #set value depending on how much time has elapsed
                    if ((self.time_elapsed > 1) and ((math.floor(self.time_elapsed)%self.time_between_jumps)==0) and (self.jump == True)):
                        #choose randomly between -120 and 120 jumps
                        self.jump_size = random.choice([np.deg2rad(-self.jump_mag), np.deg2rad(self.jump_mag)])
                        self.jump = False
                    else:
                    	self.jump_size = 0

                   #reset self.jump 1 sec before the gain change
                    if (((math.floor(self.time_elapsed+1)%self.time_between_jumps)==0) and (self.jump == False)):
                        self.jump = True

                    # send the heading signal to Arduino
                    self.motor_command = (self.motor_command + self.deltaheading + self.jump_size) % (2 * np.pi)
                    #animal_heading_360 = int(self.heading * (360 / (2 * np.pi)))  # convert from rad to deg
                    arduino_str = "H " + str(360 - np.rad2deg(self.motor_command)) + "\n"  # "H is a command used in the Arduino code to indicate heading
                    arduino_byte = arduino_str.encode()  # convert unicode string to byte string
                    ser.write(arduino_byte)  # send to serial port  


                    ## Set Phidget voltages using FicTrac data
                    # Set analog output voltage X
                    wrapped_intx = (self.intx % (2 * np.pi))                   
                    output_voltage_x = wrapped_intx * (self.aout_max_volt - self.aout_min_volt) / (2 * np.pi)
                    self.aout_x.setVoltage(output_voltage_x)

                    # Set analog output voltage YAW
                    self.bar_position = (self.bar_position + self.deltaheading*self.gain_panels) % (2 * np.pi)  # wrap around
                    self.output_voltage_yaw = (self.bar_position) * (self.aout_max_volt-self.aout_min_volt) / (2 * np.pi)
                    self.aout_yaw.setVoltage(self.output_voltage_yaw)
                    self.aout_yaw_gain.setVoltage(self.output_voltage_yaw)  

                    # Set analog output voltage Y
                    wrapped_inty = self.inty % (2 * np.pi)
                    output_voltage_y = wrapped_inty * (self.aout_max_volt - self.aout_min_volt) / (2 * np.pi)
                    self.aout_y.setVoltage(output_voltage_y)

                    # Save fictrac data in HDF5 file
                    self.write_logfile_fictrac() 

                    # Display status message
                    if self.print:
                        print(f'time elapsed: {self.time_elapsed: 1.3f}', end='')
                        print(f'  motor command: {np.rad2deg(self.motor_command):3.0f}', end='')
                        print(f'  motor pos: {motor_pos:3.0f}', end='')
                        print(f'  bar pos: {np.rad2deg(self.bar_position):3.0f}')
                        #print(f'  delta heading: {np.rad2deg(self.deltaheading):3.0f}')

                    if self.time_elapsed > self.experiment_time:
                        self.done = True
                        break

            # go back to 0 deg at the end of the trial            
            arduino_str = "H " + str(0) + "\n"  # "H is a command used in the Arduino code to indicate heading
            arduino_byte = arduino_str.encode()  # convert unicode string to byte string       
            ser.write(arduino_byte)  # send to serial port

            self.aout_wind_valve.setVoltage(0.0)  # turn the wind off at the end of the trial

            print('Trial finished - quitting!')

    #define function to log data to hdf5 file
    def write_logfile_fictrac(self):
        log_data = {
            'time': self.time_elapsed,
            'frame': self.frame,
            'posx': self.posx,
            'posy': self.posy,
            'intx': self.intx,
            'inty': self.inty,
            'heading': self.heading,
            'deltaheading': self.deltaheading,
            'motor': self.motor_pos_rad,
            'motor_command': self.motor_command,
            'bar_position': self.bar_position,
            'out_voltage_yaw': self.output_voltage_yaw
        }
        self.logger_fictrac.add(log_data)

    def write_logfile_arduino(self):
        log_data = {
            'time': self.time_arduino,
            'motor': self.motor_pos_rad
        }
        self.logger_arduino.add(log_data)