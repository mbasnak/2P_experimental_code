# 2P_experimental_code
Code to run fictrac trials while imaging and delivering visual or wind stimuli

## Installation notes
### Version
This code has been tested using
- MATLAB 2020b
- Python 3.7.4

## NI-DAQ channel information (2021/04/05 updated)
- AI1: yaw gain
- AI2: y
- AI3: yaw
- (AI4: frame clock, unused)
- AI5: xdim panels
- AI11: x
- AI12: piezo Z
- AI13: ydim panels
- AI14: motor position

| NI-DAQ channel | MATLAB | Description |
| ----------- | ----------- | ----------- |
| AI1 | 1 | yaw gain |
| AI2 | 2 | y |
| AI3 | 3 | yaw |
| AI4 | N.A.| frame clock (unused)|
| AI5 | 4 | x dim panels |
| AI11 | 5 | x |
| AI12 | 6 | piezo Z |
| AI13 | 7 | y dim panels |
| AI14 | 8 | motor position |


