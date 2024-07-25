function [fit_results, fit_DCM, file] = fit_bd(subject,DCM)
    dbstop if error;
    if ispc
        root = 'L:/';
        else
        root = '/media/labs/';
    end
    file_path = [root 'NPC/DataSink/StimTool_Online/WB_Blind_Dating/'];
    
    has_practice_effects = false;
    % Manipulate Data
    directory = dir(file_path);
    % sort by date
    dates = datetime({directory.date}, 'InputFormat', 'dd-MMM-yyyy HH:mm:ss');
    % Sort the dates and get the sorted indices
    [~, sortedIndices] = sort(dates);
    % Use the sorted indices to sort the structure array
    sortedDirectory = directory(sortedIndices);

    index_array = find(arrayfun(@(n) contains(sortedDirectory(n).name, strcat('blind_dating_',subject)),1:numel(sortedDirectory)));
    if length(index_array) > 1
        disp("WARNING, MULTIPLE BEHAVIORAL FILES FOUND FOR THIS ID. USING THE FIRST FULL ONE")
    end

    for k = 1:length(index_array)
        file_index = index_array(k);
        file = [file_path sortedDirectory(file_index).name];
        subdat = readtable(file);

        main_row_idx = find(strcmp(subdat.trial_type, 'MAIN'));
        if isempty(main_row_idx)
            continue
        end
        subdat = subdat(main_row_idx+1:end, :);
        trials = max(subdat.trial);
        if subdat.trial(end) ~= 107;
           has_practice_effects = true;
           continue
            
        end
    
        if strcmp(class(subdat.response_time),"cell")
           subdat.response_time = str2double(subdat.response_time);
        end
    end

    %1x108 struct: choice, observation, reaction time

    df_struct = cell(1, 108);
    for i = 0:trials
        %Extract the relevant rows from df for the current trial
        trial_data = subdat(subdat.trial == i, {'response','trial_type', 'result', 'response_time'});

        %Let's build an array of states 

        %0 initial state, 1 not having a date 2 having a date
        num_waits = sum(strcmp(trial_data.response, 'right'));
        num_accepts = sum(strcmp(trial_data.response, 'left'));
        n = 1 + num_waits + num_accepts;
        state_array = nan(n, 1);

        % Assign values
        state_array(1) = 0; % 0 for initial state
        state_array(2:num_waits+1) = 1;  % Fill with 1s for not having a date
        state_array(2+num_waits:end) = 2;  % Fill with 2s for accepting date

        trial_type = trial_data.trial_type{1};
        split_str = strsplit(trial_type, '_');
        high_offer_time = str2double(split_str{2})+1; % time high offer is given
        rejection_time = str2double(split_str{3}); % time rejection happens
        observation_array = nan(n, 1);
        observation_array(1) = str2num(trial_data.response{1});

         if high_offer_time == n % if got high offer
            observation_array(length(observation_array)) = 90;
         elseif any(state_array(end) == 2) % if accepted initial offer
                    observation_array(length(observation_array)) = observation_array(1);
         elseif rejection_time == n % if got rejected
                    observation_array(length(observation_array)) = 0;
         else  %if rejected the initial offer
                    observation_array(length(observation_array)) = 0;
         end

        % reaction time
        reaction_times = nan(n,1);
        reaction_times(2:end) = trial_data.response_time(~isnan(trial_data.response_time));

%             df_struct{1,i+1}.reaction_times = reaction_times;
%             df_struct{1,i+1}.observation_array = observation_array;
%             df_struct{1,i+1}.state_array = state_array;
%             df_struct{1,i+1} =  struct2table(df_struct{1,i+1});

        DCM.U{1,i+1} = observation_array;
        DCM.Y.choice{1,i+1} = state_array;
        DCM.Y.rts{1,i+1} = reaction_times;

    end

    DCM.MDP = nan;
    % call the model inversion code
    fit_DCM = bd_inversion(DCM);

    % re-transform parameters back into native space
    field = fit_DCM.field;
    for i = 1:length(field)
        if ismember(field{i},{'p_high_hazard', 'p_reject_start_ratio', 'p_reject_ceiling_ratio', 'date_qual_thresh'})
            posterior.(field{i}) = 1/(1+exp(-fit_DCM.Ep.(field{i})));
        elseif ismember(field{i},{'date_num_thresh', 'decision_noise'})
            posterior.(field{i}) = exp(fit_DCM.Ep.(field{i}));
        else
            posterior.(field{i}) = fit_DCM.Ep.(field{i});
        end
    end
    
    fit_results.subject = subject;
    fit_results.has_practice_effects = has_practice_effects;
    % get final average action probability
    model_output = bd_model(posterior,DCM.U,DCM.Y);
    fit_results.average_action_prob = nanmean(model_output.action_probabilities, 'all');

    % get final model accuracy
    fit_results.model_acc = sum(model_output.action_probabilities(:)' > .5) / sum(~isnan(model_output.action_probabilities(:)'));
    
    % assign priors/posteriors to fit_results
    for i = 1:length(field)
        fit_results.(['posterior_' field{i}]) = posterior.(field{i});
        fit_results.(['prior_' field{i}]) = DCM.estimation_prior.(field{i});  
    end

end


