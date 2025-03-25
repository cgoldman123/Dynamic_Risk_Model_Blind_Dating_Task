function simmed_output = sim_bd(params,study,plot)

if ispc
    root = 'L:/';
else
    root = '/media/labs/';
end
% read in random file to get initial offer sequence
if strcmp(study,"prolific")
    file = [root 'NPC/DataSink/StimTool_Online/WB_Blind_Dating/blind_dating_5c4ea6cc889752000156dd8e_T1_2024-05-08_12h52.43.170.csv'];
elseif strcmp(study,"local")
    file =  [root 'rsmith/wellbeing/data/raw/sub-BE668/BE668-T0-__BD_R1-_BEH.csv'];
    schedule = readtable([root '/rsmith/wellbeing/tasks/BlindDating/schedules/blind_dating_schedule1.csv']);
    schedule = schedule(schedule.block>0,:);
end

subdat = readtable(file);

main_row_idx = find(strcmp(subdat.trial_type, 'MAIN'));
subdat = subdat(main_row_idx+1:end, :);
    
if strcmp(class(subdat.response_time),"cell")
   subdat.response_time = str2double(subdat.response_time);
end
        

if strcmp(study,"prolific")
    %1x108 struct: choice, observation, reaction time
    for i = 0:107
        %Extract the relevant rows from df for the current trial
        trial_data = subdat(subdat.trial == i, {'response','trial_type', 'result', 'response_time'});
        %Get the initial offer
        initial_offer = str2num(trial_data.response{1});
    
        trial_type = trial_data.trial_type{1};
        split_str = strsplit(trial_type, '_');
    
        observations.obs{1,i+1} = initial_offer;
        observations.trial_length{1,i+1} = str2double(split_str{1});
        
        observations.high_offer_timestep{1,i+1} = str2double(split_str{2}); % timestep when get high offer
        observations.reject_timestep{1,i+1} = str2double(split_str{3}); % timestep when get rejected
        
    end
elseif strcmp(study,"local")
    %1x108 struct: choice, observation, reaction time
    % event code 6 always starts the trial
    trial_start_indices = find(subdat.event_code == 6);
    for i = 1:108
        % get index for the start of the trial (game)
        trial_start_index = trial_start_indices(i);
        % get index for the end of the trial (game)
        if i ==108
            trial_end_index = height(subdat);
        else
           trial_end_index = trial_start_indices(i+1)-1;
        end
        %Extract the relevant rows from df for the current trial
        trial_data = subdat(trial_start_index:trial_end_index, {'response','event_code','trial_type', 'result', 'response_time'});
    
        initial_offer =  schedule.initial_offer(i);
    
        trial_type = trial_data.trial_type{1};
        split_str = strsplit(trial_type, '_');
    
        observations.obs{1,i} = initial_offer;
        observations.trial_length{1,i} = str2double(split_str{1});
        
        if str2double(split_str{2}) == 0
            observations.high_offer_timestep{1,i} = 0;
        else
            observations.high_offer_timestep{1,i} = str2double(split_str{2})+1; % timestep when get high offer
        end

        if str2double(split_str{3}) == 0
            observations.reject_timestep{1,i} = 0;
        else
            observations.reject_timestep{1,i} = str2double(split_str{3})+1; % timestep when get rejected 
        end
          
    end
end

actions = {};

simmed_output = bd_model(params,observations, actions);

if plot
    plot_bd(simmed_output.action_probabilities, simmed_output.observations, simmed_output.actions)
end

end