function [ skt ] = connect_to_scanimage()
%UNTITLED3 Summary of this function goes here
%   Detailed explanation goes here

skt = tcpip('10.119.97.242', 30000, 'NetworkRole', 'client'); %if this code is giving an error, change the first argument by whatever appears as 'ipv4 address' in crane using 'ipconfig /all'
fopen(skt);
flushinput(skt);

end

