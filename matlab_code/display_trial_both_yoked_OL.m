function [fwd_histo, ang_histo, fly_pos_histo] = display_trial_both_yoked_OL(sid, tid, run_obj, trial_time, trial_data, session_fig, fwd_histogram, ang_histogram, fly_pos_histogram)
%%% code to plot the results of yoked wind + bar open loop
%%% needs to be a separete file since yaw is recorded on a different NI-DAQ
%%% channel
%%% based on display_trial.m by Melanie Basnak
%%% Tatsuo Okubo
%%% 2021-10-22

settings = nidaq_settings;

%% get fly position and velocity, as well as stim position

x_pixels = 96; %= number of x dimensions in the panels (i.e., 96 pixels for the 360 arena)
[ t, stim_pos_panel_x, stim_pos_panel_y, stim_pos_motor, vel_for, vel_yaw, fly_pos, mfc_monitor] = process_data_both_yoked_OL( trial_time, trial_data, x_pixels); 

%% Display trial results

%Set up data visualization figure
viz_figs.data_fig = figure();
set(viz_figs.data_fig,'Units','inches','Position',[0 0 10 10]);
set(viz_figs.data_fig,'color','w');
viz_figs.info_ax = subtightplot(6,8,[1:8], [.05 .05], [.1, .1], [.1, .1]);
viz_figs.info_ax.Visible = 'Off';
xlim(viz_figs.info_ax, [0 1]);
ylim(viz_figs.info_ax, [0 1]);

%set up text for the figure
viz_figs.text_expname = text( 0, 1, ['Experiment Type: ' char(run_obj.experiment_type)], 'FontSize', 12, 'Interpreter', 'none'); %viz_figs.info_ax as first arg
viz_figs.text_sidtid = text(0, .8, ['Session ID: ' num2str(run_obj.session_id) ' | Trial ID: ' num2str(sid)], 'FontSize', 12);
viz_figs.text_trialtime = text(.4, .6, ['Trial duration: ' num2str(run_obj.trial_t) ' sec | ITI: ' num2str(run_obj.inter_trial_t)], 'FontSize', 12); %same
viz_figs.text_trialtime = text(.4, .8, ['Num trials: ' num2str(run_obj.num_trials)], 'FontSize', 12);
if (strcmp(run_obj.panel_status, 'On') == 1) & (strcmp(run_obj.wind_status, 'On') == 0) 
    viz_figs.text_trialtype = text(.4, 1, ['Panel Mode: ' run_obj.panel_mode] , 'FontSize', 12, 'Interpreter', 'none');
elseif (strcmp(run_obj.panel_status, 'On') == 0) & (strcmp(run_obj.wind_status, 'On') == 1) 
    viz_figs.text_trialtype = text(.4, 1, ['Panel Mode: ' run_obj.wind_mode] , 'FontSize', 12, 'Interpreter', 'none');
elseif (strcmp(run_obj.panel_status, 'On') == 0) & (strcmp(run_obj.wind_status, 'On') == 0) 
    viz_figs.text_trialtype = text(.4, 1, ['Empty trial'] , 'FontSize', 12, 'Interpreter', 'none');
else
    viz_figs.text_trialtype = text(.4, 1, ['Panel Mode: ' run_obj.panel_mode ' | Wind Mode: ' run_obj.wind_mode] , 'FontSize', 12, 'Interpreter', 'none'); %same    
end

%set up axes for the different plots
viz_figs.stim_ax = subtightplot(6,8,[9:13], [.05 .05], [.1, .1], [.1, .1]);
viz_figs.fly_ax = subtightplot(6,8,[17:21], [.05 .05], [.1, .1], [.1, .1]);
viz_figs.fwd_ax = subtightplot(6,8,[25:29], [.05 .05], [.1, .1], [.1, .1]);
viz_figs.ang_ax = subtightplot(6,8,[33:37], [.05 .05], [.1, .1], [.1, .1]);

viz_figs.circular_fly = subplot(6,8,[14:16,22:24],polaraxes); %polaraxes after the coma

viz_figs.fwd_dist_ax = subtightplot(6,8,[30:32], [.05 .05], [.1, .1], [.1, .1]);
viz_figs.ang_dist_ax = subtightplot(6,8,[38:40], [.05 .05], [.1, .1], [.1, .1]);

viz_figs.fly_trajectory = subtightplot(6,8,[43:45], [.1 .05], [.1, .1], [.1, .1]);

%%%%%

%Plot trial results

%Stimulus position
subplot(viz_figs.stim_ax);
plot(t, stim_pos_panel_x, 'c');
hold on
plot(t, stim_pos_motor, 'm');
xlim([0 trial_time(end)]);
set(gca, 'ytick', 0:90:360)
title('Stimulus position');
ylabel('Deg');

yyaxis right
plot(t, mfc_monitor, 'k')
ylabel('Flow (L/min)')

legend('panel_x', 'motor', 'MFC')
legend boxoff

%Fly position
subplot(viz_figs.fly_ax);
plot(t, wrapTo360(360-fly_pos), 'color', [0.2 0.8 0.3]);
title('Ball position');
ylabel('Deg');
ylim([0 360]);
xlim([0 trial_time(end)]);
set(gca, 'ytick', 0:90:360)

% Fwd velocity subplot
subplot(viz_figs.fwd_ax);
plot(t, vel_for, 'color', [0.8 0.6 0.2]);
title('Forward velocity');
ylabel('Forward Velocity (mm/s)');
%ylim([-2 6]);
xlim([0 trial_time(end)]);

% Angular velocity subplot
subplot(viz_figs.ang_ax);
plot(t, vel_yaw, 'color', [0.8 0.2 0.6]);
title('Angular velocity');
ylabel('Angular velocity (deg/s)');
%ylim([-10 10]);
xlabel('Time (s)');
xlim([0 trial_time(end)]);

% Fwd velocity distribution
subplot(viz_figs.fwd_dist_ax)
histogram(vel_for, 'FaceColor', [0.8 0.6 0.2])
ylabel('Counts');
xlabel('Forward velocity (mm/s)');

%Ang vel distribution
subplot(viz_figs.ang_dist_ax)
histogram(vel_yaw, 'FaceColor', [0.8 0.2 0.6])
ylabel('Counts');
xlabel('Angular velocity (deg/s)');

% Polar distribution of fly position
subplot(viz_figs.circular_fly);
polarhistogram(deg2rad(fly_pos), 24);
title('Fly heading distribution');
set(viz_figs.circular_fly, 'ThetaZeroLocation', 'top');
set(viz_figs.circular_fly, 'ThetaDir', 'clockwise');
set(viz_figs.circular_fly, 'ThetaColor', [.5 .5 .5]);
set(viz_figs.circular_fly, 'RTick', []);
g = get(viz_figs.circular_fly, 'OuterPosition');
set(viz_figs.circular_fly, 'OuterPosition', [g(1) g(2) .34 .34]);

%Fly 2d trajectory
subplot(viz_figs.fly_trajectory)
%import posx and posy data from the hdf5 file
hdf5_files = dir(fullfile(run_obj.experiment_ball_dir,'*hdf5'));
for file = length(hdf5_files):-1:1 % start from the most recent files
    % make sure that it has the correct session # and trial ID, and that
    % it's not an arduino log
    if contains(hdf5_files(file).name,['sid_',num2str(run_obj.session_id), '_tid_',num2str(tid+1)]) && ~contains(hdf5_files(file).name, 'arduino')
        hd5f_file_to_read = fullfile(hdf5_files(file).folder,hdf5_files(file).name);
        break
    end
end
posx = h5read(hd5f_file_to_read,'/posx');
posy = h5read(hd5f_file_to_read,'/posy');
time = h5read(hd5f_file_to_read,'/time');
ball_radius = 4.5; %we need to scale the variables by the ball radius for the true position
% if (strcmp(run_obj.experiment_type,'Gain_change')==1) %if it's a gain change experiment
%     gain = h5read(hd5f_file_to_read,'/gain_yaw');
%     scatter(ball_radius*posx,ball_radius*posy,4.5,gain) %color according to the gain
% else
    scatter(ball_radius*posx,ball_radius*posy,4.5,time)
%end
colorbar
title('Fly trajectory');


%% Update the session figure

fwd_histo = [fwd_histogram, vel_for];
ang_histo = [ang_histogram, vel_yaw];
fly_pos_histo = [fly_pos_histogram; fly_pos];

figure(session_fig.data_fig);
% Fwd velocity distribution
subplot(session_fig.fwd_dist_ax)
histogram(fwd_histo, 'FaceColor', [0.8 0.6 0.2])
ylabel('Counts');
xlabel('Forward velocity (mm/s)');

%Ang vel distribution
subplot(session_fig.ang_dist_ax)
histogram(ang_histo, 'FaceColor', [0.8 0.2 0.6])
ylabel('Counts');
xlabel('Angular velocity (deg/s)');

% Polar distribution of fly position
subplot(session_fig.circular_fly);
polarhistogram(deg2rad(fly_pos_histo),24);
title('Fly heading distribution');
set(session_fig.circular_fly, 'ThetaZeroLocation', 'top');
set(session_fig.circular_fly, 'ThetaDir', 'clockwise');
set(session_fig.circular_fly, 'ThetaColor', [.5 .5 .5]);
set(session_fig.circular_fly, 'RTick', []);

% Save viz figures
saveas( viz_figs.data_fig, [run_obj.experiment_ball_dir '\trial_figure_' datestr(now, 'yyyy_mmdd_HH_MM_SS') '_sid_' num2str(run_obj.session_id) '_tid_' num2str(tid) '.fig'] );

end