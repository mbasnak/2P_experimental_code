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
| AI1 | 1 | x | FicTrac |
| AI2 | 2 | y | FicTrac |
| AI3 | 3 | yaw | FicTrac |
| AI4 | 4 | yaw gain | FicTrac |
| AI5 | 5 | x dim | Panels |
| AI6 | 6 | MFC (valve) | copy of the valve signal |
| AI10 | 7 | y dim | Panels |
| AI11 | 8 | piezo Z | fast-Z objective|
| AI12 | 9 | motor position | wind device|
| AI13 | 10 | MFC (control) | copy of the control signal |
| AI14 | 11 | MFC (monitor) | 0-5V corresponds to 0-2L/min |
| AI15 | 12 | Fictrac yaw (backup) | used for yoked wind+bar open-loop |
| AO0 |  | mass flow controller (control) | 0-5V corresponds to 0-2L/min |
| DO0 |  | imaging trigger| ScanImage |
| DO1 |  | valve ON/OFF | MFC |
| DO6 |  | acquisition stop? | ScanImage |
