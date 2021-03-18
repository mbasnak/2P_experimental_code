import os
import sys
sys.path.insert(0, os.path.abspath(r'C:/Users/Tots/Documents/GitHub/2P_experimental_code/python_code'))
from socket_client_wind_2p_open_loop import SocketClient

def experiment_code(experiment=None, time=60, logfile=None):

    experiment_param = {
        'experiment': experiment, # experiment type
        'experiment_time': time, # trial duration (s)
        'logfile_name': logfile or 'C:/Users/wilson_lab/Documents/Tots/test/test.hdf5', 
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
        time = float(sys.argv[2]) #...etc
        logfile = sys.argv[3]
        wind_dir = sys.argv[4]  # wind coming from a fixed direction [deg]
        experiment_code(experiment, time, logfile, wind_dir)
    else:  # no command line argument provided
        experiment_code()
