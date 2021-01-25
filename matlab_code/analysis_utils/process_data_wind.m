%%% based on process_data_wind.m for wind trials
%%% just plotting fictrac and not the panels for now
%%% Tatsuo Okubo
%%% 2021/01/25

function [ t, stim_pos, vel_for, vel_yaw, fly_pos] = process_data_wind( trial_time, trial_data)

%import acquisition settings
settings = sensor_settings;

%Asignment of the Daq channels
settings.fictrac_x_DAQ_AI = 4;
settings.fictrac_yaw_gain_DAQ_AI = 1;
settings.fictrac_x_gain_DAQ_AI = 3; 
settings.fictrac_y_DAQ_AI = 2; 

data.ficTracIntx = trial_data( :, settings.fictrac_x_DAQ_AI ); %data from x channel
data.ficTracAngularPosition = trial_data( :, settings.fictrac_yaw_gain_DAQ_AI ); 
data.ficTracInty = trial_data( :, settings.fictrac_y_DAQ_AI );

%Get filtered position and velocity data 
smoothed = singleTrialVelocityAnalysis9mm(data, settings.sampRate);
vel_for = smoothed.xVel;
vel_yaw = smoothed.angularVel;
%vel_side = smoothed.yVel;

%Get position and time data
fly_pos = smoothed.degAngularPosition;
[ t ] = resample(trial_time, 25, settings.sampRate); %downsamples the time

% TO DO: return wind tube position
stim_pos = nan;

end

