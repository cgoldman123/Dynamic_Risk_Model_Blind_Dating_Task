function simmed_output = sim_bd(params,plot)

file = 'L:/NPC/DataSink/StimTool_Online/WB_Blind_Dating/blind_dating_5c4ea6cc889752000156dd8e_T1_2024-05-08_12h52.43.170.csv';

subdat = readtable(file);

main_row_idx = find(strcmp(subdat.trial_type, 'MAIN'));
subdat = subdat(main_row_idx+1:end, :);
trials = max(subdat.trial);

    
if strcmp(class(subdat.response_time),"cell")
   subdat.response_time = str2double(subdat.response_time);
end
        

%1x108 struct: choice, observation, reaction time
for i = 0:trials
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

actions = {};

simmed_output = bd_model(params,observations, actions);

if plot
    plot_bd(simmed_output.action_probabilities, simmed_output.observations, simmed_output.actions)
end

end