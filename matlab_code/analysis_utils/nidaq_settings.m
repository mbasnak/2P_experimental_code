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

settings.panels_x_DAQ_AI = 5;
settings.panels_y_DAQ_AI = 6;
settings.piezo = 7;
settings.motor_DAQ_AI = 8;

settings.mfc_control = 9;
settings.mfc_monitor = 10;


