function test_olfactometer_closed_loop_wind(PulseDur, N_repeat)
%%% test the pinch valve used for closed-loop wind device
%%% INPUTS:
%%%     PulseDur: duration of the pulse in sec
%%%     N_repeat: number of repeats
%%% OUTPUTS:
%%%     None
%%%
%%% Tatsuo Okubo
%%% 2021-03-01

%% parameters
Fs = 4000;  % sampling rate (Hz)
PreDur = 1; % (s)
PostDur = 1; % (s)

%% setup DAQ
daqreset
niIO = daq.createSession('ni');
devID = 'Dev1';
niIO.Rate = Fs;
I = niIO.addAnalogInputChannel(devID,[03],'Voltage');
DO = niIO.addDigitalChannel(devID, ['port0/line3'], 'OutputOnly'); % use the "center" valve

%% make a pulse waveform
Pulse = [zeros(round(PreDur*Fs),1); ones(round(PulseDur*Fs),1); zeros(round(PostDur*Fs),1)];
Output = Pulse; %

%% send the pulse to the olfactometer and repeat
for k=1:N_repeat
    niIO.queueOutputData(Output);
    in = niIO.startForeground;
end