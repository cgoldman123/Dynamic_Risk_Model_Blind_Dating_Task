function [model_output] = bd_model(params, observations, actions)
dbstop if error
% use helper function to load in variable names
get_params(params);


total_trials = 108;
if isempty(actions)
    sim = true;
else
    sim = false;
end



%% dynamic risk component


%setup dynamic risk
p_reject_start = p_reject_start_ratio * (1 - p_high_hazard);
p_reject_ceiling = p_reject_ceiling_ratio * (1 - p_high_hazard - p_reject_start);

T=4;
for t = 1:T
    p_high_vec_4_choice(t) = p_high_hazard;
    p_alone_vec_4_choice(t) = p_reject_start + (p_reject_ceiling - p_reject_start)*(log(t)/log(T));
    p_low_vec_4_choice(t) = 1 - p_high_vec_4_choice(t) - p_alone_vec_4_choice(t);
end
T=8; % choice number within each game
for t = 1:T
    p_high_vec_8_choice(t) = p_high_hazard;
    p_alone_vec_8_choice(t) = p_reject_start + (p_reject_ceiling - p_reject_start)*(log(t)/log(T));
    p_low_vec_8_choice(t) = 1 - p_high_vec_8_choice(t) - p_alone_vec_8_choice(t);
end


% stagnant risk
% p_high_vec = repmat(p_high_hazard, 1, T);
% p_reject = (1-p_high_hazard)*p_reject_ratio;
% p_alone_vec = repmat(p_reject, 1, T);
% p_low_vec = repmat(1-p_high_hazard-p_reject, 1, T);


%  plot([p_high_vec]') % probability that person will get the high offer
%  hold on
%  plot([p_alone_vec]') % probability that person will get rejected
%  hold on
%  plot([p_low_vec]') % probability that low offer will still be there

%% dynamic preference component & choice 

% create an array with dates and the percent match they overved or obtained
dates = nan(1,total_trials); % indicates if got a date on a particular trial
percent_match = nan(1,total_trials); % indicates percent match if got a date on a particular trial
initial_offer = nan(1,total_trials); % initial offer for that trial
num_dates_scheduled = nan(1,total_trials+1); %indicates number of dates scheduled so far (not including current trial)
num_dates_scheduled(1) = 0;
average_percent_match = nan(1,total_trials+1); %indicates average percent match so far (not including current trial)
average_percent_match(1) = 0;
subj_percent_match = nan(1,total_trials);

% for each trial
for trial = 1:total_trials
    % get initial offer
    initial_offer(trial) = observations.obs{trial}(1)/100;
    
    trials_left = total_trials-trial+1; % trials left including this one

    % get concern for number of dates
    max_possible_dates = trials_left + num_dates_scheduled(trial);
    max_possible_dates_percent = max_possible_dates/total_trials;
    date_num_concern = date_num_thresh - max_possible_dates_percent;
    
    % get concern for quality of dates
    date_qual_concern = date_qual_thresh - average_percent_match(trial);

    % get subjective value of initial offer
    subj_percent_match(trial) = initial_offer_scale*initial_offer(trial) + date_num_sensitivity*date_num_concern - date_qual_sensitivity*date_qual_concern;
   
    % make sure initial offer is never subjectively better than high offer
    if subj_percent_match(trial) > .85
        subj_percent_match(trial) = .85;
    elseif subj_percent_match(trial) < .05
        subj_percent_match(trial) = .05;
    end
    
    % set probability of reject/high offer/low offer probs depending on trial length
    game_length = observations.trial_length{trial};
    % for each time step in a game
    for t = 1:game_length
        if  game_length == 8
            p_high = p_high_vec_8_choice(t);
            p_alone = p_alone_vec_8_choice(t);
            p_low = p_low_vec_8_choice(t);
        else
            p_high = p_high_vec_4_choice(t);
            p_alone = p_alone_vec_4_choice(t);
            p_low = p_low_vec_4_choice(t);
        end

        % get probability of accept/wait for each time step
        if t ~=game_length
            EV_wait(t) = .9*p_high + alone_acceptance*p_alone + subj_percent_match(trial)*p_low;
            EV_accept(t) = subj_percent_match(trial);
            p_accept(trial,t) = 1/(1+exp((EV_wait(t)-EV_accept(t))/decision_noise));
        % get probability of accept/wait for last time step
        else
            EV_wait(t) = alone_acceptance;
            EV_accept(t) = subj_percent_match(trial);
            p_accept(trial,t) = 1/(1+exp((EV_wait(t)-EV_accept(t))/decision_noise));
        end
    end
    
    % GET THE OUTCOME
    if sim
        actions.choice{trial}(1) = 0;
        for t = 1:game_length
            % if reject timstep, break
            if t == observations.reject_timestep{trial}
                break;
            end
            % if high offer timestep
            if t == observations.high_offer_timestep{trial}
                actions.choice{trial}(t+1) = 2; % must accept high offer
                observations.obs{trial}(t+1) = 90;        
                break;
            else
                actions.choice{trial}(t+1) = 1 + (rand(1) <= p_accept(trial,t)); % 2 is accept, 1 is wait
                if actions.choice{trial}(t+1) == 2 % if accepted initial offer
                    observations.obs{trial}(t+1) = initial_offer(trial)*100;
                    break;
                else
                    observations.obs{trial}(t+1) = 0;
                end
            end
            
        end
    end
    
    if actions.choice{trial}(end) == 1 % no date
        dates(trial) = 0;
        percent_match(trial) = 0;
    elseif actions.choice{trial}(end) == 2 % date!
        dates(trial) = 1;
        percent_match(trial) = observations.obs{trial}(end)/100;
    end  
    
    

    % update number/quality of dates gotten so far
    num_dates_scheduled(trial+1) = num_dates_scheduled(trial) + dates(trial);
    % if date, update average percent match so far
    if dates(trial)
        average_percent_match(trial+1) = average_percent_match(trial) + (percent_match(trial)-average_percent_match(trial))/num_dates_scheduled(trial+1);
    else
        average_percent_match(trial+1) = average_percent_match(trial);
    end
    
end


% plot objective vs. subjective preference dynamics
% figure
% plot(subj_percent_match(1:20))
% hold on
% plot(initial_offer(1:20))
% plot(high_offer)


% plot choice probabilities over time in each game
% figure
% for trial = 1:numel(dates)
%     plot(p_accept(trial,:))
%     hold on
% end
action_probabilities = nan(8, total_trials);
%action_probabilities = nan(1, total_trials);
for trial = 1:total_trials
    game = actions.choice{trial};
    observation = observations.obs{trial};
    T = length(game)-1; % number of decisions this person made
    % include all decisions up until last one (don't count decision to
    % accept high offer since it's automatic!
    for t = 1:T
        % if got high offer
        if observation(t+1) == 90
            break;
        end
        did_accept = game(t+1)-1;
        action_probabilities(t, trial) = p_accept(trial, t)*did_accept +  (1-p_accept(trial, t)) * (1-did_accept);
    end

    % only include probability for decision to accept initial offer, decision to wait before getting rejected,
    % decision to wait before receiving high offer, or decision to
    % reject on last time step. Means only looking at action on last time step
%     did_accept = game(end)-1;
%     action_probabilities(trial) = p_accept(trial, T)*did_accept +  (1-p_accept(trial, T)) * (1-did_accept);
end

model_output.action_probabilities = action_probabilities;
model_output.observations = observations;
model_output.actions=actions;
model_output.subj_date_qual = subj_percent_match;
model_output.risk.p_high = p_high_vec_8_choice;
model_output.risk.p_alone = p_alone_vec_8_choice;
model_output.risk.p_low = p_low_vec_8_choice;



end

function get_params(params)
    param_names = fieldnames(params);
    for i = 1:length(param_names)
        assignin('caller', param_names{i}, params.(param_names{i}));
    end
end
