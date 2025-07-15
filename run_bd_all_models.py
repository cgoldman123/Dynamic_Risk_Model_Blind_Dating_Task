import sys, os, re, subprocess

results = sys.argv[1]
study = sys.argv[2] # indicate "local" or "prolific"

if study == "prolific":
    subject_list_path = '/media/labs/rsmith/lab-members/cgoldman/Wellbeing/blind_dating/blind_dating_subject_IDs_prolific.csv'

if study == "local":
    subject_list_path = '/media/labs/rsmith/lab-members/osanchez/wellbeing/blind_dating/blind_dating_subject_IDs_local.csv'


models = [
    {'field': 'p_high_hazard,p_reject_start_ratio,p_reject_ceiling_ratio,date_num_thresh,decision_noise,alone_acceptance', 'dynamic_risk':1},
    {'field': 'p_high_hazard,p_reject_start_ratio,p_reject_ceiling_ratio,date_qual_thresh,decision_noise,alone_acceptance', 'dynamic_risk':1},
    {'field': 'p_high_hazard,p_reject_start_ratio,p_reject_ceiling_ratio,date_num_thresh,date_qual_thresh,decision_noise,alone_acceptance', 'dynamic_risk':1},
    {'field': 'p_high_hazard,p_reject_start_ratio,p_reject_ceiling_ratio,date_num_sensitivity,decision_noise,alone_acceptance', 'dynamic_risk':1}, # winner
    {'field': 'p_high_hazard,p_reject_start_ratio,p_reject_ceiling_ratio,date_qual_sensitivity,decision_noise,alone_acceptance', 'dynamic_risk':1},
    {'field': 'p_high_hazard,p_reject_start_ratio,p_reject_ceiling_ratio,date_num_sensitivity,date_qual_sensitivity,decision_noise,alone_acceptance', 'dynamic_risk':1}, #second
    {'field': 'p_high_hazard,p_reject_start_ratio,p_reject_ceiling_ratio,decision_noise,alone_acceptance', 'dynamic_risk':1},

    {'field': 'p_high_hazard,p_reject_ratio,date_num_thresh,decision_noise,alone_acceptance', 'dynamic_risk':0},
    {'field': 'p_high_hazard,p_reject_ratio,date_qual_thresh,decision_noise,alone_acceptance', 'dynamic_risk':0},
    {'field': 'p_high_hazard,p_reject_ratio,date_num_thresh,date_qual_thresh,decision_noise,alone_acceptance', 'dynamic_risk':0},
    {'field': 'p_high_hazard,p_reject_ratio,date_num_sensitivity,decision_noise,alone_acceptance', 'dynamic_risk':0}, # third best
    {'field': 'p_high_hazard,p_reject_ratio,date_qual_sensitivity,decision_noise,alone_acceptance', 'dynamic_risk':0},
    {'field': 'p_high_hazard,p_reject_ratio,date_num_sensitivity,date_qual_sensitivity,decision_noise,alone_acceptance', 'dynamic_risk':0},
    {'field': 'p_high_hazard,p_reject_ratio,decision_noise,alone_acceptance', 'dynamic_risk':0},

]



if not os.path.exists(results):
    os.makedirs(results)
    print(f"Created results directory {results}")


subjects = []
with open(subject_list_path) as infile:
    next(infile)  # Skip the header line
    for line in infile:
        subjects.append(line.strip())

ssub_path = '/media/labs/rsmith/lab-members/cgoldman/Wellbeing/blind_dating/scripts/run_bd_all_models.ssub'

    
for index, model in enumerate(models, start=1):
    combined_results_dir = os.path.join(results, f"model{index}")
    field = model['field']
    dynamic_risk = model['dynamic_risk']

    if not os.path.exists(f"{combined_results_dir}/logs"):
        os.makedirs(f"{combined_results_dir}/logs")
        print(f"Created results-logs directory {combined_results_dir}/logs")
    
    for subject in subjects:
        
        stdout_name = f"{combined_results_dir}/logs/BD-{subject}-%J.stdout"
        stderr_name = f"{combined_results_dir}/logs/BD-{subject}-%J.stderr"
    
        jobname = f'BD-Model-{index}-fit-{subject}'
        os.system(f"sbatch -J {jobname} -o {stdout_name} -e {stderr_name} {ssub_path} \"{subject}\" \"{combined_results_dir}\" \"{field}\" \"{dynamic_risk}\" \"{study}\"")
    
        print(f"SUBMITTED JOB [{jobname}]")
        
     
        
    ### ORESTES change to save to ORESTES SUB FOLDER
    ###python3 /media/labs/rsmith/lab-members/osanchez/wellbeing/blind_dating/Dynamic_Risk_Model_Blind_Dating_Task/run_bd_all_models.py /media/labs/rsmith/lab-members/osanchez/wellbeing/blind_dating/model_output/Local_fit_7-3-2025 "local"

    ## joblist | grep BD | grep -Po 98.... | xargs -n1 scancel
    