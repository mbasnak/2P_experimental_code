import os
import sys
sys.path.insert(0, os.path.abspath(r'C:/Users/Tots/Documents/GitHub/2P_experimental_code/python_code'))
from socket_client_wind_2p_modulated_open_loop import SocketClient

def experiment_code(experiment=None, stim_speed = 30, turn_type = None, time=60, logfile=None):

    experiment_param = {
        'experiment': experiment, # experiment type
        'stim_speed': stim_speed,
        'turn_type': turn_type,
        'experiment_time': time, # trial duration (s)
        'logfile_name': logfile or 'C:/Users/WilsonLab/Documents/Tots/test/test.hdf5', 
        'logfile_auto_incr': False,
        'logfile_auto_incr_format': '{0:06d}',
        'logfile_dt': 0.01,
    }
    client = SocketClient(experiment_param)
    client.run()

if __name__ == '__main__':

    """
    ARGV: 
    1: experiment, 
    2: experiment time,
    3: logfile
    """
    print(sys.argv)
    print('Running the experiment...')
    if len(sys.argv) > 1:    #from the list of arguments given to the system by the matlab code run_trial
        experiment = sys.argv[1] #make the first argument be the experiment...
        stim_speed = float(sys.argv[2])
        turn_type = sys.argv[3]
        time = float(sys.argv[4]) #...etc
        logfile = sys.argv[5]
        experiment_code(experiment, stim_speed, turn_type, time, logfile)
    else:  # no command line argument provided
        experiment_code()