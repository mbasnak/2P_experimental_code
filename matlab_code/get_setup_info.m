function setup = get_setup_info(setup_name)
%%% putting setup specific info in one file
%%% input: 2p-room, WLI-TOBIN
%%% output: structure with all the necessary info
%%% Tatsuo Okubo
%%% 2021/01/04

if strcmp(setup_name, '2p-room')
    setup.python_path = 'C:\src\2P_experimental_code\python_code';
elseif strcmp(setup_name, 'WLI-TOBIN')
    setup.python_path = 'C:\Users\Tots\Documents\GitHub\2P_experimental_code\python_code';
else
    error('Choose 2p-room or WLI-TOBIN')
end
    