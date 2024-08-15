import sys, os, re, subprocess, time

results = sys.argv[1]
subject_list_path = '/media/labs/rsmith/lab-members/cgoldman/Wellbeing/blind_dating/blind_dating_subject_IDs_prolific.csv'

if not os.path.exists(results):
    os.makedirs(results)
    print(f"Created results directory {results}")

if not os.path.exists(f"{results}/logs"):
    os.makedirs(f"{results}/logs")
    print(f"Created results-logs directory {results}/logs")


subjects = []
with open(subject_list_path) as infile:
    for line in infile:
        if 'ID' not in line:
            subjects.append(line.strip())



ssub_path = '/media/labs/rsmith/lab-members/cgoldman/Wellbeing/blind_dating/scripts/run_bd.ssub'
for subject in subjects:
    stdout_name = f"{results}/logs/{subject}-%J.stdout"
    stderr_name = f"{results}/logs/{subject}-%J.stderr"

    jobname = f'BD-fit-{subject}'
    os.system(f"sbatch -J {jobname} -o {stdout_name} -e {stderr_name} {ssub_path} {results} {subject}")

    print(f"SUBMITTED JOB [{jobname}]")
    

    


###python3 /media/labs/rsmith/lab-members/cgoldman/Wellbeing/blind_dating/scripts/run_bd.py /media/labs/rsmith/lab-members/cgoldman/Wellbeing/blind_dating/model_output/prolific_model_output/BD_prolific_fit_no_concern_stagnant_risk_8-8-24/