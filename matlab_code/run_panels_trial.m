function [ trial_data, trial_time ] = run_panels_trial(tid, task, run_obj, scanimage_client, trial_core_name )

%Move to the folder with the python code
setup = get_setup_info(run_obj.set_up);
cd(setup.python_path);

% Currently v2
disp(['About to start trial task: ' task]);

% Setup data structures for read / write on the daq board
s = daq.createSession('ni');

% This channel is for external triggering of scanimage 5.1
s.addDigitalChannel('Dev1', 'port0/line0', 'OutputOnly');
%add analog input channels
ai_channels_used = [1:3,5,11,13];
aI = s.addAnalogInputChannel('Dev1', ai_channels_used, 'Voltage');
for i=1:length(ai_channels_used)
    aI(i).InputType = 'SingleEnded';
end
aI(9) = s.addAnalogInputChannel('Dev1', 12, 'Voltage');
aI(9).InputType = 'SingleEnded';

% Input channels:
%
%   Dev1:
%       AI.1 = Fictrac yaw gain
%       AI.2 = Fictrac y
%       AI.3 = Fictrac yaw
%       AI.4 = Fictrac x
%       AI.5 = Panels x
%       AI.6 = Panels y
%       AI.7 = Panels ON/OFF
%       AI.8 = arduino LED
%       AI.9 = piezo z
%
% Output channels:
%
%   Dev1:
%       P0.0 = external trigger for scanimage
%

%establish the acquisition rate and duration
settings = sensor_settings;
SAMPLING_RATE = settings.sampRate;
s.Rate = SAMPLING_RATE; %sampling rate for the session (Jenny is using 4000 Hz)
total_duration = run_obj.trial_t; %trial duration taken from the GUI input

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

experiment_type = run_obj.experiment_type;
%create the variable arduino when necessary
%arduino = double(); 

cur_trial_corename = [experiment_type '_' task '_' datestr(now, 'yyyymmdd_HHMMSS') '_sid_' num2str(run_obj.session_id) '_tid_' num2str(tid)];
cur_trial_file_name = [ run_obj.experiment_ball_dir '\hdf5_' cur_trial_corename '.hdf5' ];
hdf_file = cur_trial_file_name; %etsablishes name of hdf5 file to be written.
        

% Configure Panels 
start = run_obj.start_pos;
if ( strcmp(task, 'Closed_Loop') == 1 )  
    closedLoop(run_obj.pattern_number, start);
elseif ( strcmp(task, 'Open_Loop') == 1 )
    openLoop(run_obj.pattern_number, run_obj.function_number);
elseif ( strcmp(task, 'Closed_Loop_X_Open_Loop_Y') == 1)
    closedOpenLoop(run_obj.pattern_number, run_obj.function_number, start); 
elseif ( strcmp(task, 'Closed_Loop_X_Closed_Loop_Y') == 1)
    closedClosedLoop(run_obj.pattern_number, start); 
end

% Start panels
Panel_com('start');

% Run the python script that runs fictrac and other experimental conditions
if (strcmp(run_obj.experiment_type,'Spontaneous_walking')==1)
    system(['python run_socket_client.py ' num2str(run_obj.experiment_type) ' ' num2str(run_obj.trial_t) ' "' hdf_file '" ' ' 1 &']);
elseif (strcmp(run_obj.experiment_type,'Gain_change')==1)
    system(['python run_socket_client_gain_change.py ' num2str(run_obj.experiment_type) ' ' num2str(run_obj.trial_t) ' "' hdf_file '" ' ' 1 &']); 
elseif (strcmp(run_obj.experiment_type,'Stimulus_jump')==1)
    system(['python run_socket_client_bar_jump.py ' num2str(run_obj.experiment_type) ' ' num2str(run_obj.trial_t) ' "' hdf_file '" ' ' 1 &']); 
end
%Start the data acquisition
[trial_data, trial_time] = s.startForeground(); %gets data and timestamps for the NiDaq acquisition

Panel_com('stop');
Panel_com('all_off');
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

function openLoop(pattern, func)
%% begins openLoop setting in panels
freq = 50;
Panel_com('stop');
%set pattern number
Panel_com('set_pattern_id', pattern);
%set open loop for x
Panel_com('set_mode', [4, 0]);
Panel_com('set_funcX_freq' , freq);
Panel_com('set_posFunc_id', [1, func]);
Panel_com('set_position', [1, 1]);
%quiet mode on
Panel_com('quiet_mode_on');
end

function closedOpenLoop(pattern, func, startPosition)
%% begins closedLoop setting in panels
freq = 5;
Panel_com('stop');
%set pattern number
Panel_com('set_pattern_id', pattern);
%set closed loop for x , open loop y
Panel_com('set_mode', [3, 4]);
Panel_com('set_funcY_freq' , freq);
Panel_com('set_posFunc_id', [2, func]);
%Define the start position in y according to the y pos func

Panel_com('set_position', [startPosition, 1]);
%quiet mode on
Panel_com('quiet_mode_on');
end

function closedClosedLoop(pattern, startPosition)
%% begins closedLoop setting in panels
freq = 50;
Panel_com('stop');
Panel_com('g_level_7');
%set pattern number
Panel_com('set_pattern_id', pattern);
%set closed loop for x and y
Panel_com('set_mode', [3, 3]);
Panel_com('set_position', [startPosition, 1]);
%quiet mode on
Panel_com('quiet_mode_on');
end
