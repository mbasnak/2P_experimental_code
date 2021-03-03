%%% converts fictrac data to appropriate units and calculate velocities
%%% read panel and motor data and apply smoothing
%%% based on process_data.m by Melanie Basnak
%%% Tatsuo Okubo
%%% 2021-03-03

function [ t, stim_pos_panel, stim_pos_motor, vel_for, vel_yaw, fly_pos] = process_data_both( trial_time, trial_data, num_x_pixels)

%% import acquisition settings
settings = sensor_settings;
sampRate_new = 25; % sampling rate after downsampling (Hz)

%% Asignment of the DAQ channels
settings.fictrac_x_DAQ_AI = 4;
settings.fictrac_yaw_gain_DAQ_AI = 1;
settings.fictrac_yaw_DAQ_AI = 3; 
settings.fictrac_y_DAQ_AI = 2; 

settings.panels_x_DAQ_AI = 5;
settings.panels_y_DAQ_AI = 6;
settings.motor_DAQ_AI = 10;

data.Intx = trial_data( :, settings.fictrac_x_DAQ_AI ); %data from x channel
data.angularPosition = trial_data( :, settings.fictrac_yaw_gain_DAQ_AI ); 
data.Inty = trial_data( :, settings.fictrac_y_DAQ_AI );

%% Get filtered position and velocity data 
smoothed = singleTrialVelocityAnalysis9mm_TO(data, settings.sampRate, sampRate_new);
vel_for = smoothed.xVel;
vel_yaw = smoothed.angularVel;
%vel_side = smoothed.yVel;

%% Get panel position and time data
panels = trial_data( :, settings.panels_x_DAQ_AI ); %data from the x dimension in panels
fly_pos = smoothed.degAngularPosition;
[stim_pos_panel] = process_panel_360(panels, num_x_pixels); %returns filtered and downsampled panel px data as well as calculated angle of the bar
[ t ] = resample_new(trial_time, sampRate_new, settings.sampRate); %downsamples the time

%% Get panel position
motor = trial_data( :, settings.motor_DAQ_AI);
downsampled.motor = resample_new(motor, sampRate_new, settings.sampRate);
downsRad.motor = downsampled.motor .* 2 .* pi ./ 10; % from voltage to radian
downsDeg.motor = downsRad.motor .* 360 ./ (2 * pi); 
stim_pos_motor = downsDeg.motor;

end