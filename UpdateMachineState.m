function machine = UpdateMachineState(machine)

% Update the state of the machine, determine transitions, if needed,
% execute a transition.
%
% Created 6/20/12, TJB

%Define constants
EndState = -1;
ITIState = 0;

%Update timing and cycle length
machine.LastCycleLength = GetSecs - machine.LastCycleTime;
machine.LastCycleTime = GetSecs;
machine.TrialNumCycles = machine.TrialNumCycles + 1;
machine.AverageTrialCycleLength = (machine.AverageTrialCycleLength*(machine.TrialNumCycles-1) + machine.LastCycleLength)/machine.TrialNumCycles;

%If this machine is currently sitting at the 0 state (inter-trial interval)
%and the ITI has gone on long enough, then initialize the trial
if (machine.CurrentStateID == ITIState),
    if (machine.TimeInState <= machine.ITILength),
        return;
    end
          
    %Enter first state
    machine.CurrentStateID = machine.TrialStartState(machine.CurrentTrial);
    machine.CurrentStateName = machine.States(machine.CurrentStateID).Name;
    machine.TimeEnterState = GetSecs; % Time entered current state
    machine.TimeInState = 0;
    machine.TrialStateCount = 1;
    machine.TrialStateEnterTimeList{machine.CurrentTrial} = [machine.TimeEnterState];
    machine.Interruptable = machine.States(machine.CurrentStateID).Interruptable;
    return;
end

%Otherwise we are in a trial -- check transitions
for trans_ind = 1:machine.States(machine.CurrentStateID).NumTransitions,
    if eval(machine.States(machine.CurrentStateID).Transitions(trans_ind).Logic),
        %Transition to new state
        machine.CurrentStateID = eval(machine.States(machine.CurrentStateID).Transitions(trans_ind).ToState);
        machine.TrialStateExitTimeList{machine.CurrentTrial}(machine.TrialStateCount) = GetSecs;
       
        %If ITI or end of trial, just skip rest of the transition
        if machine.CurrentStateID <= 0, 
            machine.TrialStateCount = machine.TrialStateCount + 1;
            machine.TimeEnterState = GetSecs; % Time entered current state
            machine.TrialStateList{machine.CurrentTrial}(machine.TrialStateCount) = machine.CurrentStateID;
            machine.TrialStateEnterTimeList{machine.CurrentTrial}(machine.TrialStateCount) = machine.TimeEnterState;
            machine.Interruptable = 1;
            continue; 
        end
        
        %Update name of the current state
        machine.CurrentStateName = machine.States(machine.CurrentStateID).Name;
        
        % Set up analog outputs
        for output_ind = 1:machine.States(machine.CurrentStateID).NumAnalogOutput,
            if machine.AnalogOutputs(machine.States(machine.CurrentStateID).AnalogOutput(output_ind).AOIndex).DAQSession.IsRunning,
                machine.AnalogOutputs(machine.States(machine.CurrentStateID).AnalogOutput(output_ind).AOIndex).DAQSession.stop;
            end
            machine.AnalogOutputs(machine.States(machine.CurrentStateID).AnalogOutput(output_ind).AOIndex).DAQSession.queueOutputData(...
                eval(machine.States(machine.CurrentStateID).AnalogOutput.Data));
            machine.AnalogOutputs(machine.States(machine.CurrentStateID).AnalogOutput(output_ind).AOIndex).DAQSession.prepare();
        end
        
        %Start them all as quickly as possible
        for output_ind = 1:machine.States(machine.CurrentStateID).NumAnalogOutput,
            machine.AnalogOutputs(machine.States(machine.CurrentStateID).AnalogOutput(output_ind).AOIndex).DAQSession.startBackground();
        end
        
        %Send digital codes (after as they are usually used to
        %timestamp/sync with other systems)
        didStrobe = 0;
        for output_ind = 1:machine.States(machine.CurrentStateID).NumDigitalOutput,
            putvalue(machine.DigitalOutputs(machine.States(machine.CurrentStateID).DigitalOutput(output_ind).DIOIndex).DigitalOutputObject, ...
                eval(machine.States(machine.CurrentStateID).DigitalOutput(output_ind).Function));
            if machine.States(machine.CurrentStateID).DigitalOutput(output_ind).doStrobe,
                putvalue(machine.DigitalOutputs(machine.States(machine.CurrentStateID).DigitalOutput(output_ind).StrobeDIOIndex).DigitalOutputObject, 1);
                didStrobe = 1;
            end
        end
        
        %Set trial start time to now
        machine.TimeEnterState = GetSecs; % Time entered current state
        machine.TrialStateCount = machine.TrialStateCount + 1;
        machine.TrialStateList{machine.CurrentTrial}(machine.TrialStateCount) = machine.CurrentStateID;
        machine.TrialStateEnterTimeList{machine.CurrentTrial}(machine.TrialStateCount) = machine.TimeEnterState;
        machine.Interruptable = machine.States(machine.CurrentStateID).Interruptable;
        
        %Do we need to re-set any strobe bits?
        if didStrobe,
            %Wait 1 ms and re-set strobe
            while (machine.TimeInState <= 1), machine.TimeInState = (GetSecs - machine.TimeEnterState)*1000; end
            for output_ind = 1:machine.States(machine.CurrentStateID).NumDigitalOutput,
                if machine.States(machine.CurrentStateID).DigitalOutput(output_ind).doStrobe,
                    putvalue(machine.DigitalOutputs(machine.States(machine.CurrentStateID).DigitalOutput(output_ind).StrobeDIOIndex).DigitalOutputObject, 0);
                end
            end
        end %did strobe?
        
        
    end %test transition
end %transition loop
