%This code converts the panel and fictrac data to appropriate units and
%calls on additional code to calculate velocities

function [ t, stim_pos, vel_for, vel_yaw, fly_pos] = process_data( trial_time, trial_data, num_x_pixels)

%import acquisition settings
settings = sensor_settings;

%Asignment of the Daq channels
settings.fictrac_x_DAQ_AI = 4;
settings.fictrac_yaw_gain_DAQ_AI = 1;
settings.fictrac_yaw_DAQ_AI = 3; 
settings.fictrac_y_DAQ_AI = 2; 

settings.panels_x_DAQ_AI = 5;
settings.panels_y_DAQ_AI = 6;


data.Intx = trial_data( :, settings.fictrac_x_DAQ_AI ); %data from x channel
data.angularPosition = trial_data( :, settings.fictrac_yaw_gain_DAQ_AI ); 
data.Inty = trial_data( :, settings.fictrac_y_DAQ_AI );

%Get filtered position and velocity data 
smoothed = singleTrialVelocityAnalysis9mm(data, settings.sampRate);
vel_for = smoothed.xVel;
vel_yaw = smoothed.angularVel;
%vel_side = smoothed.yVel;

%Get position and time data
panels = trial_data( :, settings.panels_x_DAQ_AI ); %data from the x dimension in panels
fly_pos = smoothed.degAngularPosition;
[stim_pos] = process_panel_360(panels, num_x_pixels); %returns filtered and downsampled panel px data as well as calculated angle of the bar
[ t ] = resample(trial_time, 25, settings.sampRate); %downsamples the time

end

