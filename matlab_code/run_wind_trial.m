function [ trial_data, trial_time ] = run_wind_trial(tid, task, run_obj, scanimage_client, trial_core_name )

%% Move to the folder with the python code
setup = get_setup_info(run_obj.set_up);
cd(setup.python_path);

%% Currently v2
disp(['About to start trial task: ' task]);

%% Setup NI-DAQ
s = setup_nidaq(run_obj.set_up);

%% establish the acquisition rate and duration
settings = sensor_settings;
SAMPLING_RATE = settings.sampRate;
s.Rate = SAMPLING_RATE; %sampling rate for the session (Jenny is using 4000 Hz)
total_duration = run_obj.trial_t; %trial duration taken from the GUI input

%% prepare scanimage
if strcmp(setup_name, '2P-room')
    %pre-allocate output data (imaging trigger)
    imaging_trigger = zeros(SAMPLING_RATE*total_duration,1); %set the size for the imaging trigger
    imaging_trigger(2:end-1) = 1.0;
    output_data = [imaging_trigger];
    queueOutputData(s, output_data);
    
    % Trigger scanimage run if using 2p.
    if(run_obj.using_2p == 1)
        scanimage_file_str = ['cdata_' trial_core_name '_tt_' num2str(total_duration) '_'];
        fprintf(scanimage_client, [scanimage_file_str]);
        disp(['Wrote: ' scanimage_file_str ' to scanimage server' ]);
        acq = fscanf(scanimage_client, '%s');
        disp(['Read acq: ' acq ' from scanimage server' ]);
    end
end

%% prepare file names
experiment_type = run_obj.experiment_type;
cur_trial_corename = [experiment_type '_' task '_' datestr(now, 'yyyymmdd_HHMMSS') '_sid_' num2str(run_obj.session_id) '_tid_' num2str(tid)];
cur_trial_file_name = [ run_obj.experiment_ball_dir '\hdf5_' cur_trial_corename '.hdf5' ];
hdf_file = cur_trial_file_name; %etsablishes name of hdf5 file to be written.

%% start the trial
start = run_obj.start_pos;
if ( strcmp(task, 'Closed_Loop') == 1 )
    closedLoop(run_obj.pattern_number, start);
elseif ( strcmp(task, 'Open_Loop') == 1 )
    openLoop(run_obj.pattern_number, run_obj.function_number);
end

%Run the python script that runs fictrac and other experimental conditions
if (strcmp(run_obj.experiment_type,'Spontaneous_walking')==1)
    system(['python run_socket_client.py ' num2str(run_obj.experiment_type) ' ' num2str(run_obj.trial_t) ' "' hdf_file '" ' ' 1 &']);
elseif (strcmp(run_obj.experiment_type,'Gain_change')==1)
    system(['python run_socket_client_gain_change.py ' num2str(run_obj.experiment_type) ' ' num2str(run_obj.trial_t) ' "' hdf_file '" ' ' 1 &']);
end

%Start the data acquisition
[trial_data, trial_time] = s.startForeground(); %gets data and timestamps for the NiDaq acquisition

system('exit');
release(s);

end

%Functions to set the panels correctly for each experiment type

function closedLoop(pattern, startPosition)
%% begins closedLoop setting in panels
Panel_com('stop');
%set arena
Panel_com('set_config_id', 1);
%set pattern number
Panel_com('set_pattern_id', pattern);
Panel_com('set_position', [startPosition, 1]);
%set closed loop for x
Panel_com('set_mode', [3, 0]);
Panel_com('quiet_mode_on');
Panel_com('all_off');
end