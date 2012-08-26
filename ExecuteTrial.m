function machine = ExecuteTrial(machine)

% Executes a single trial.  Returns after trial finishes
%
% Created 6/21/12 TJB

%Define constants
EarlyResponseEndState = -5;
NoResponseEndState = -4;
IncorrectEndState = -3;
CorrectEndState = -2;
EndState = -1;
ITIState = 0;

% Initialize trial
machine = InitializeTrial(machine);

% Run cycle until we reach an end state (which are always negative)
while machine.CurrentStateID > EndState,
    
    % Update cycle count
    machine.TrialNumCycles = machine.TrialNumCycles + 1;
    
    %% Update variables
    % Loop through analog input variables
    for i = 1:machine.NumInputDAQSession,
        x = machine.InputDAQSession(i).inputSingleScan; ts = now;
        matching_vars = find([machine.AnalogInputs(:).MatchingSource] == i);
        for j = 1:length(matching_vars),
            cur_ind = matching_vars(j);
            machine.Vars.(machine.AnalogInputs(cur_ind).Name)(2:machine.AnalogInputs(cur_ind).KeepSamples, :) = ...
                machine.Vars.(machine.AnalogInputs(cur_ind).Name)(1:(machine.AnalogInputs(cur_ind).KeepSamples-1), :);
            machine.Vars.(machine.AnalogInputs(cur_ind).Name)(1, :) = x(machine.AnalogInputs(j).ChannelIndex);
            %Save all samples?
            if (machine.AnalogInputs(cur_ind).SaveSamples),
                machine.SaveVarValue.(machine.AnalogInputs(i).Name)(machine.TrialNumCycles, :) = x(machine.AnalogInputs(j).ChannelIndex);
                machine.SaveVarTimestamp.(machine.AnalogInputs(i).Name)(machine.TrialNumCycles) = ts;
            end
        end %matching variable loop
    end %analog input device loop
    
    % Loop through digital input variables
    for i = 1:machine.NumDigitalInputObject,
        x = getvalue(machine.DigitalInputObject(i)); ts = now;
        matching_vars = find([machine.DigitalInputs(:).MatchingSource] == i);
        for j = 1:length(matching_vars),
            cur_ind = matching_vars(j);
            machine.Vars.(machine.DigitalInputs(cur_ind).Name)(2:machine.DigitalInputs(cur_ind).KeepSamples) = ...
                machine.Vars.(machine.DigitalInputs(cur_ind).Name)(1:(machine.DigitalInputs(cur_ind).KeepSamples-1));
            machine.Vars.(machine.DigitalInputs(cur_ind).Name)(1) = binvec2dec(x(machine.DigitalInputs(j).ChannelIndex));
            %Save all samples?
            if (machine.DigitalInputs(cur_ind).SaveSamples),
                machine.SaveVarValue.(machine.DigitalInputs(i).Name)(machine.TrialNumCycles) = binvec2dec(x(machine.DigitalInputs(j).ChannelIndex));
                machine.SaveVarTimestamp.(machine.DigitalInputs(i).Name)(machine.TrialNumCycles) = ts;
            end
        end %matching variable loop
    end %digital input object loop
        
    %% Update state of machine
    %Update timing and cycle length
    machine.LastCycleLength = now - machine.LastCycleTime;
    machine.LastCycleTime = now;
    machine.AverageTrialCycleLength = (machine.AverageTrialCycleLength*(machine.TrialNumCycles-1) + machine.LastCycleLength)/machine.TrialNumCycles;
    if (machine.LastCycleLength > machine.MaxTrialCycleLength), machine.MaxTrialCycleLength = machine.LastCycleLength; end
    if (machine.LastCycleLength < machine.MinTrialCycleLength), machine.MinTrialCycleLength = machine.LastCycleLength; end
    machine.TimeInState = (now - machine.TimeEnterState)*86400000; % Time (ms) in current state, multiplying by 24*60*60*1000 to get to ms
    
    %If this machine is currently sitting at the 0 state (inter-trial interval)
    %and the ITI has gone on long enough, then initialize the trial
    if (machine.CurrentStateID == ITIState),
        if (machine.TimeInState <= machine.ITILength),
            continue;
        end
        
        %Enter first state (following ITI)
        machine = TransitionStates(machine, machine.CurrentStateID, machine.TrialStartState(machine.CurrentTrial));
        continue;
    end
    
    %Update digital output(s)
    digi_output_time = round(machine.TimeInState);
    for output_ind = 1:machine.States(machine.CurrentStateID).NumDigitalOutput,
        if (machine.States(machine.CurrentStateID).DigitalOutput(output_ind).doStrobe), continue; end %this was just a strobe
        if ((digi_output_time >= 1) && (digi_output_time <= length(machine.States(machine.CurrentStateID).DigitalOutput(output_ind).CurrentData))),
            putvalue(machine.DigitalOutputs(machine.States(machine.CurrentStateID).DigitalOutput(output_ind).DIOIndex).DigitalOutputObject, ...
                machine.States(machine.CurrentStateID).DigitalOutput(output_ind).CurrentData(digi_output_time));
        end
    end
    
    %Otherwise we are in a trial -- check transitions
    for trans_ind = 1:machine.States(machine.CurrentStateID).NumTransitions,
        if eval(machine.States(machine.CurrentStateID).Transitions(trans_ind).Logic),
            
            %Make transition from one state to the next
            machine = TransitionStates(machine, machine.CurrentStateID, ...
                eval(machine.States(machine.CurrentStateID).Transitions(trans_ind).ToState));
            break;
                        
        end %test transition
    end %transition loop
   
    
end %run loop

% End trial
machine = FinalizeTrial(machine);