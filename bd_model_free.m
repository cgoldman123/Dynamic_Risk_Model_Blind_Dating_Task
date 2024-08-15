function mf_results = bd_model_free(file)
    subdat = readtable(file);
    
        
    if strcmp(class(subdat.response_time),"cell")
       subdat.response_time = str2double(subdat.response_time);
    end
    main_row_idx = find(strcmp(subdat.trial_type, 'MAIN'));
    subdat = subdat(main_row_idx+1:end, :);


    observations = cell(1,108);
    choices = cell(1,108);
    rts = cell(1,108);
    trials = 107;
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


        observations{1,i+1} = observation_array;
        choices{1,i+1} = state_array;
        rts{1,i+1} = reaction_times;

    end
    
    num_dates = 0;
    num_initial_offers_accepted = 0;
    num_high_offers_accepted = 0;
    initial_offers_total = 0;
    for i=1:length(choices)
        game = choices{i};
        if any(game == 2)
            num_dates = num_dates+1;
        end
        offer = observations{i};
        offer_ended_up_with = offer(end);
        if (offer_ended_up_with ~= 0 && offer_ended_up_with ~= 90)
            num_initial_offers_accepted = num_initial_offers_accepted+1;
            initial_offers_total = initial_offers_total+offer_ended_up_with;
        else
            if offer_ended_up_with==90
                num_high_offers_accepted = num_high_offers_accepted+1;
            end
        end
        
    end
    avg_initial_offer_accepted = initial_offers_total/num_initial_offers_accepted;






    mf_results.num_dates = num_dates;
    mf_results.num_initial_offers_accepted = num_initial_offers_accepted;
    mf_results.num_high_offers_accepted = num_high_offers_accepted;
    mf_results.initial_offer_accepted_average = avg_initial_offer_accepted;

end