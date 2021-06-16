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
| AI10 | 6 | y dim | Panels |
| AI11 | 7 | piezo Z | fast-Z objective|
| AI12 | 8 | motor position | wind device|
| AI13 | 9 | MFC (control) | copy of the control signal |
| AI14 | 10 | MFC (monitor) | 0-5V corresponds to 0-2L/min |
| AI15 | 11 | sensor signal from Pockels cell | for monitoring laser power |
| AO0 |  | mass flow controller (control) | 0-5V corresponds to 0-2L/min |
| DO0 |  | imaging trigger| ScanImage |
| DO1 |  | valve ON/OFF | MFC |
| DO6 |  | acquisition stop? | ScanImage |


## How to run vision & wind trials

### Closed-loop visual panels  + closed=loop wind
- Type a "Pattern number" (e.g. 57 for 2px-wide vertical bar) for the visual stimulus.
- Type an "Airflow (L/min)" for the wind stimulus.
- If you want to change the offset between these two stimuli, you can specify it in the "Initial pos x (deg)".
  - Default is 0 deg (vision & wind are aligned).
  - The wind tube is always at 0 deg. If you specify +90 deg, the bar will initially appear at the right of the fly (viewed from the top) and as the fly moves, this +90 deg offset will be maintained throughout the trial.

### Static visual bar + wind
- Type 63 for the "Pattern number." This pattern has a 2-px wide static bar but with different locations specified as y pos.
- To specify the location of the static bar, type in a 0-360 deg number in the "Initial pos y (deg)".
- **Note that you'll need to choose "Closed_Loop" for the panels**, even though the panels will not react to fly's movement. This is due to easy of plotting.
- You can choose either closed-bar or open-loop for the wind.
