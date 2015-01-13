function machine = FinalizeTrial(machine),

% Code to execute when trial is finished.
%
% 6/21/12 Created by TJB
machine.TrialEndState(machine.CurrentTrial) = machine.CurrentStateID;
machine.TrialStateExitTimeList{machine.CurrentTrial}(machine.TrialStateCount) = GetSecs;