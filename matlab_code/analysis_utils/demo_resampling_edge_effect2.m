%%% edge effect due to resampling
%%% https://www.mathworks.com/matlabcentral/answers/91767-why-do-i-obtain-edge-effects-or-oscillations-when-using-the-resample-function-to-perform-non-integer
%%% Tatsuo Okubo
%%% 2021-01-26

clear;

%% original method
fs_old = 400; % sampling frequency of the original signal (Hz)
fs_new = 25;   % sampling frequency after resampling (Hz)
T = 1; % [s]

%%
t = 0:1/fs_old:T;       % Time vector
x = t + 100;         % Define a linear sequence
y1 = resample(x, fs_new, fs_old);  % Now resample it
t1 = [0:(length(y1)-1)]*(1/fs_new);  % New time vector

figure(10); clf;
subplot(211)
plot(t, x, 'b.-', t1, y1, 'r.-')
legend('original','resampled', 'location', 'southeast');
legend boxoff
xlim([-0.1 T+0.1])
ylim([0 120])
title('Original')

%% pad values at the end to mitigate the edge effect due to resampling
[y2, t2] = resample_new(x, fs_new, fs_old);

subplot(212)
plot(t, x, 'b.-', t2, y2, 'r.-')
xlim([-0.1 T+0.1])
ylim([0 120])
legend('original','resampled (new)', 'location', 'southeast');
legend boxoff
xlabel('Time (s)')
title('Modified')