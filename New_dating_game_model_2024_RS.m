clear 
close all

%% dynamic risk component

T=8; % choice number within each game

% risk parameters
p_high_hazard = .5; % higher = greater starting prob of high match (then drops)
p_alone_hazard = .3; % higher = greater starting prob of rejection (then rises)

% Note: probability of low match waiting decreases over time

% setup dynamic risk
for t = 1:T
    p_high_vec(t) = (1 - (1 - p_high_hazard)^(1/T));
    p_alone_vec(t) =(1 - (1 - p_alone_hazard).^t);
    
    p_low(t) = (1 - p_high_vec(t) + p_high_vec(t)*p_alone_vec(t) - p_alone_vec(t));
    p_high(t) = p_high_vec(t)*(1 - p_alone_vec(t));
    p_alone(t) = p_alone_vec(t);
end

% plot([p_low]')
% figure
% plot([p_high]')
% figure
% plot([p_alone]')

%% dynamic preference component & choice 

% arbitrary outcome sequence for testing
total_trials = 100;
dates = [ones(total_trials*2/4,1)' zeros(total_trials*1/4,1)' zeros(total_trials*1/4,1)'];
percent_match = [ones(total_trials*1/4,1)'*.3 ones(total_trials*1/4,1)'*.6 ones(total_trials*1/4,1)'*.4 ones(total_trials*1/4,1)'*.7];

% preference parameters
number_dates_sensitivity = 0.3;
average_percent_match_sensitivity = 0.3;

number_dates_concern_threshold = .8; % lowest percentage max possible dates that's  ok
average_percent_match_concern_threshold = .5; % lowest average percent match that's ok


% choice parameters
alone_acceptance = average_percent_match_concern_threshold; % minimum match percentage that's ok
decision_noise = .5;

% setup
average_percent_match = [];
for trial = 1:numel(percent_match)
    average_percent_match(trial) = mean(percent_match(1:trial));
end

trials_left = linspace(total_trials,1,total_trials);

num_dates = [];
num_dates_total = [];
max_possible_dates = [];
max_possible_dates_percent = [];
subjective_percent_match = [];

num_dates(1) = 0;
num_dates_total(1) = 0;
trials_left(1) = total_trials;
max_possible_dates(1) = total_trials;
max_possible_dates_percent(1) = 1;

for trial = 2:numel(dates)
    num_dates(trial) = num_dates(trial-1) + dates(trial-1);
    max_possible_dates(trial) = trials_left(trial) + num_dates(trial);
    max_possible_dates_percent(trial) = max_possible_dates(trial)/total_trials;
    number_dates_concern(trial) = (1-max_possible_dates_percent(trial))-(1-number_dates_concern_threshold);
    average_percent_match_concern(trial) = (1-average_percent_match(trial))-(1-average_percent_match_concern_threshold);
end

for trial = 1:numel(dates)
  subjective_percent_match(trial) = percent_match(trial) + number_dates_sensitivity*number_dates_concern(trial) - average_percent_match_sensitivity*average_percent_match_concern(trial);
   
    if subjective_percent_match(trial) > .85
        subjective_percent_match(trial) = .85;
    elseif subjective_percent_match(trial) < .05
        subjective_percent_match(trial) = .05;
    end
            
    high_offer(trial) = .9; % just included for plotting below

    for t = 1:T
        if t ~=T
            EV_wait(t) = .9*p_high(t) + alone_acceptance*p_alone(t) + subjective_percent_match(trial)*p_low(t);
            EV_accept(t) = subjective_percent_match(trial);
            p_accept(trial,t) = 1/(1+exp((EV_wait(t)-EV_accept(t))/decision_noise));
        else
            EV_wait(t) = alone_acceptance;
            EV_accept(t) = subjective_percent_match(trial);
            p_accept(trial,t) = 1/(1+exp((EV_wait(t)-EV_accept(t))/decision_noise));
        end
    end

end

% plot objective vs. subjective preference dynamics
figure
plot(subjective_percent_match)
hold on
plot(percent_match)
plot(high_offer)


% plot choice probabilities over time in each game
figure
for trial = 1:numel(dates)
    plot(p_accept(trial,:))
    hold on
end




