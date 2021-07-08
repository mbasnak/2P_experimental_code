#!/usr/bin/env python3

# Comments from this tutorial - https://realpython.com/python-sockets/

# FT terminal:
# cd C:\Users\amoore\akm_fictrac\fictrac-master\sample
# ..\bin\Release\fictrac.exe config_3_cw_ball_turns_with_socket.txt

# The FT terminal will appear to hang. That’s because the server is blocked (suspended) in a call.
# It’s waiting for a client connection. Now open another terminal window or command prompt
# and run the client:
# cd C:\Users\amoore\akm_fictrac\fictrac-master\scripts
# py socket_client_akm_noJumps_continuous.py

import time
import socket
from Phidget22.Phidget import *
from Phidget22.Devices.VoltageOutput import *
import numpy as np

# *********** Set up socket info ***********

HOST = '127.0.0.1'  # Standard loopback interface address (localhost)
PORT = 65432  # Port to listen on (non-privileged ports are > 1023)

# The following is from the 'init' part of analogout.py (https://github.com/jennyl617/fly_experiments/blob/master/fictrac_2d/analogout.py)


# *********** Set up aout params ***********

rate_to_volt_const = 50,
aout_max_volt = 10.0,
aout_min_volt = 0.0,
aout_max_volt_vel = 10.0,
aout_min_volt_vel = 0.0,
lowpass_cutoff = 0.5,

# *********** Set up analog output channels ***********

# Setup analog output 'runSpeed' - inst. running speed in rads/frame
aout_runSpeed = VoltageOutput()
aout_runSpeed.setChannel(0)
aout_runSpeed.openWaitForAttachment(5000)
aout_runSpeed.setVoltage(0.0)
aout_runSpeed.setDeviceSerialNumber(525438)


# Setup analog output 'animalheading360' -- this will be fly heading in degrees (0-3.6V) as in open loop trials
aout_animalheading360 = VoltageOutput()
aout_animalheading360.setChannel(1)
aout_animalheading360.openWaitForAttachment(5000)
aout_animalheading360.setVoltage(0.0)
aout_animalheading360.setDeviceSerialNumber(525438)

# xpos command to controller
aout_xposcmd = VoltageOutput()
aout_xposcmd.setChannel(2)
aout_xposcmd.openWaitForAttachment(5000)
aout_xposcmd.setVoltage(0.0)
aout_xposcmd.setDeviceSerialNumber(525438)

# ypos command to controller (10V or 0V - 10V indicates that py script is running)
aout_yposcmd = VoltageOutput()
aout_yposcmd.setChannel(3)
aout_yposcmd.openWaitForAttachment(5000)
aout_yposcmd.setVoltage(0.0)
aout_yposcmd.setDeviceSerialNumber(525438)


# Tell the py script to run for 5 minutes (50 frames/s * 60 s/minute * 5 minutes)
maxFrames = 50 * 60 * 5

# Initialize
frameCount = 0
bias_dps=0
bias_degPerFrame=0
accumulatedOffset270=0



# Open the connection (FicTrac must be waiting for socket connection) and get data until FT closes....

# Below we create a socket object using socket.socket() and specify the socket type as socket.SOCK_STREAM.
# When you do that, the default protocol that’s used is the Transmission Control Protocol (TCP). This is a good
# default and probably what you want. # The object can be used w/in a with statement and there's no need to call s.close().

with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as sock:
    sock.connect((HOST, PORT))
    data = ""

    while frameCount <= maxFrames:



        # Receive one data frame
        new_data = sock.recv(1024)
        if not new_data:
            break

        # Decode received data
        data += new_data.decode('UTF-8')

        # Find the first frame of data
        endline = data.find("\n")
        line = data[:endline]  # copy first frame
        data = data[endline + 1:]  # delete first frame

        # Tokenise
        toks = line.split(", ")

        # Fixme: sometimes we read more than one line at a time,
        # should handle that rather than just dropping extra data...
        if ((len(toks) < 24) | (toks[0] != "FT")):
            print('Bad read')
            continue

        # Extract FicTrac variables - see https://github.com/rjdmoore/fictrac/blob/master/doc/data_header.txt
        cnt = int(toks[1])
        dr_cam = [float(toks[2]), float(toks[3]), float(toks[4])]
        err = float(toks[5])
        r_cam = [float(toks[9]), float(toks[10]), float(toks[11])]
        r_lab = [float(toks[12]), float(toks[13]), float(toks[14])]
        heading = float(toks[17])
        step_dir = float(toks[18])
        step_mag = float(toks[19])
        intx = float(toks[20])
        inty = float(toks[21])
        ts = float(toks[22])
        seq = int(toks[23])

        # Get variables w/ names that match JL's code...

        velx = float(toks[
                         6])  # ball velocity about the x axis, i.e. L/R rotation velocity (units = rotation angle/axis in rads), see config image
        vely = float(toks[7])  # ball velocity about the y axis, i.e. fwd/backwards rotation velocity
        velheading = float(toks[8])  # ball velocity about the z axis, i.e. yaw/heading velocity

        heading = float(
            toks[17])  # integrated heading direction of the animal in lab coords (units = rads, 0-360 in degrees)
        intx = float(toks[15])  # displacement of the fly in the x direction
        inty = float(toks[16])  # displacement of the fly in the y direction


        frameCount=cnt

        # NOW, COMPUTE VOLTAGES & SEND IT OUT FROM THE PHIDGET -- this is the "run" part of https://github.com/jennyl617/fly_experiments/blob/master/fictrac_2d/analogout.py
        # ************************************************************


        # get fly heading - convert rads to degrees & normalize for output voltage range (0-3.6V). we'll sent this to
        # the phidget below (aout_animalheading360).
        animal_heading_360 = heading * (180 / np.pi)
        flyheading = animal_heading_360 / 100


        # ft units for "step_mag" (inst. run speed) are radians/frame - the values are rarely >0.1, so we'll multiply
        # by 100, such that 0.1 rads/frame = 10 V output. we'll sent this to the phidget below (runSpeed).
        scaled_runSpeed = step_mag * 100
        # clip signal if it's not between 0-10 V
        if scaled_runSpeed > 10:
            scaled_runSpeed = 10
        if scaled_runSpeed < 0:
            scaled_runSpeed = 0


        # *finally* - compute the new bar position and then convert it to an xpos voltage. we'll send this second value
        # to the phidget below (xposcmd).


        # → update bar offset & wrap if needed
        accumulatedOffset270 = accumulatedOffset270 + bias_degPerFrame
        if accumulatedOffset270 > 270:
            accumulatedOffset270 = (270 - accumulatedOffset270) * -1

        # → subtract this offset from the animal's heading in a 270° world
        animal_heading_270 = animal_heading_360 * (270 / 360)
        current_bar_pos_270 = animal_heading_270

        # → to get the corresponding xpos voltage, normalize to 10V and then subtract from 10V
        #   so that the bar moves opposite of the fly's change in heading - i.e. the bar moves
        #   in the same direction as the ball.
        xout = (current_bar_pos_270 / 270) * 10
        xout = 10 - xout



        # wrap xpos command if it's out of range
        if xout > 10:
           xout = (10 - xout) * -1
        elif xout < 0:
           xout = 10 - (xout * -1)


        # send outputs to Phidget
        aout_yposcmd.setVoltage(10.0)
        aout_xposcmd.setVoltage(xout)
        aout_animalheading360.setVoltage(flyheading)
        aout_runSpeed.setVoltage(scaled_runSpeed)








    # When finished, close the outputs (this sets voltages to 0)
    aout_runSpeed.close()
    aout_animalheading360.close()
    aout_xposcmd.close()
    aout_yposcmd.close()











