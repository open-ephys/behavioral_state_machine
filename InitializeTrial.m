function machine = InitializeTrial(machine)

% Initializes the machine for starting a new trial
%
% Written 6/20/12 by TJB

machine.Active = 1;
machine.CurrentTrial = machine.CurrentTrial + 1;
machine.TimeEnterState = now;
machine.TimeInState = 0;
machine.CurrentStateID = 0;
machine.TrialNumCycles = 0;
machine.AverageTrialCycleLength = 0;
machine.MaxTrialCycleLength = 0;
machine.MinTrialCycleLength = Inf;
machine.LastCycleTime = now;
machine.TrialStateCount = 0;

%Pick current condition
if machine.CurrentTrial == 1,
    if isempty(machine.FirstCondition),
        machine.TrialCondition = 1;
    else
        machine.TrialCondition = eval(machine.FirstCondition);
    end
else
    if ~isempty(machine.ChooseNextCondition.Logic),
        machine.TrialCondition(machine.CurrentTrial) = eval(machine.ChooseNextCondition.Logic);
    else
        machine.TrialCondition(machine.CurrentTrial) = machine.TrialCondition(machine.CurrentTrial-1);
    end
end
machine.TrialCondition(machine.CurrentTrial) = min(max(1, machine.TrialCondition(machine.CurrentTrial)), machine.NumConditions);
machine.CurrentCondition = machine.TrialCondition(machine.CurrentTrial);

%Choose start state
if isempty(machine.ChooseStartState.Logic),
    machine.TrialStartState(machine.CurrentTrial) = 1;
else
    machine.TrialStartState(machine.CurrentTrial) = eval(machine.ChooseStartState.Logic);
end

%Initialize trial variables
machine.TrialStateList{machine.CurrentTrial} = [0];
machine.TrialStateEnterTimeList{machine.CurrentTrial} = now;
machine.TrialStateCount = 1;

% Loop through condition variables, update them for this trial -- NOTE THESE WILL BE CONSTANT THROUGOUT THE TRIAL
for i = 1:machine.NumConditionVars,
    machine.Vars.(machine.ConditionVars(i).Name) = eval(machine.ConditionVars(i).Function);
end
machine.StateVarValue = struct(machine.Vars);