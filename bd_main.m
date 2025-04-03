clear all;
close all;
rng(23);
dbstop if error
FIT = true;
SIM = true;

if ispc
    root = 'L:';
    study = 'local'; % indicate if study is prolific or local
    if strcmp(study,'local')
        subject = 'BW226';
    else
        subject = 'TYLER_TEST'; % 5c4ea6cc889752000156dd8e 5590a34cfdf99b729d4f69dc 66368ac547b8824e50cfa854 5fadd628cd4e9e1c42dab969 5fc58cd91b53521031a2d369 5fd5381b5807b616d910c586
    end
    result_dir = 'L:/rsmith/lab-members/cgoldman/Wellbeing/blind_dating/model_output/';
    % specify fitted and fixed parameter values; note that fieldnames
    % determines which parameters are fitted
    DCM.field = {'decision_noise', 'alone_acceptance', 'p_high_hazard', 'p_reject_start_ratio', 'p_reject_ceiling_ratio'};
    DCM.params.dynamic_risk = 1;
else
    study = getenv('STUDY')
    root = '/media/labs';
    subject = getenv('SUBJECT')
    result_dir = getenv('RESULTS')
    field = strsplit(getenv('FIELD'), ',')
    DCM.field = field;
    dynamic_risk = str2double(getenv('DYNAMIC_RISK'))
    DCM.params.dynamic_risk = dynamic_risk;
end

addpath([root '/rsmith/all-studies/util/spm12/']);
addpath([root '/rsmith/all-studies/util/spm12/toolbox/DEM/']);


if DCM.params.dynamic_risk
    % dynamic risk
    DCM.params.p_reject_start_ratio = 1/3; % bound 0 and 1
    DCM.params.p_reject_ceiling_ratio = .5; % bound 0 and 1
else
    DCM.params.p_reject_ratio = 1/3;
end
DCM.params.p_high_hazard = .25; % bound 0 and 1

if any(contains(DCM.field,'date_num_thresh'))
    DCM.params.date_num_thresh = .5; % bound 0 and 1
else
    DCM.params.date_num_thresh = 1; % bound 0 and 1
end

if any(contains(DCM.field,'date_qual_thresh'))
    DCM.params.date_qual_thresh = .5; % bound 0 and 1
else
    DCM.params.date_qual_thresh = 1; % bound 0 and 1
end

if any(contains(DCM.field,'date_qual_sensitivity'))
    DCM.params.date_qual_sensitivity = 0; % unbounded
else
    if any(contains(DCM.field,'date_qual_thresh'))
        DCM.params.date_qual_sensitivity = 1; 
    else
        DCM.params.date_qual_sensitivity = 0; 
    end
end

if any(contains(DCM.field,'date_num_sensitivity'))
    DCM.params.date_num_sensitivity = 0; % unbounded
else
    if any(contains(DCM.field,'date_num_thresh'))
        DCM.params.date_num_sensitivity = 1; 
    else
        DCM.params.date_num_sensitivity = 0; 
    end
end


DCM.params.alone_acceptance = 0; % unbounded
DCM.params.decision_noise = 1; % bound positive
DCM.params.initial_offer_scale = 1; % bound positive
 
 
if FIT
    if strcmp(study,"prolific")
        [fit_results, fit_DCM, file] = fit_bd_prolific(subject, DCM);
        mf_results = bd_model_free_prolific(file);
    elseif strcmp(study,"local")
        [fit_results, fit_DCM, file] = fit_bd_local(subject, DCM);
        mf_results = bd_model_free_local(file);
    end
    final_table = [struct2table(fit_results), struct2table(mf_results)];
    if SIM
        simfit_results = simfit_bd(fit_results, fit_DCM,study);
        final_table = [final_table struct2table(simfit_results)];
    end  
else
    if SIM
        simmed_output = sim_bd(DCM.params,1);
    end
end



writetable(final_table, [result_dir '/' subject '_blind_dating_fit.csv']);
save([result_dir '/' subject '_blind_dating_fit.mat'], 'fit_DCM');
saveas(gcf, [result_dir '/' subject '_blind_dating_plot.png']);