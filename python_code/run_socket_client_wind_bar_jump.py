import os
import sys
sys.path.insert(0, os.path.abspath('C:/Users/WilsonLab/Desktop/FicTrac_Experiments/2P_experimental_code/python_code'))
from socket_client_wind_bar_jump import SocketClientWindBarJump

def experiment_code(experiment=None, time=None, logfile=None, offset = 0):
    experiment_param = {
        'experiment': experiment, #the experiment number determines the experiment type, with
        'experiment_time': time, #this is the trial length
        'logfile_name': logfile or 'Z:/Wilson Lab/Mel/FlyOnTheBall/data/data.hdf5', #this file will be saved in the experiment directory we choose in the GUI I believe, because of the matlab code
        'logfile_auto_incr': True,
        'logfile_auto_incr_format': '{0:06d}',
        'logfile_dt': 0.01,
        'offset': offset
    }
    client = SocketClientWindBarJump(experiment_param)
    client.run()

if __name__ == '__main__':

    """
    ARGV: 
    1: experiment, 
    2: experiment time,
    3: logfile
    """

    if len(sys.argv) > 1:    #from the list of arguments given to the system by the matlab code run_trial
        experiment = sys.argv[1] #make the first argument be the experiment...
        time = float(sys.argv[2]) #...etc
        logfile = sys.argv[3]
        experiment_code(experiment, time, logfile)
    else:
        experiment_code()