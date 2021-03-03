function [y, t] = resample_new(x, fs_new, fs_old)
%% wrapper function around y = resample() in MATLAB to avoid edge effects
%% pad 1 sec of data on each side with the edge value
%% note that the input arguments are slightly different from resample()
%%
%% inputs
%%    x: original signal
%%    fs_new: sampling frequency after the resampling
%%    fs_old: sampling frequency of the original data
%%
%% outputs
%%    y: resampled signal
%%    t: time vector
%%
%% see https://www.mathworks.com/help/signal/ref/resample.html
%% Tatsuo Okubo
%% 2021-01-27

if size(x,1) > size(x, 2)
    x = x';
end
xpad = [repmat(x(1), 1, fs_old), x, repmat(x(end), 1, fs_old)]; % extend by 1s on each side
ypad = resample(xpad, fs_new, fs_old);
tpad = [0:(length(ypad)-1)]*(1/fs_new) - 1;  % new time vector, shifted by 1s

% remove the padding
t = tpad(fs_new+1: length(tpad)-fs_new);
y = ypad(fs_new+1: length(ypad)-fs_new);

end