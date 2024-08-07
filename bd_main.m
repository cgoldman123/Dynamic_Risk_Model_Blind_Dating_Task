clear all;
rng(23);
dbstop if error
SIMFIT = false;

if ispc
    root = 'L:';
    subject = '5c4ea6cc889752000156dd8e'; % 5c4ea6cc889752000156dd8e 5590a34cfdf99b729d4f69dc
    result_dir = 'L:/rsmith/lab-members/cgoldman/Wellbeing/blind_dating/model_output/';
else
    root = '/media/labs';
    subject = getenv('SUBJECT');
    result_dir = getenv('RESULTS');
end

addpath([root '/rsmith/all-studies/util/spm12/']);
addpath([root '/rsmith/all-studies/util/spm12/toolbox/DEM/']);

% specify fitted and fixed parameter values; note that fieldnames
% determines which parameters are fitted
DCM.params.p_high_hazard = .25; % bound 0 and 1
DCM.params.p_reject_start_ratio = .33; % bound 0 and 1
DCM.params.p_reject_ceiling_ratio = .8; % bound 0 and 1
DCM.params.date_num_thresh = 1; % bound 0 and 1
DCM.params.date_qual_thresh = 1; % bound 0 and 1
DCM.params.date_num_sensitivity = 0; % unbounded
DCM.params.date_qual_sensitivity = 0; % unbounded
DCM.params.alone_acceptance = 0; % unbounded
DCM.params.decision_noise = 2; % bound positive
DCM.field = {'alone_acceptance', 'decision_noise', 'date_num_sensitivity',...
     'date_qual_sensitivity', 'p_high_hazard', 'p_reject_ceiling_ratio' };


[fit_results, fit_DCM, file] = fit_bd(subject, DCM);
mf_results = bd_model_free(file);
fit_results = [struct2table(fit_results), struct2table(mf_results)];

writetable(fit_results, [result_dir subject '_blind_dating_fit.csv']);
save([result_dir subject '_blind_dating_fit.mat'], 'fit_DCM');