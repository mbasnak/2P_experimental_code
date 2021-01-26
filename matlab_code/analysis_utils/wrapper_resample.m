function xx = wrapper_resample(x, Fs_old, Fs_new)
% inputs
% x: original signal
% Fs_old: original sampling frequency
% Fs_new: new sampling frequency
% N: number of points to pad on each end
    
t_old = 0 : (1/Fs_old) : (length(x)-1)/Fs_old;       % time vector
xpad = [repmat(x(1), 1, Fs_old), x, repmat(x(end), 1, Fs_old)];  % add values at both ends

t_before = [-(1/Fs_old)*N : (1/Fs_old) : 0-(1/Fs_old)];
t_after = [t_old(end)+(1/Fs_old) : (1/Fs_old) : t_old(end)+(1/Fs_old)*N];
tpad = [t_before, t_old, t_after];

ypad = resample(xpad, Fs_new, Fs_old);  % now resample it
t2 = (0:(length(ypad)-1))*2/(3*fs1) - 1;  % new time vector

figure
plot(t_old, x, 'b*')

end