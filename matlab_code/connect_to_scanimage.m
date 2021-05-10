function [ skt ] = connect_to_scanimage()
%UNTITLED3 Summary of this function goes here
%   Detailed explanation goes here

%skt = tcpip('gjoa.med.harvard.edu', 30000, 'NetworkRole', 'client');
skt = tcpip('10.119.96.233', 30000, 'NetworkRole', 'client');
fopen(skt);
flushinput(skt);

end

