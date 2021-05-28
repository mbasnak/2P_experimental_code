function MFC = MFC_settings
%%% set the parameters for the mass flow controller (MFC)
%%% Tatsuo Okubo
%%% 2021-05-28

MFC.MAX_FLOW = 2; % [L/min] depends on the device
MFC.MAX_V = 5; % [V] input is 0-5 V
MFC.WAIT = 8; % [s] number of seconds to wait