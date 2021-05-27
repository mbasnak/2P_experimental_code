function s = setup_nidaq(setup_name)
%%% setting up NI-DAQ for each setup
%%% INPUT:
%%%     setup name (string): '2p-room' or 'WLI-TOBIN'
%%% OUTPUT:
%%%     NI-DAQ object
%%% Tatsuo Okubo
%%% 2021-01-07
%%% 2021-05-10: modified

if strcmp(setup_name, '2P-room')
    Dev = 'Dev1';
    s = daq.createSession('ni');

    %% Outputs
    s.addAnalogOutputChannel(Dev, 'ao0', 'Voltage'); % mass flow controller
    s.addDigitalChannel(Dev, 'port0/line0', 'OutputOnly'); % triggering scanimage
    s.addDigitalChannel(Dev, 'port0/line1:2', 'OutputOnly'); % use the "master and the "left" valve
    
    %% Inputs
    ai_channels_used = [1:3, 5, 10:15];
    aI = s.addAnalogInputChannel(Dev, ai_channels_used, 'Voltage');
    for i=1:length(ai_channels_used)
        aI(i).InputType = 'SingleEnded';
    end
        
%% channel references
% Input channels (MATLAB channel number, not what's on NI-DAQ):
%
%   Dev1:
%       AI.1 = Fictrac yaw gain
%       AI.2 = Fictrac y
%       AI.3 = Fictrac yaw
%       AI.4 = Panels x 
%       AI.5 = Fictrac x
%       AI.6 = piezo z
%       AI.7 = Panels y
%       AI.8 = motor position
%       AI.9 = mass flow controller (0-5V corresponds to 0-2L/min)
%
% Output channels:
%
%   Dev1:
%       AO.0 = mass flow controller (0-5V corresponds to 0-2L/min)
%       P0.0 = external trigger for scanimage
%       P0.1-2 = trigger for wind delivery (i.e. pinch valve in the olfactometer)       
    
elseif strcmp(setup_name, 'WLI-TOBIN')
    s = daq.createSession('ni');

    % Input channels:
    %
    %   Dev1:
    %       AI.1 = Fictrac yaw gain
    %       AI.2 = Fictrac y
    %       AI.3 = Fictrac x
    %       AI.4 = motor
    %       AI.5 = master valve
    %       AI.6 = odor valve (HIGH: odor, LOW: solvent)
    %
    % Output channels:
    %
    %   Dev1:
    %       D0.0 
    %       D0.1
    %       D0.2
    
    %add analog input channels
    ai_channels_used = 1:6;
    aI = s.addAnalogInputChannel('Dev1', ai_channels_used, 'Voltage');
    dO = s.addDigitalChannel('Dev1', ['port0/line1:2'], 'OutputOnly'); % master and left solenoid valves
    for i=1:length(ai_channels_used)
        aI(i).InputType = 'SingleEnded';
    end
else
    error('Choose 2P-room or WLI-TOBIN')
end