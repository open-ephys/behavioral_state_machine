%% Defined constants
EarlyResponseEndState = -5;
NoResponseEndState = -4;
IncorrectEndState = -3;
CorrectEndState = -2;
EndState = -1;
ITIState = 0;

%% List of variables that are available to use in function calls
machine_var_list = {};

%Generic variables
machine_var_list{1} = 'CurrentTrial'; % Current trial count
machine_var_list{end+1} = 'MaximumTrials'; % Maximum number of trials
machine_var_list{end+1} = 'LastCycleStartTime'; % Time when the last cycle started
machine_var_list{end+1} = 'LastCycleLength'; % Time (ms) of last cycle length
machine_var_list{end+1} = 'AverageCycleLength'; % Average time to cycle (ms)
machine_var_list{end+1} = 'NumCycles'; % Number of cycles completed
machine_var_list{end+1} = 'BSMVersion'; % Average time to cycle (ms)

%State variables
machine_var_list{end+1} = 'CurrentStateID'; %ID of current state
machine_var_list{end+1} = 'CurrentStateName'; %Name of current state
machine_var_list{end+1} = 'TimeInState'; % Time (ms) in current state
machine_var_list{end+1} = 'TimeEnterState'; % Time (ms) in current state

%Condition variables
machine_var_list{end+1} = 'CurrentCondition'; %Current condition
machine_var_list{end+1} = 'NumConditions'; %Number of conditions
machine_var_list{end+1} = 'FirstCondition'; %Number of conditions

%Trial variables
machine_var_list{end+1} = 'TrialCondition'; %List of conditions used over all of the trials
machine_var_list{end+1} = 'TrialStartState'; %List of what states trials started with
machine_var_list{end+1} = 'TrialEndState'; %List of what states trials ended with (i.e. what transitioned to state -1)
machine_var_list{end+1} = 'TrialStateList'; %List of state sequence for all trials
machine_var_list{end+1} = 'TrialStateEnterTimeList'; %List of times when entering each state for all trials
machine_var_list{end+1} = 'TrialStateExitTimeList'; %List of times when entering each state for all trials
