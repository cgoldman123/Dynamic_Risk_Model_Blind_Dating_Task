function [fit_results, fit_DCM, file] = fit_bd_local(subject,DCM)
    dbstop if error;
    if ispc
        root = 'L:/';
        else
        root = '/media/labs/';
    end
    file_path = [root '/rsmith/wellbeing/data/raw/sub-' subject '/'];
   
    has_practice_effects = false;
    % Manipulate Data
    directory = dir(file_path);
    % sort by date
    dates = datetime({directory.date}, 'InputFormat', 'dd-MMM-yyyy HH:mm:ss');
    % Sort the dates and get the sorted indices
    [~, sortedIndices] = sort(dates);
    % Use the sorted indices to sort the structure array
    sortedDirectory = directory(sortedIndices);

    index_array = find(arrayfun(@(n) contains(sortedDirectory(n).name, 'T0-__BD'),1:numel(sortedDirectory)));
    if length(index_array) > 1
        disp("WARNING, MULTIPLE BEHAVIORAL FILES FOUND FOR THIS ID. USING THE FIRST FULL ONE")
    end

    has_complete_file = false;
    for k = 1:length(index_array)
        file_index = index_array(k);
        file = [file_path sortedDirectory(file_index).name];
        subdat = readtable(file);

        main_row_idx = find(strcmp(subdat.trial_type, 'MAIN'));
        if isempty(main_row_idx)
            continue
        end
        subdat = subdat(main_row_idx+1:end, :);
        num_trials = sum(subdat.event_code == 6);
        if num_trials ~= 108
           has_practice_effects = true;
           continue
            
        end
    
        if strcmp(class(subdat.response_time),"cell")
           subdat.response_time = str2double(subdat.response_time);
        end
        
        has_complete_file = true;
        break
    end
    if ~has_complete_file
        error("This subject does not have a complete behavioral file");
    end

    % read in schedule
    schedule = readtable([root '/rsmith/wellbeing/tasks/BlindDating/schedules/blind_dating_schedule1.csv']);
    schedule = schedule(schedule.block>0,:);

    %1x108 struct: choice, observation, reaction time
    % event code 6 always starts the trial
    trial_start_indices = find(subdat.event_code == 6);
    for i = 1:num_trials
        % get index for the start of the trial (game)
        trial_start_index = trial_start_indices(i);
        % get index for the end of the trial (game)
        if i ==num_trials
            trial_end_index = height(subdat);
        else
           trial_end_index = trial_start_indices(i+1)-1;
        end
        %Extract the relevant rows from df for the current trial
        trial_data = subdat(trial_start_index:trial_end_index, {'response','event_code','trial_type', 'result', 'response_time'});

        %Let's build an array of states 

        %0 initial state, 1 not having a date 2 having a date
        % note that reject response means the participant rejected initial
        % offer on last time step
        num_waits = sum(strcmp(trial_data.response,'wait')) + sum(strcmp(trial_data.response,'reject'));
        num_accepts = sum(strcmp(trial_data.response, 'accept'));
        n = 1 + num_waits + num_accepts;
        state_array = nan(n, 1);

        % Assign values
        state_array(1) = 0; % 0 for initial state
        state_array(2:num_waits+1) = 1;  % Fill with 1s for not having a date
        state_array(2+num_waits:end) = 2;  % Fill with 2s for accepting date

        trial_type = trial_data.trial_type{1};
        split_str = strsplit(trial_type, '_');
        % note that everything is shifted from prolific
        
        if split_str{2} == '0'
            high_offer_time = 0; % check for the pressence of high offer in the trial 
        else
            high_offer_time = str2double(split_str{2})+2; % time high offer is given
        end
        if split_str{3} == '0'
            rejection_time = 0;
        else
            rejection_time = str2double(split_str{3})+1; % time rejection happens
        end
        observation_array = nan(n, 1);
        observation_array(1) = schedule.initial_offer(i);

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

        DCM.U.obs{1,i} = observation_array;
        DCM.U.trial_length{1,i} = str2double(split_str{1});
        DCM.Y.choice{1,i} = state_array;
        DCM.Y.rts{1,i} = reaction_times;

    end

    % call the model inversion code
    fit_DCM = bd_inversion(DCM);

    % re-transform parameters back into native space
    field = fit_DCM.field;
    % get fitted and fixed params
    params = fit_DCM.params;
    for i = 1:length(field)
        if ismember(field{i},{'p_high_hazard', 'p_reject_start_ratio', 'p_reject_ceiling_ratio', 'date_qual_thresh','date_num_thresh', 'p_reject_ratio',...
                'p_high_start', 'p_high_ceiling'})
            params.(field{i}) = 1/(1+exp(-fit_DCM.Ep.(field{i})));
        elseif ismember(field{i},{'decision_noise', 'initial_offer_scale'})
            params.(field{i}) = exp(fit_DCM.Ep.(field{i}));
        elseif ismember(field{i},{'alone_acceptance', 'date_num_sensitivity','date_qual_sensitivity'})
            params.(field{i}) = fit_DCM.Ep.(field{i});
        else
            disp(field{i});
            error("Param not propertly transformed");
        end
    end
    
    fit_results.subject = subject;
    fit_results.has_practice_effects = has_practice_effects;
    fit_results.F = fit_DCM.F;
    
    % get final average action probability
    model_output = bd_model(params,DCM.U,DCM.Y);
    
    % plot fit
    plot_bd(model_output.action_probabilities, model_output.observations, model_output.actions, model_output.risk);

    
    %fit_results.average_action_prob = nanmean(model_output.action_probabilities, 'all');
    fit_results.average_action_prob = mean(model_output.action_probabilities(:), 'omitnan');
    % get final model accuracy
    fit_results.model_acc = sum(model_output.action_probabilities(:)' > .5) / sum(~isnan(model_output.action_probabilities(:)'));
    
    % assign priors/posteriors/fixed params to fit_results
    param_names = fieldnames(params);
    for i = 1:length(param_names)
        % param was fitted
        if ismember(param_names{i}, field)
            fit_results.(['posterior_' param_names{i}]) = params.(param_names{i});
            fit_results.(['prior_' param_names{i}]) = fit_DCM.params.(param_names{i});  
        % param was fixed
        else
            fit_results.(['fixed_' param_names{i}]) = params.(param_names{i});
        end
    end

end


