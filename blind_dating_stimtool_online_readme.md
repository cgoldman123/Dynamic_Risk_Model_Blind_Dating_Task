# Blind Dating Game
Social version of Limited Offer Task

![Thumbnail](/public/js/tasks/blind_dating/thumbnail.png)

# TRIAL STRUCTURE
```

```

# INPUT DETAILS

EACH LINE CODES: one trial
- COLUMN 1: **block** block number
- COLUMN 2: **trial_number** trial number (cha room)
- COLUMN 3: **initial_offer** the initial percent match
- COLUMN 4: **trial_length** either 4 or 8
- COLUMN 5: **ts_high** the trial when the highest match is shown
- COLUMN 6: **ts_withdrawal** the trial when there is no longer the best match
- COLUMN 7: **trial_isi** isi in millisecond

TRIAL ORDER IS: fixed

# OUTPUT DETAILS

```
'INSTRUCT_ONSET': 1,
'TASK_ONSET': 2,
'FIXATION_ONSET': 3,
'QUESTION_RESULT': 4,
'CHOICE_ONSET': 5,
'RESPONSE': 6,
'BLOCK_ONSET': 7,
'FEEDBACK': 8,
'ISI': 9,


INSTRUCT_ONSET (1) (NOT USED)
response_time: not used
response: not used
result: not used

TASK_ONSET (2) (NOT USED)
response_time: not used
response: not used
result: not used

FIXATION_ONSET (3)
response_time: not used
response: not used
result: '+'

QUESTION_RESULT (4) 
response_time: not used
response: not used
result: questions json

CHOICE_ONSET (5)
response_time: not used
response: the initial match percentage
result: total dates so far

RESPONSE (6) (NOT USED)
response_time: response time
response: key clicked
result: timepoint (turn number responsed)

BLOCK_ONSET (7)
response_time: not used.
response: not used
result: not used

FEEDBACK (8)
response_time: not used
response: not used
result: total dates accumlated so far.

ISI (9)
response_time: not used
response: not used
result: isi duration ( from input schedule)

```
