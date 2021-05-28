function [trial_data, trial_time] = run_MFC(run_obj)

flow_rate = run_obj.airflow.Value;

%% Setup NI-DAQ
s = setup_nidaq(run_obj.set_up);
settings = nidaq_settings;
SAMPLING_RATE = settings.sampRate;
s.Rate = SAMPLING_RATE; %sampling rate for the session (Jenny is using 4000 Hz)

%%
MFC = MFC_settings;
MFC_trigger = (flow_rate / MFC.MAX_FLOW) * MFC.MAX_V * ones(SAMPLING_RATE * MFC.WAIT, 1); %convert the airflow signal to voltage
imaging_trigger = zeros(SAMPLING_RATE * MFC.WAIT, 1);
valve_trigger = ones(SAMPLING_RATE * MFC.WAIT, 1);
valve_trigger(1) = 0;
output_data = [MFC_trigger, imaging_trigger, valve_trigger];
queueOutputData(s, output_data);

[trial_data, trial_time] = s.startForeground(); %gets data and timestamps for the NiDaq acquisition

end