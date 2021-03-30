import os
import sys
sys.path.insert(0, os.path.abspath('C:/Users/WilsonLab/Desktop/FicTrac_Experiments/2P_experimental_code'))
from socket_client_wind_2p import SocketClient  # note: different code for wind experiments

def experiment_code(experiment=None, time=60, logfile=None):
    experiment_param = {
        'experiment': experiment, #the experiment number determines the experiment type, with
        'experiment_time': time, #this is the trial length (s)
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
        experiment_code(experiment, time, logfile)
    else:  # no command line argument provided
        experiment_code()