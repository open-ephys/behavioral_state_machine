function machine = TransitionStates(machine, from_state, to_state)

%Need to stop analog outputs?
if from_state > 0, %transitioning from another state (not ITI)
    for output_ind = 1:machine.States(from_state).NumAnalogOutput,
        if ((machine.AnalogOutputs(machine.States(from_state).AnalogOutput(output_ind).AOIndex).DAQSession.IsRunning) & ...
                (machine.States(from_state).AnalogOutput(output_ind).ForceStop)),
            machine.AnalogOutputs(machine.States(from_state).AnalogOutput(output_ind).AOIndex).DAQSession.stop;
        end
    end
end

%Transition to new state
machine.CurrentStateID = to_state;
machine.TrialStateExitTimeList{machine.CurrentTrial}(machine.TrialStateCount) = now;

%If ITI or end of trial, just skip rest of the transition
if machine.CurrentStateID <= 0,
    %Update key variables
    machine.TrialStateCount = machine.TrialStateCount + 1;
    machine.TimeEnterState = now; % Time entered current state
    machine.TrialStateList{machine.CurrentTrial}(machine.TrialStateCount) = machine.CurrentStateID;
    machine.TrialStateEnterTimeList{machine.CurrentTrial}(machine.TrialStateCount) = machine.TimeEnterState;
    machine.Interruptable = 1;
    %Still save Vars structure
    machine.StateVarValue(machine.TrialStateCount) = machine.Vars;    
    return; %out of transition
end

%Update name of the current state
machine.CurrentStateName = machine.States(to_state).Name;

% Set up analog outputs
for output_ind = 1:machine.States(to_state).NumAnalogOutput,
    if machine.AnalogOutputs(machine.States(to_state).AnalogOutput(output_ind).AOIndex).DAQSession.IsRunning,
        machine.AnalogOutputs(machine.States(to_state).AnalogOutput(output_ind).AOIndex).DAQSession.stop;
    end
    machine.AnalogOutputs(machine.States(to_state).AnalogOutput(output_ind).AOIndex).DAQSession.queueOutputData(...
        eval(machine.States(to_state).AnalogOutput.Data));
    machine.AnalogOutputs(machine.States(to_state).AnalogOutput(output_ind).AOIndex).DAQSession.prepare();
end

%Start them all as quickly as possible
for output_ind = 1:machine.States(to_state).NumAnalogOutput,
    machine.AnalogOutputs(machine.States(to_state).AnalogOutput(output_ind).AOIndex).DAQSession.startBackground();
end

%Send digital codes (after as they are usually used to timestamp/sync with other systems)
didStrobe = 0; didTrue = 0;
for output_ind = 1:machine.States(to_state).NumDigitalOutput,
    machine.States(to_state).DigitalOutput(output_ind).CurrentData = ...
        eval(machine.States(to_state).DigitalOutput(output_ind).Data);
    putvalue(machine.DigitalOutputs(machine.States(to_state).DigitalOutput(output_ind).DIOIndex).DigitalOutputObject, ...
        machine.States(to_state).DigitalOutput(output_ind).CurrentData(1));
    didStrobe = didStrobe | machine.States(to_state).DigitalOutput(output_ind).doStrobe;
    didTrue = didTrue | machine.States(to_state).DigitalOutput(output_ind).doTrue;
end

%Set trial start time to now
machine.TimeEnterState = now; % Time entered current state
machine.TrialStateCount = machine.TrialStateCount + 1;
machine.TrialStateList{machine.CurrentTrial}(machine.TrialStateCount) = to_state;
machine.TrialStateEnterTimeList{machine.CurrentTrial}(machine.TrialStateCount) = machine.TimeEnterState;
machine.Interruptable = machine.States(to_state).Interruptable;

%Do we need to re-set any strobe bits or monitor any 'true' digital outputs?
while didStrobe | didTrue,
    %Update time in state
    machine.TimeInState = (now - machine.TimeEnterState)*86400000;
    if didStrobe & (machine.TimeInState >= 1),
        %Waited 1 ms, now re-set strobe
        for output_ind = 1:machine.States(to_state).NumDigitalOutput,
            if machine.States(to_state).DigitalOutput(output_ind).doStrobe,
                putvalue(machine.DigitalOutputs(machine.States(to_state).DigitalOutput(output_ind).DIOIndex).DigitalOutputObject, 0);
            end
        end
        didStrobe = 0;
    end
    if didTrue,
        didTrue = 0;
        digi_output_time = max(1, round(machine.TimeInState));
        for output_ind = 1:machine.States(to_state).NumDigitalOutput,
            if machine.States(to_state).DigitalOutput(output_ind).doTrue,
                if (digi_output_time >= length(machine.States(to_state).DigitalOutput(output_ind).CurrentData)),
                    digi_output_time = length(machine.States(to_state).DigitalOutput(output_ind).CurrentData);
                else
                    didTrue = 1;
                end
                putvalue(machine.DigitalOutputs(machine.States(to_state).DigitalOutput(output_ind).DIOIndex).DigitalOutputObject, ...
                    machine.States(to_state).DigitalOutput(output_ind).CurrentData(digi_output_time));
            end
        end
    end
end %did strobe or true?

%Do we need to execute any commands?
for exec_ind = 1:machine.States(to_state).NumExecuteFunction,
    eval(machine.States(to_state).ExecuteFunction(exec_ind).Function);
end

%Save Vars structure at beginning of each state (but after all other commands)
machine.StateVarValue(machine.TrialStateCount) = machine.Vars;