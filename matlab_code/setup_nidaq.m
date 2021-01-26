function s = setup_nidaq(setup_name)
%%% setting up NI-DAQ for each setup
%%% input: 2p-room, WLI-TOBIN
%%% output: IN-DAQ object
%%% Tatsuo Okubo
%%% 2021/01/07

if strcmp(setup_name, '2P-room')
    s = daq.createSession('ni');

    % This channel is for external triggering of scanimage 5.1
    s.addDigitalChannel('Dev1', 'port0/line0', 'OutputOnly');
    %add analog input channels
    ai_channels_used = [1:3,11:15];
    aI = s.addAnalogInputChannel('Dev3', ai_channels_used, 'Voltage');
    for i=1:length(ai_channels_used)
        aI(i).InputType = 'SingleEnded';
    end
    aI(9) = s.addAnalogInputChannel('Dev1', 12, 'Voltage'); % piezo Z
    aI(9).InputType = 'SingleEnded';    
    
    % Input channels:
    %
    %   Dev1:
    %       AI.1 = Fictrac yaw gain
    %       AI.2 = Fictrac y
    %       AI.3 = Fictrac x gain
    %       AI.4 = Fictrac x
    %       AI.5 = Panels x
    %       AI.6 = Panels y
    %       AI.7 = Panels ON/OFF
    %       AI.8 = arduino LED
    %       AI.9 = piezo z
    %
    % Output channels:
    %
    %   Dev1:
    %       P0.0        = external trigger for scanimage
    %
    
elseif strcmp(setup_name, 'WLI-TOBIN')
    s = daq.createSession('ni');

    %add analog input channels
    ai_channels_used = 1:5;
    aI = s.addAnalogInputChannel('Dev1', ai_channels_used, 'Voltage');
    for i=1:length(ai_channels_used)
        aI(i).InputType = 'SingleEnded';
    end
else
    error('Choose 2P-room or WLI-TOBIN')
end
    