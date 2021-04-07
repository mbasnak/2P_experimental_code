[1mdiff --git a/matlab_code/display_trial.m b/matlab_code/display_trial.m[m
[1mindex ee2d0a1..671f87c 100644[m
[1m--- a/matlab_code/display_trial.m[m
[1m+++ b/matlab_code/display_trial.m[m
[36m@@ -110,26 +110,26 @@[m [mg = get(viz_figs.circular_fly, 'OuterPosition');[m
 set(viz_figs.circular_fly, 'OuterPosition', [g(1) g(2) .34 .34]);[m
 [m
 %Fly 2d trajectory[m
[31m-subplot(viz_figs.fly_trajectory)[m
[31m-%import posx and posy data from the hdf5 file[m
[31m-hdf5_files = dir(fullfile(run_obj.experiment_ball_dir,'*hdf5'));[m
[31m-for file = 1:length(hdf5_files)[m
[31m-    if contains(hdf5_files(file).name,['sid_',num2str(sid)])[m
[31m-        hd5f_file_to_read = fullfile(hdf5_files(file).folder,hdf5_files(file).name);[m
[31m-    end[m
[31m-end[m
[31m-posx = h5read(hd5f_file_to_read,'/posx');[m
[31m-posy = h5read(hd5f_file_to_read,'/posy');[m
[31m-time = h5read(hd5f_file_to_read,'/time');[m
[31m-ball_radius = 4.5; %we need to scale the variables by the ball radius for the true position[m
[31m-% if (strcmp(run_obj.experiment_type,'Gain_change')==1) %if it's a gain change experiment[m
[31m-%     gain = h5read(hd5f_file_to_read,'/gain_yaw');[m
[31m-%     scatter(ball_radius*posx,ball_radius*posy,4.5,gain) %color according to the gain[m
[31m-% else[m
[31m-    scatter(ball_radius*posx,ball_radius*posy,4.5,time)[m
[31m-%end[m
[31m-colorbar[m
[31m-title('Fly trajectory');[m
[32m+[m[32m% subplot(viz_figs.fly_trajectory)[m
[32m+[m[32m% %import posx and posy data from the hdf5 file[m
[32m+[m[32m% hdf5_files = dir(fullfile(run_obj.experiment_ball_dir,'*hdf5'));[m
[32m+[m[32m% for file = 1:length(hdf5_files)[m
[32m+[m[32m%     if contains(hdf5_files(file).name,['sid_',num2str(sid)])[m
[32m+[m[32m%         hd5f_file_to_read = fullfile(hdf5_files(file).folder,hdf5_files(file).name);[m
[32m+[m[32m%     end[m
[32m+[m[32m% end[m
[32m+[m[32m% posx = h5read(hd5f_file_to_read,'/posx');[m
[32m+[m[32m% posy = h5read(hd5f_file_to_read,'/posy');[m
[32m+[m[32m% time = h5read(hd5f_file_to_read,'/time');[m
[32m+[m[32m% ball_radius = 4.5; %we need to scale the variables by the ball radius for the true position[m
[32m+[m[32m% % if (strcmp(run_obj.experiment_type,'Gain_change')==1) %if it's a gain change experiment[m
[32m+[m[32m% %     gain = h5read(hd5f_file_to_read,'/gain_yaw');[m
[32m+[m[32m% %     scatter(ball_radius*posx,ball_radius*posy,4.5,gain) %color according to the gain[m
[32m+[m[32m% % else[m
[32m+[m[32m%     scatter(ball_radius*posx,ball_radius*posy,4.5,time)[m
[32m+[m[32m% %end[m
[32m+[m[32m% colorbar[m
[32m+[m[32m% title('Fly trajectory');[m
 [m
 [m
 %% Update the session figure[m
[1mdiff --git a/matlab_code/display_trial_both.m b/matlab_code/display_trial_both.m[m
[1mindex a7ceaea..c7dccbf 100644[m
[1m--- a/matlab_code/display_trial_both.m[m
[1m+++ b/matlab_code/display_trial_both.m[m
[36m@@ -61,6 +61,7 @@[m [mhold on[m
 plot(t, stim_pos_motor, 'm');[m
 ylim([0 360]);[m
 xlim([0 trial_time(end)]);[m
[32m+[m[32mset(gca, 'ytick', 0:90:360)[m
 title('Stimulus position');[m
 legend('panels', 'motor')[m
 legend boxoff[m
[36m@@ -73,6 +74,7 @@[m [mtitle('Fly position');[m
 ylabel('Deg');[m
 ylim([0 360]);[m
 xlim([0 trial_time(end)]);[m
[32m+[m[32mset(gca, 'ytick', 0:90:360)[m
 [m
 % Fwd velocity subplot[m
 subplot(viz_figs.fwd_ax);[m
[1mdiff --git a/matlab_code/test_olfactometer_closed_loop_wind.m b/matlab_code/test_olfactometer_closed_loop_wind.m[m
[1mindex b8a745d..ad5a623 100644[m
[1m--- a/matlab_code/test_olfactometer_closed_loop_wind.m[m
[1m+++ b/matlab_code/test_olfactometer_closed_loop_wind.m[m
[36m@@ -1,7 +1,7 @@[m
 %%% function test_olfactometer_closed_loop_wind(PulseDur, N_repeat)[m
 %%% test the pinch valve used for closed-loop wind device[m
 %%% INPUTS:[m
[31m-%%%     PulseDur: duration of the pulse in sec[m
[32m+[m[32m%%%     PulseDur:                                                                                                                                                                                                                                                                                                                                                                                                                                                                           duration of the pulse in sec[m
 %%%     N_repeat: number of repeats[m
 %%% OUTPUTS:[m
 %%%     None[m
[36m@@ -14,8 +14,8 @@[m [mFs = 4000;  % sampling rate (Hz)[m
 PreDur = 1; % (s)[m
 PostDur = 1; % (s)[m
 [m
[31m-PulseDur = 1; %[s][m
[31m-N_repeat = 3;[m
[32m+[m[32mPulseDur = 30; %[s][m
[32m+[m[32mN_repeat = 1;[m
 [m
 %% setup DAQ[m
 daqreset[m
