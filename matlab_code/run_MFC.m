function [trial_data, trial_time] = run_MFC(run_obj)

flow_rate = run_obj.airflow.Value;

settings = sensor_settings;
SAMPLING_RATE = settings.sampRate;

%% Setup NI-DAQ

Dev = 'Dev1';
s = daq.createSession('ni');
s.Rate = SAMPLING_RATE;

% Outputs
s.addAnalogOutputChannel(Dev, 'ao0', 'Voltage'); % mass flow controller

% Inputs
ai_channels_used = [1:3, 5, 10:15];
aI = s.addAnalogInputChannel(Dev, ai_channels_used, 'Voltage');
for i=1:length(ai_channels_used)
    aI(i).InputType = 'SingleEnded';
end

%%
MFC_trigger = (flow_rate / 2) * 5 * ones(SAMPLING_RATE*8,1); %convert the airflow signal to voltage
output_data = [MFC_trigger];
queueOutputData(s, output_data);

[trial_data, trial_time] = s.startForeground(); %gets data and timestamps for the NiDaq acquisition

end