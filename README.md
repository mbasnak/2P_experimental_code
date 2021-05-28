# 2P_experimental_code
Code to run fictrac trials while imaging and delivering visual or wind stimuli

## Installation notes
### Version
This code has been tested using
- MATLAB 2020b
- Python 3.7.4

## NI-DAQ channel information
2021/05/28 updated

| NI-DAQ  | MATLAB | Description | Notes |
| ------- |:------:| ----------- | ----- |
| AI1 | 1 | yaw gain ||
| AI2 | 2 | y ||
| AI3 | 3 | yaw ||
| AI4 | N.A.| frame clock (unused)||
| AI5 | 4 | x dim panels ||
| AI10 | 5 | mass flow controller (monitor) | 0-5V corresponds to 0-2L/min |
| AI11 | 6 | x ||
| AI12 | 7 | piezo Z ||
| AI13 | 8 | y dim panels ||
| AI14 | 9 | motor position ||
| AI15 | 10 | mass flow controller (control) | copy of the control signal |
| AO0 |  | mass flow controller (control) | 0-5V corresponds to 0-2L/min |
| DO0 |  | scanimage trigger| |
| DO1 |  | mass flow controller valve ON/OFF | |
