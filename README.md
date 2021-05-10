# 2P_experimental_code
Code to run fictrac trials while imaging and delivering visual or wind stimuli

## Installation notes
### Version
This code has been tested using
- MATLAB 2020b
- Python 3.7.4

## NI-DAQ channel information
2021/05/10 updated

| NI-DAQ  | MATLAB | Description | Notes |
| ------- |:------:| ----------- | ----- |
| AI1 | 1 | yaw gain ||
| AI2 | 2 | y ||
| AI3 | 3 | yaw ||
| AI4 | N.A.| frame clock (unused)||
| AI5 | 4 | x dim panels ||
| AI11 | 5 | x ||
| AI12 | 6 | piezo Z ||
| AI13 | 7 | y dim panels ||
| AI14 | 8 | motor position ||
| AI15 | 9 | mass flow controller (monitor) | 0-5V corresponds to 0-2L/min |
| AO0 |  | mass flow controller (control) | 0-5V corresponds to 0-2L/min |
