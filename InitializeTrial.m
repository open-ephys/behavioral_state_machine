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
machine.LastCycleTime = now;

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
machine.TrialStateList{machine.CurrentTrial} = [machine.TrialStartState(machine.CurrentTrial)];