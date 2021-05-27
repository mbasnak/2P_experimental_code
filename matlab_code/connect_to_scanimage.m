function [ skt ] = connect_to_scanimage()
%UNTITLED3 Summary of this function goes here
%   Detailed explanation goes here

skt = tcpip('10.119.97.143', 30000, 'NetworkRole', 'client');
fopen(skt);
flushinput(skt);

end

