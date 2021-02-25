function [next_session_id] = begin_trials( run_obj)

%Get the number of trials
task_cnt = run_obj.num_trials;
session_id = run_obj.session_id;

%Connect tok scanimage if using the 2P
scanimage_client_skt = '';
if(run_obj.using_2p == 1)
    scanimage_client_skt = connect_to_scanimage();
    disp(['Connected to scanimage server on socket.']);
end

%pre-allocate across-trials figure
session_fig.data_fig = figure();
set(session_fig.data_fig,'Units','inches','Position',[0 0 10 10]);
set(session_fig.data_fig,'color','w');
session_fig.info_ax = subtightplot(5,4,[1:4], [.05 .05], [.1, .1], [.1, .1]);
session_fig.info_ax.Visible = 'Off';
xlim(session_fig.info_ax, [0 1]);
ylim(session_fig.info_ax, [0 1]);
%add figure title as text
session_fig.title = text( 0.35, 1, ['Figure for session # ' char(run_obj.session_id)], 'FontSize', 18);
session_fig.text_expname = text( 0, 0.2, ['Experiment Name: ' char(run_obj.experiment_type)], 'FontSize', 12, 'Interpreter', 'none'); %session_fig.info_ax as first arg
session_fig.text_sidtid = text(0, 0, ['Session ID: ' num2str(run_obj.session_id)], 'FontSize', 12); %same
session_fig.text_trialtime = text(.5, 0.2, ['Trial time: ' num2str(run_obj.trial_t) ' sec | ITI: ' num2str(run_obj.inter_trial_t)], 'FontSize', 12); %same
session_fig.text_trialtime = text(.5, 0, ['Num trials: ' num2str(run_obj.num_trials)], 'FontSize', 12); %same
session_fig.fwd_dist_ax = subtightplot(5,4,[5:6,9:10], [.1 .1], [.1, .1], [.1, .1]);
session_fig.ang_dist_ax = subtightplot(5,4,[13:14,17:18], [.1 .1], [.1, .1], [.1, .1]);
session_fig.circular_fly = subplot(5,4,[7:8,11:12,15:16,19:20],polaraxes);
%pre-allocate data structures that will be updates with each trial for the
%figures
fwd_histogram = [];
ang_histogram = [];
fly_pos_histogram = [];

% Make run_object folder
if(~exist([run_obj.experiment_ball_dir '\runobj\'], 'dir'))
    mkdir([run_obj.experiment_ball_dir '\runobj\']);
end

% Save run_obj first
save([run_obj.experiment_ball_dir '\runobj\' datestr(now, 'yyyy_mmdd_HH_MM_SS') '_sid_' num2str(session_id) '_runobj.mat'], 'run_obj');

%%%%
% For each trial:
for i = 1:task_cnt
    
    %If only running panels
    if (strcmp(run_obj.panel_status, 'On') == 1) && (strcmp(run_obj.wind_status, 'On') == 0)       
        cur_task = run_obj.panel_mode;
        cur_trial_corename = ['panels_' cur_task '_' datestr(now, 'yyyymmdd_HHMMSS') '_sid_' num2str(session_id) '_tid_' num2str(i-1)];
        %Call the function to run the trial
        [trial_bdata, trial_time] = run_panels_trial(i, cur_task, run_obj, scanimage_client_skt, cur_trial_corename );
        [fwd_histogram, ang_histogram, fly_pos_histogram] = display_trial(session_id, i-1, run_obj, trial_time, trial_bdata, session_fig,fwd_histogram, ang_histogram, fly_pos_histogram);
        
    %If only running wind (this need to be changed)
    elseif (strcmp(run_obj.panel_status, 'On') == 0) && (strcmp(run_obj.wind_status, 'On') == 1)        
        cur_task = run_obj.wind_mode;
        cur_trial_corename = ['wind_' cur_task '_' datestr(now, 'yyyymmdd_HHMMSS') '_sid_' num2str(session_id) '_tid_' num2str(i-1)];
        [trial_bdata, trial_time] = run_wind_trial(i, cur_task, run_obj, scanimage_client_skt, cur_trial_corename );
        [fwd_histogram, ang_histogram, fly_pos_histogram] = display_trial(session_id, i-1, run_obj, trial_time, trial_bdata, session_fig,fwd_histogram, ang_histogram, fly_pos_histogram);
        
    %If running both
    elseif (strcmp(run_obj.panel_status, 'On') == 1) && (strcmp(run_obj.wind_status, 'On') == 1)  
        cur_task = ['panels_' run_obj.panels_mode '_wind_' run_obj.wind_mode];
        cur_trial_corename = [cur_task '_' datestr(now, 'yyyymmdd_HHMMSS') '_sid_' num2str(session_id) '_tid_' num2str(i-1)];
    
    %if not using the panels or the wind
    elseif (strcmp(run_obj.panel_status, 'On') == 0) && (strcmp(run_obj.wind_status, 'On') == 0)  
        cur_task = 'empty_trial';
        cur_trial_corename = ['panels_' cur_task '_' datestr(now, 'yyyymmdd_HHMMSS') '_sid_' num2str(session_id) '_tid_' num2str(i-1)];
        %Call the function to run the trial
        [trial_bdata, trial_time] = run_empty_trial(i, cur_task, run_obj, scanimage_client_skt, cur_trial_corename );
        [fwd_histogram, ang_histogram, fly_pos_histogram] = display_trial(session_id, i-1, run_obj, trial_time, trial_bdata, session_fig,fwd_histogram, ang_histogram, fly_pos_histogram);
        
        %     % nether panels or wind is turned on
%     else
%         error('Turn on panels or wind!')
       
        %If running both
    else
        cur_task = ['panels_' run_obj.panels_mode '_wind_' run_obj.wind_mode];
        cur_trial_corename = [cur_task '_' datestr(now, 'yyyymmdd_HHMMSS') '_sid_' num2str(session_id) '_tid_' num2str(i-1)];
    end
    
    % Save data
    cur_trial_file_name = [ run_obj.experiment_ball_dir '\bdata_' cur_trial_corename '.mat' ];
    save(cur_trial_file_name, 'trial_bdata', 'trial_time')
    
    % wait for an inter-trial period
    if( i < task_cnt )
        disp(['Finished with trial: ' num2str(i-1) '. Waiting for ' num2str(run_obj.inter_trial_t) ' seconds till next trial']);
        pause(run_obj.inter_trial_t);
    end
    
end

%If imaging, closed the connection to scanimage
if(run_obj.using_2p == 1)
    fprintf(scanimage_client_skt, 'END_OF_SESSION');
    fclose(scanimage_client_skt);
end

%If using the panels, turn them off
if (strcmp(run_obj.panel_status, 'On') == 1)
    Panel_com('all_off');
end

% Update session id
next_session_id = session_id+1;

% Save session figure
saveas(session_fig.data_fig, [run_obj.experiment_ball_dir '\session_figure_' datestr(now, 'yyyy_mmdd_HH_MM_SS') '_sid_' num2str(run_obj.session_id) '.fig'] );


disp('Trials complete.');

end
