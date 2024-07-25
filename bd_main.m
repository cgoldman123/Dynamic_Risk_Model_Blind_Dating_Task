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

DCM.estimation_prior.p_high_hazard = .4; % bound 0 and 1
DCM.estimation_prior.p_reject_start_ratio = .8; % bound 0 and 1
DCM.estimation_prior.p_reject_ceiling_ratio = .6; % bound 0 and 1
DCM.estimation_prior.date_num_thresh = 100; % bound positive
DCM.estimation_prior.date_qual_thresh = .4; % bound 0 and 1
DCM.estimation_prior.date_num_sensitivity = 0; 
DCM.estimation_prior.date_qual_sensitivity = 0;
DCM.estimation_prior.alone_acceptance = 0; 
DCM.estimation_prior.decision_noise = 2; % bound positive
DCM.field = fieldnames(DCM.estimation_prior);

[fit_results, fit_DCM, file] = fit_bd(subject, DCM);
mf_results = bd_model_free(file);
fit_results = [struct2table(fit_results), struct2table(mf_results)];

writetable(fit_results, [result_dir subject '_blind_dating_fit.csv']);
save([result_dir subject '_blind_dating_fit.mat'], 'fit_DCM');