#!/usr/bin/env python3

from Phidget22.Phidget import *
from Phidget22.Devices.VoltageOutput import *
import sys
import time

experiment_time = float(sys.argv[1]) + 2.0  # adding two extra seconds

phidget_wind = 589946  # for sending the position of the motor to NI-DAQ
aout_channel_wind_valve = 2

aout_wind_valve = VoltageOutput()
aout_wind_valve.setDeviceSerialNumber(phidget_wind)
aout_wind_valve.setChannel(aout_channel_wind_valve)
aout_wind_valve.openWaitForAttachment(5000)
aout_wind_valve.setVoltage(0.0)

time_start = time.time() 

print(f'Turning MFC on for {experiment_time} seconds')

while True:
    time_elapsed = time.time() - time_start
    aout_wind_valve.setVoltage(5.0)
    if time_elapsed > experiment_time:
        aout_wind_valve.setVoltage(0.0)
        print('Turning MFC off')
        break