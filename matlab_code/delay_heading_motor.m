%%% calculating the delay between fly heading and the motor position
%%% Tatsuo Okubo
%%% 2021-01-26


DirName = 'C:\Users\Tots\Documents\test\20210126_test\ball';
cd(DirName)
fileName = 'hdf5_Spontaneous_walking_Closed-loop_20210126_141501_sid_8_tid_1.hdf5';
t = h5read(fileName, '/time');
h = h5read(fileName, '/heading');
m = h5read(fileName, '/motor');

% remove the initial transient
t_range = [2, 16]; % [s]
idx = t_range(1) < t & t < t_range(2);
tt = t(idx);
hh = h(idx);
mm = m(idx);

figure(20); clf;
plot(tt, hh, 'b.-')
hold on
plot(tt, mm, 'r.-')

%% unwrap the phase
hhh = unwrap(hh);
mmm = unwrap(mm);

figure(21); clf;
plot(tt, hhh, 'b.-')
hold on
plot(tt, mmm, 'r.-')

%% lag cross-correlation
[c, lags] = xcov(hhh, mmm, 10, 'normalized');
figure(22); clf;
stem(lags, c)
line([0, 0], ylim, 'color', 'r', 'linestyle', ':')
zoom xon

