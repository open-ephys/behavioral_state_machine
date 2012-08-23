function machine = ExecuteTrial(machine)

% Executes a single trial.  Returns after trial finishes
%
% Created 6/21/12 TJB

%Define constants
EndState = -1;
ITIState = 0;

% Initialize trial
machine = InitializeTrial(machine);

% Run cycle
while machine.CurrentStateID ~= EndState,
    
    %Update variables
    %tic;
    machine = UpdateVariables(machine);
    %fprintf('Time to update variables: %5.2f ms.\n', 1000*toc);
        
    %Update state of machine
    %tic;
    machine = UpdateMachineState(machine);
    %fprintf('Time to update state: %5.2f ms.\n', 1000*toc);
    
end %run loop

% End trial
machine = FinalizeTrial(machine);