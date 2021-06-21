function [ trial_data, trial_time ] = run_empty_trial(tid, task, run_obj, scanimage_client, trial_core_name)

%Move to the folder with the python code
setup = get_setup_info(run_obj.set_up);
cd(setup.python_path);

% Currently v2
disp(['About to start trial task: ' task]);

%% Setup NI-DAQ
s = setup_nidaq(run_obj.set_up);

%% establish the acquisition rate and duration
settings = nidaq_settings;
SAMPLING_RATE = settings.sampRate;
s.Rate = SAMPLING_RATE; %sampling rate for the session (Jenny is using 4000 Hz)
total_duration = run_obj.trial_t; %trial duration taken from the GUI input

%pre-allocate output data (imaging trigger)
imaging_trigger = zeros(SAMPLING_RATE*total_duration,1); %set the size for the imaging trigger
imaging_trigger(2:end-1) = 1.0;
MFC_flow = zeros(SAMPLING_RATE*total_duration,1); %zeros throughout the trial
MFC_trigger = zeros(SAMPLING_RATE*total_duration,1); %zeros throughout the trial
output_data = [MFC_flow, imaging_trigger, MFC_trigger];
queueOutputData(s, output_data);

% Trigger scanimage run if using 2p.
if(run_obj.using_2p == 1)
    scanimage_file_str = ['cdata_' trial_core_name '_tt_' num2str(total_duration) '_'];
    fprintf(scanimage_client, [scanimage_file_str]);
    disp(['Wrote: ' scanimage_file_str ' to scanimage server' ]);
    acq = fscanf(scanimage_client, '%s');
    disp(['Read acq: ' acq ' from scanimage server' ]);    
end

experiment_type = run_obj.experiment_type;
%create the variable arduino when necessary
%arduino = double(); 

cur_trial_corename = [experiment_type '_' task '_' datestr(now, 'yyyymmdd_HHMMSS') '_sid_' num2str(run_obj.session_id) '_tid_' num2str(tid)];
cur_trial_file_name = [ run_obj.experiment_ball_dir '\hdf5_' cur_trial_corename '.hdf5' ];
hdf_file = cur_trial_file_name; %etsablishes name of hdf5 file to be written.
        
% Run the python script that runs fictrac and other experimental conditions
system(['python run_socket_client.py ' num2str(run_obj.experiment_type) ' ' num2str(run_obj.trial_t) ' "' hdf_file '" ' ' 1 &']);
        
 %Start the data acquisition
[trial_data, trial_time] = s.startForeground(); %gets data and timestamps for the NiDaq acquisition
 
system('exit');
release(s);

end
