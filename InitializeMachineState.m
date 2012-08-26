function machine = InitializeMachineState(machine),

% Initializes the state of the machine.
%
% Written 6/20/12 by TJB

machine.Active = 1;
machine.CurrentTrial = 0;
machine.StartTime = now;
machine.TimeEnterState = now;
machine.TimeInState = 0;
machine.CurrentStateID = 0;
machine.TrialNumCycles = 0;
machine.AverageTrialCycleLength = 0;
machine.MinTrialCycleLength = Inf;
machine.MaxTrialCycleLength = 0;
machine.LastCycleTime = now;
machine.LastCycleLength = NaN;

machine.TrialCondition = [];
machine.TrialStartState = [];
machine.TrialEndState = [];
machine.TrialStateList = {};
machine.TrialStateEnterTimeList = {};
machine.TrialStateExitTimeList = {};