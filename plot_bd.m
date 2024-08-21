function plot_bd(action_probabilities, observations, actions, risk)

figure;
hold on;

% Set the figure to be as wide as possible
screenSize = get(0, 'ScreenSize'); % Gets the size of your screen
figWidth = screenSize(3) - 50; % Set width close to screen width, leave some margin
figHeight = screenSize(4) - 200; % Set height as per your preference
set(gcf, 'Position', [50, 100, figWidth, figHeight]); % Adjust position and size

% Map actions (1 and 2) to strings ('w' and 'a')
numToCharMap = containers.Map('KeyType', 'double', 'ValueType', 'char');
numToCharMap(1) = 'w';
numToCharMap(2) = 'a';

% Define colors for probabilities
colors = colormap(gray);
colors = flipud(colors);  % Reverse the colormap


% Plot each game
previous_num_choices = nan;
previous_offset = nan;
for game = 1:108
    game_observations = observations.obs{game};
    initial_offer = game_observations(1); % Extract the initial offer for the game
    final_result = game_observations(end); % Extract the final result of the game

    % Calculate stagger position of initial offer based on even/odd game number
    if mod(game, 2) == 0 % Even
        yOffset = .10; % Lower position
    else
        yOffset = .35; % Higher position
    end
    
    % Display the initial offer staggered at the bottom of the plot
    text(game, yOffset, num2str(initial_offer), 'HorizontalAlignment', 'center', ...
         'VerticalAlignment', 'top', 'FontSize', 8, 'Color', 'k');

    num_choices = sum(~isnan(action_probabilities(:,game)));
    % fill in blocks of participant choices
    for choice = 1:num_choices
        % Extract the action probability
        action_prob = action_probabilities(choice, game);
        % Determine the color based on action probability
        color_idx = max(1, round(action_prob * size(colors, 1)));
        % Create a rectangle for the action probability
        rectangle('Position', [game - 0.33, choice - 0.5, 0.7, 1], 'FaceColor', colors(color_idx, :), 'EdgeColor', 'k');
        % Add text for the action type
        game_actions = actions.choice{game};
        text(game, choice, numToCharMap(game_actions(choice+1)), 'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', 'FontSize', 8, 'Color', 'w');
    end
    trial_length = observations.trial_length{game};
    % fill in remaining timesteps
    remaining_timesteps = trial_length - num_choices;
    for i = 1:remaining_timesteps
        % Create a white rectangle above the last choice made
        rectangle('Position', [game - 0.33, num_choices + i - 0.5, 0.7, 1], 'FaceColor', [1, 1, 1], 'EdgeColor', 'k');
        % Add a "-" inside the rectangle
        text(game, num_choices + i, '-', 'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', 'FontSize', 8, 'Color', 'k');
    end
    
    
    if previous_num_choices==trial_length
        if previous_offset == 0 || previous_offset == .10
            result_offset = .35;
        else
            result_offset = .10;
        end
    else
        result_offset = .10;
    end
    if final_result==90
        text(game, trial_length+ 0.5+result_offset, num2str(final_result), 'HorizontalAlignment', 'center', ...
             'VerticalAlignment', 'bottom', 'FontSize', 8, 'Color', [0, 0.5, 0]);
    elseif final_result==0
        text(game, trial_length+ 0.5+result_offset, num2str(final_result), 'HorizontalAlignment', 'center', ...
             'VerticalAlignment', 'bottom', 'FontSize', 8, 'Color', 'r');
    else
        text(game, trial_length+ 0.5+result_offset, num2str(final_result), 'HorizontalAlignment', 'center', ...
             'VerticalAlignment', 'bottom', 'FontSize', 8, 'Color', 'k');
    end
    previous_num_choices = trial_length;
    previous_offset = result_offset;
          
end

% Adjust the axes and labels
xlim([0.5, 108.5]);
ylim([-.75, 10]); % Extend the y-limits to accommodate the staggered initial offer annotations
xlabel('Game Number');
ylabel('Choices');
title('Action Probabilities and Decisions per Game');

% Turn off the y-axis ticks and labels
set(gca, 'YTick', []);
set(gca, 'YTickLabel', []);



figure;
hold on;

% Add markers for each line using the appropriate marker symbols
plot(risk.p_high, '-og', 'MarkerFaceColor', 'g');  % Circle markers for high offer, filled with green
plot(risk.p_alone, '-ob', 'MarkerFaceColor', 'b');  % Circle markers for rejected, filled with blue
plot(risk.p_low, '-ok', 'MarkerFaceColor', 'k');   % Circle markers for low offer, filled with black

legend('High Offer', 'Rejected', 'Low Offer');
xlabel('Choice Number');
ylabel('Probability');
title('Probabilities for T=8');


end
