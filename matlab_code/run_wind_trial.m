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

%% prepare outputs
flow_rate = 0.2; % [L/min] (range 0-2 L/min)
if flow_rate > 2
    error('Flow rate needs to be within 0-2 L/min')
end

if strcmp(run_obj.set_up, '2P-room')
    MFC_trigger = (flow_rate / 2) * 5 * ones(SAMPLING_RATE*total_duration,1); % 
    MFC_trigger(end) = 0; % turn off air at the end of the trial
    imaging_trigger = zeros(SAMPLING_RATE*total_duration,1); %set the size for the imaging trigger
    imaging_trigger(2:end-1) = 1.0;
    valve_trigger = imaging_trigger; % idenfical to the imagging trigger (high throuhout the trial except for the first and last samples) 
    output_data = [MFC_trigger, imaging_trigger, valve_trigger, valve_trigger];
    queueOutputData(s, output_data);
    
    % Trigger scanimage run if using 2p.
    if(run_obj.using_2p == 1)
        scanimage_file_str = ['cdata_' trial_core_name '_tt_' num2str(total_duration) '_'];
        fprintf(scanimage_client, [scanimage_file_str]);
        disp(['Wrote: ' scanimage_file_str ' to scanimage server' ]);
        acq = fscanf(scanimage_client, '%s');
        disp(['Read acq: ' acq ' from scanimage server' ]);
    end
elseif strcmp(run_obj.set_up, 'WLI-TOBIN')
    Ch.master = 1; % master solenoid valve
    Ch.odor = 2; % odor (HIGH) vs solvant (LOW)
    Pulse = zeros(SAMPLING_RATE*total_duration,1); %set the size for the imaging trigger
    Pulse(2:end-1) = 1.0;
    output_data(:, Ch.master) = Pulse;
    output_data(:, Ch.odor) = Pulse;
    queueOutputData(s, output_data);
end

%% prepare file names
experiment_type = run_obj.experiment_type;
cur_trial_corename = [experiment_type '_' task '_' datestr(now, 'yyyymmdd_HHMMSS') '_sid_' num2str(run_obj.session_id) '_tid_' num2str(tid)];
cur_trial_file_name = [ run_obj.experiment_ball_dir '\hdf5_' cur_trial_corename '.hdf5' ];
hdf_file = cur_trial_file_name; %etsablishes name of hdf5 file to be written.

%% start the trial
delay = 1; % waiting time for the motor to get ready (s)

%Run the python script that runs fictrac and other experimental conditions
if (strcmp(run_obj.experiment_type,'Spontaneous_walking')==1)
    if strcmp(task, 'Closed-loop') == 1 
        if strcmp(run_obj.set_up, 'WLI-TOBIN')
            system(['conda activate CLwind & python.exe run_socket_client_wind.py ' num2str(run_obj.experiment_type) ' ' num2str(run_obj.trial_t + delay) ' "' hdf_file '" ' ' 1 &'])
        elseif strcmp(run_obj.set_up, '2P-room')
            system(['python.exe run_socket_client_wind.py ' num2str(run_obj.experiment_type) ' ' num2str(run_obj.trial_t) ' "' hdf_file '" ' ' 1 &']);
        end
    elseif strcmp(task, 'Open-loop') == 1
        if strcmp(run_obj.set_up, 'WLI-TOBIN')
            system(['conda activate CLwind & python.exe run_socket_client_wind_2p_open_loop.py ' num2str(run_obj.experiment_type) ' ' num2str(run_obj.trial_t + delay) ' "' hdf_file '" ' ' 1 &'])
        elseif strcmp(run_obj.set_up, '2P-room')
            system(['python.exe run_socket_client_wind_2p_open_loop.py ' num2str(run_obj.experiment_type) ' ' num2str(run_obj.trial_t) ' "' hdf_file '" ' ' 1 &']);
        end
    else
        disp('Task not ready!')
    end
        
elseif strcmp(run_obj.experiment_type,'Simulus_jump')==1
    disp('Trial type not ready!')
elseif strcmp(run_obj.experiment_type,'Gain_change')==1
    disp('Trial type not ready!')
end

pause(delay)

%Start the data acquisition
[trial_data, trial_time] = s.startForeground(); %gets data and timestamps for the NiDaq acquisition

system('exit');
release(s);

end