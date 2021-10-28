function settings = nidaq_settings

% Acquisition params
settings.sampRate = 4000;

% Processing settings
settings.cutoffFreq = 100;
settings.aiType = 'SingleEnded';
settings.sensorPollFreq = 50; 

settings.fictrac_x_DAQ_AI = 1;
settings.fictrac_y_DAQ_AI = 2; 
settings.fictrac_yaw_DAQ_AI = 3; 
settings.fictrac_yaw_gain_DAQ_AI = 4;
settings.fictrac_yaw_OL_DAQ_AI = 12; % used for yoked wind + bar open-loop

settings.panels_x_DAQ_AI = 5;
settings.panels_y_DAQ_AI = 7;
settings.piezo = 8;
settings.motor_DAQ_AI = 9;

% mass flow controller
settings.wind_valve = 6;
settings.mfc_control = 10;
settings.mfc_monitor = 11;


