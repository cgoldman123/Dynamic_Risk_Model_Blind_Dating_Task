function simfit_results = simfit_bd(fit_results, fit_DCM, study)
    % simulate behavior
    params = fit_DCM.params;
    field_names = fieldnames(fit_results); % Get the fieldnames once
    for i = 1:length(field_names)
        if contains(field_names{i}, 'posterior_')
            % Extract the part of the fieldname after 'posterior_' and
            % assign to params
            param_name = strrep(field_names{i}, 'posterior_', '');
            params.(param_name) = fit_results.(field_names{i});
        end
    end
    simmed_output = sim_bd(params,study,0);
    
    % fit simulated behavior
    simmed_DCM.field = fit_DCM.field; 
    simmed_DCM.U = simmed_output.observations;
    simmed_DCM.Y = simmed_output.actions;
    simmed_DCM.params = fit_DCM.params; % estimation priors

    % call the model inversion code
    simfit_DCM = bd_inversion(simmed_DCM);

    % re-transform parameters back into native space
    field = simmed_DCM.field;
    % get fitted and fixed params
    params = simfit_DCM.params;
    for i = 1:length(field)
        if ismember(field{i},{'p_high_hazard', 'p_reject_start_ratio', 'p_reject_ceiling_ratio', 'date_qual_thresh','date_num_thresh', 'p_reject_ratio'})
            params.(field{i}) = 1/(1+exp(-simfit_DCM.Ep.(field{i})));
        elseif ismember(field{i},{'decision_noise', 'initial_offer_scale'})
            params.(field{i}) = exp(simfit_DCM.Ep.(field{i}));
        elseif ismember(field{i},{'alone_acceptance', 'date_num_sensitivity','date_qual_sensitivity'})
            params.(field{i}) = simfit_DCM.Ep.(field{i});
        else
            disp(field{i});
            error("Should have transformed a parameter or indicated that don't need to transform");
        end
    end
    
    % get final average action probability
    model_output = bd_model(params,simmed_DCM.U,simmed_DCM.Y);
    
    simfit_results.simfit_average_action_prob = nanmean(model_output.action_probabilities, 'all');

    % get final model accuracy
    simfit_results.simfit_model_acc = sum(model_output.action_probabilities(:)' > .5) / sum(~isnan(model_output.action_probabilities(:)'));
    
    % assign priors/posteriors/fixed params to fit_results
    param_names = fieldnames(params);
    for i = 1:length(param_names)
        % param was fitted
        if ismember(param_names{i}, field)
            simfit_results.(['simfit_posterior_' param_names{i}]) = params.(param_names{i});
            simfit_results.(['simfit_prior_' param_names{i}]) = simfit_DCM.params.(param_names{i});  
        % param was fixed
        else
            simfit_results.(['simfit_fixed_' param_names{i}]) = params.(param_names{i});
    
        end
    end
    
   

end



