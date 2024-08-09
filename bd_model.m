function [model_output] = bd_model(params, observations, actions)
dbstop if error
% use helper function to load in variable names
get_params(params);


total_trials = 108;




%% dynamic risk component

T=8; % choice number within each game

% setup dynamic risk
% p_reject_start = p_reject_start_ratio * (1 - p_high_hazard);
% p_reject_ceiling = p_reject_ceiling_ratio * (1 - p_high_hazard - p_reject_start);
% 
% 
% for t = 1:T
%     p_high_vec(t) = p_high_hazard;
%     p_alone_vec(t) = p_reject_start + (p_reject_ceiling - p_reject_start)*(log(t)/log(T));
%     p_low_vec(t) = 1 - p_high_vec(t) - p_alone_vec(t);
% end

% stagnant risk
p_high_vec = repmat(p_high_hazard, 1, T);
p_reject = (1-p_high_hazard)*p_reject_ratio;
p_alone_vec = repmat(p_reject, 1, T);
p_low_vec = repmat(1-p_high_hazard-p_reject, 1, T);


 plot([p_high_vec]') % probability that person will get the high offer
 hold on
 plot([p_alone_vec]') % probability that person will get rejected
 hold on
 plot([p_low_vec]') % probability that low offer will still be there

%% dynamic preference component & choice 

% create an array with dates and the percent match they overved or obtained
dates = nan(1,total_trials);
percent_match = nan(1,total_trials);
initial_offer = nan(1,total_trials);
for i = 1:total_trials
    if actions.choice{i}(end) == 1
        dates(i) = 0;
        percent_match(i) = 0;
    elseif actions.choice{i}(end) == 2
        dates(i) = 1;
        percent_match(i) = observations{i}(end)/100;
    end
    initial_offer(i) = observations{i}(1)/100;
end

percent_match_sum = nan(1,total_trials);
for i = 1:length(percent_match)
    if i == 1
        percent_match_sum(i) = percent_match(i);
    else
        percent_match_sum(i) = percent_match_sum(i-1) + percent_match(i);
    end
end

average_percent_match = nan(1,length(percent_match_sum));
for trial = 1:numel(percent_match_sum)
    if trial == 1
        average_percent_match(trial) = percent_match_sum(trial);
    elseif percent_match_sum(trial) == 0
        average_percent_match(trial) = 0;
    else
        average_percent_match(trial) = percent_match_sum(trial)/sum(dates(1:trial) == 1);  
    end
end

trials_left = linspace(total_trials,1,total_trials);
num_dates = nan(1,total_trials);
num_dates(1) = 0;
max_possible_dates = nan(1,total_trials);
max_possible_dates(1) = total_trials;
max_possible_dates_percent = nan(1,total_trials);
max_possible_dates_percent(1) = 1;
date_num_concern = nan(1,total_trials);
date_qual_concern = nan(1,total_trials);
date_num_concern(1) = date_num_thresh;
date_qual_concern(1) = date_qual_thresh;

for trial = 2:numel(dates)
    num_dates(trial) = num_dates(trial-1) + dates(trial-1);
    max_possible_dates(trial) = trials_left(trial) + num_dates(trial);
    max_possible_dates_percent(trial) = max_possible_dates(trial)/total_trials;
    date_num_concern(trial) = date_num_thresh - max_possible_dates_percent(trial);
    date_qual_concern(trial) = date_qual_thresh -average_percent_match(trial);
end

subj_percent_match = nan(total_trials);
for trial = 1:numel(dates)
  subj_percent_match(trial) = initial_offer_scale*initial_offer(trial) + date_num_sensitivity*date_num_concern(trial) - date_qual_sensitivity*date_qual_concern(trial);
   
    if subj_percent_match(trial) > .85
        subj_percent_match(trial) = .85;
    elseif subj_percent_match(trial) < .05
        subj_percent_match(trial) = .05;
    end
        

    
    
    for t = 1:T
        if t ~=T
            EV_wait(t) = .9*p_high_vec(t) + alone_acceptance*p_alone_vec(t) + subj_percent_match(trial)*p_low_vec(t);
            EV_accept(t) = subj_percent_match(trial);
            p_accept(trial,t) = 1/(1+exp((EV_wait(t)-EV_accept(t))/decision_noise));
        else
            EV_wait(t) = alone_acceptance;
            EV_accept(t) = subj_percent_match(trial);
            p_accept(trial,t) = 1/(1+exp((EV_wait(t)-EV_accept(t))/decision_noise));
        end
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
    observation = observations{trial};
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
model_output.subj_date_qual = subj_percent_match;

end

function get_params(params)
    param_names = fieldnames(params);
    for i = 1:length(param_names)
        assignin('caller', param_names{i}, params.(param_names{i}));
    end
end
