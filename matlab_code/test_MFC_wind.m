%%% function test_MFC_wind(PulseDur)
%%% test the pinch valve used for closed-loop wind device
%%% INPUTS:
%%%     pulse_dur: duration of the pulse in sec
%%% OUTPUTS:
%%%     None
%%%
%%% Tatsuo Okubo
%%% 2021-05-28

%% parameters
pulse_dur = 10; %[s]
flow_rate = 0.2; % [L/min] make sure the air is turned on!

%% setup DAQ
set_up = '2P-room';
s = setup_nidaq(set_up);
settings = nidaq_settings;
SAMPLING_RATE = settings.sampRate;
s.Rate = SAMPLING_RATE; %sampling rate for the session (Jenny is using 4000 Hz)

%% preparation
MFC = MFC_settings;
MFC_flow = (flow_rate / MFC.MAX_FLOW) * MFC.MAX_V * ones(SAMPLING_RATE * MFC.WAIT, 1); %convert the airflow signal to voltage
imaging_trigger = zeros(SAMPLING_RATE * MFC.WAIT, 1);
MFC_trigger = zeros(SAMPLING_RATE * MFC.WAIT, 1);
output_data = [MFC_flow, imaging_trigger, MFC_trigger];
queueOutputData(s, output_data);
s.startForeground();

%% pulse
MFC_flow = (flow_rate / MFC.MAX_FLOW) * MFC.MAX_V * ones(SAMPLING_RATE * pulse_dur, 1); %convert the airflow signal to voltage
MFC_flow(end) = 0; % turn off at the end of the trial
imaging_trigger = zeros(SAMPLING_RATE * pulse_dur, 1);
MFC_trigger = ones(SAMPLING_RATE * pulse_dur, 1);
MFC_trigger(1) = 0;
MFC_trigger(end) = 0;
output_data = [MFC_flow, imaging_trigger, MFC_trigger];
queueOutputData(s, output_data);
[output,time] = s.startForeground();

%%
if false
    figure
    set(gcf, 'position', [400 400 1200 400])
    plot(time,output(:,9) * MFC.MAX_FLOW / MFC.MAX_V)
    ylim([0 MFC.MAX_FLOW + 0.1])
    xlabel('time (s)', 'fontsize', 12)
    ylabel('flow rate (L/min)')
end