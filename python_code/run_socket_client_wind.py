import os
import sys
sys.path.insert(0, os.path.abspath('C:/src/experimental_code/python_code'))
from socket_client_wind import SocketClient  # note: different file for TO's experiments

def experiment_code(experiment=None, time=None, logfile=None):
    experiment_param = {
        'experiment': experiment, #the experiment number determines the experiment type, with
        'experiment_time': time, #this is the trial length
        'logfile_name': logfile or 'C:/Users/Tots/Documents/FlyOnTheBall/data/data.hdf5', #this file will be saved in the experiment directory we choose in the GUI I believe, because of the matlab code
        'logfile_auto_incr': True,
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

# an example of how to run this code from the command line
# python.exe run_socket_client_wind.py Spontaneous_walking 3 "C:\Users\Tots\Documents\test\20210115_test\ball\hdf5_Spontaneous_walking_Closed-loop_20210119_123524_sid_1_tid_1.hdf5"  1 &'
