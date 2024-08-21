clear all;
close all;
rng(23);
dbstop if error
FIT = true;
SIM = false;

if ispc
    root = 'L:';
    subject = '5c3c1617f5ebd500018596cb'; % 5c4ea6cc889752000156dd8e 5590a34cfdf99b729d4f69dc 66368ac547b8824e50cfa854 5fadd628cd4e9e1c42dab969 5fc58cd91b53521031a2d369 5fd5381b5807b616d910c586
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
% DCM.params.p_high_start = .25; % bound 0 and 1
% DCM.params.p_high_ceiling = .25; % bound 0 and 1

% dynamic risk
DCM.params.p_reject_start_ratio = .33; % bound 0 and 1
DCM.params.p_reject_ceiling_ratio = .8; % bound 0 and 1
% stagnant risk
%DCM.params.p_reject_ratio = .33;
% DCM.params.date_num_thresh = 1; % bound 0 and 1
% DCM.params.date_qual_thresh = 1; % bound 0 and 1
%DCM.params.date_num_sensitivity = 0; % unbounded
%DCM.params.date_qual_sensitivity = 1; % unbounded
DCM.params.alone_acceptance = 1; % unbounded
DCM.params.decision_noise = 1; % bound positive
DCM.params.initial_offer_scale = 1; % bound positive
DCM.field = {'decision_noise','p_high_hazard','p_reject_start_ratio', 'alone_acceptance', 'initial_offer_scale' };
 
 
if FIT
    [fit_results, fit_DCM, file] = fit_bd(subject, DCM);
    mf_results = bd_model_free(file);
    final_table = [struct2table(fit_results), struct2table(mf_results)];
    if SIM
        simfit_results = simfit_bd(fit_results, fit_DCM);
        final_table = [final_table struct2table(simfit_results)];
    end  
else
    if SIM
        simmed_output = sim_bd(DCM.params);
    end
end



writetable(final_table, [result_dir subject '_blind_dating_fit.csv']);
save([result_dir subject '_blind_dating_fit.mat'], 'fit_DCM');
saveas(gcf, [result_dir subject '_blind_dating_plot.png']);