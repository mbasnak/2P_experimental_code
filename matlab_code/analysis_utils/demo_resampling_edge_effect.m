%%% edge effect due to resampling
%%% https://www.mathworks.com/matlabcentral/answers/91767-why-do-i-obtain-edge-effects-or-oscillations-when-using-the-resample-function-to-perform-non-integer
%%% Tatsuo Okubo
%%% 2021-01-26

%% original method
fs_old = 100;             % Original sampling frequency in Hz
fs_new = 25;
T = 5; % [s]

%%
t_old = 0:1/fs_old:T;       % Time vector
x = t_old + 100;         % Define a linear sequence
y = resample(x, fs_new, fs_old);  % Now resample it
t_new = [0:(length(y)-1)]*(1/fs_new);  % New time vector

figure(10); clf;
subplot(311)
plot(t_old, x, 'b*-', t_new, y, 'r.-')
legend('original','resampled', 'location', 'southeast');
xlabel('Time')
xlim([-1 T+1])
ylim([0 120])
title('Original')

%% pad values at the end to mitigate the edge effect due to resampling
xpad = [repmat(x(1), 1, fs_old), x, repmat(x(end), 1, fs_old)]; % extend by 1s on each side
ypad = resample(xpad, fs_new, fs_old);  % Now resample it
tpad = [0:(length(ypad)-1)]*(1/fs_new) - 1;  % New time vector, shifted by 1s

% remove the edges that were added
t_new = tpad(fs_new+1: length(tpad)-fs_new - 1);
y_new = ypad(fs_new+1: length(ypad)-fs_new - 1);

subplot(312)
plot(t_old, x , 'b*-', tpad, ypad, 'ro')
legend('original','resampled (padded)', 'location', 'southeast');
xlabel('Time')
xlim([-1 T+1])
ylim([0 120])
title('Signal padded on both ends')

subplot(313)
plot(t_old, x , 'b*-', t_new, y_new, 'r.-')
legend('original','resampled (improved)', 'location', 'southeast');
xlabel('Time')
xlim([-1 T+1])
ylim([0 120])
title('Resample and remove the padded signal')

