function s = setup_nidaq(setup_name)
%%% setting up NI-DAQ for each setup
%%% INPUT:
%%%     setup name (string): '2p-room' or 'WLI-TOBIN'
%%% OUTPUT:
%%%     NI-DAQ object
%%% Tatsuo Okubo
%%% 2021-01-07
%%% 2021-03-01: modified

if strcmp(setup_name, '2P-room')
    s = daq.createSession('ni');

    %% Outputs
    s.addDigitalChannel('Dev1', 'port0/line0', 'OutputOnly'); % triggering scanimage
    s.addDigitalChannel('Dev1', 'port0/line1:2', 'OutputOnly'); % use the "master and the "left" valve
    
    %% Inputs
    ai_channels_used = [1:3, 5, 11:14];
    aI = s.addAnalogInputChannel('Dev1', ai_channels_used, 'Voltage');
    for i=1:length(ai_channels_used)
        aI(i).InputType = 'SingleEnded';
    end
        
    %% channel references
    % Input channels:
    %
    %   Dev3:
    %       AI.1 = Fictrac yaw gain
    %       AI.2 = Fictrac y
    %       AI.3 = Fictrac x gain
    %       AI.4 = Fictrac x
    %       AI.5 = Panels x
    %       AI.6 = Panels y
    %       AI.7 = Panels ON/OFF
    %       AI.8 = arduino LED
    %
    %   Dev1:
    %       AI.9 = piezo z
    %       AI.10 = motor position
    %       
    % Output channels:
    %
    %   Dev1:
    %       P0.0 = external trigger for scanimage
    %       P0.3 = trigger for wind delivery (i.e. pinch valve in the olfactometer)       
    
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
    dO = s.addDigitalChannel('Dev1', ['port0/line0:1'], 'OutputOnly'); % solenoid valves
    for i=1:length(ai_channels_used)
        aI(i).InputType = 'SingleEnded';
    end
else
    error('Choose 2P-room or WLI-TOBIN')
end
    