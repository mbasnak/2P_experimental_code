#!/usr/bin/env python3

from Phidget22.Phidget import *
from Phidget22.Devices.VoltageOutput import *
import time

phidget_wind = 589946  # for sending the position of the motor to NI-DAQ
aout_channel_wind_valve = 2

aout_wind_valve = VoltageOutput()
aout_wind_valve.setDeviceSerialNumber(phidget_wind)
aout_wind_valve.setChannel(aout_channel_wind_valve)
aout_wind_valve.openWaitForAttachment(5000)
aout_wind_valve.setVoltage(0.0)

experiment_time = 20  # (s)
time_start = time.time() 


while True:
    time_elapsed = time.time() - time_start
    aout_wind_valve.setVoltage(5.0)
    if time_elapsed > experiment_time:
        aout_wind_valve.setVoltage(0.0)
        break