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
    
    % Loop through condition variables
    for i = 1:machine.NumConditionVars,
        machine.Vars.(machine.ConditionVars(i).Name) = eval(machine.ConditionVars(i).Function);
    end
        
    %% Update state of machine
    %Update timing and cycle length
    machine.LastCycleLength = now - machine.LastCycleTime;
    machine.LastCycleTime = now;
    machine.AverageTrialCycleLength = (machine.AverageTrialCycleLength*(machine.TrialNumCycles-1) + machine.LastCycleLength)/machine.TrialNumCycles;
    machine.TimeInState = (now - machine.TimeEnterState)*86400000; % Time (ms) in current state, multiplying by 24*60*60*1000 to get to ms
    
    %If this machine is currently sitting at the 0 state (inter-trial interval)
    %and the ITI has gone on long enough, then initialize the trial
    if (machine.CurrentStateID == ITIState),
        if (machine.TimeInState <= machine.ITILength),
            continue;
        end
        
        %Enter first state
        machine.CurrentStateID = machine.TrialStartState(machine.CurrentTrial);
        machine.CurrentStateName = machine.States(machine.CurrentStateID).Name;
        machine.TimeEnterState = now; % Time entered current state
        machine.TimeInState = 0;
        machine.TrialStateCount = 1;
        machine.TrialStateEnterTimeList{machine.CurrentTrial} = [machine.TimeEnterState];
        machine.Interruptable = machine.States(machine.CurrentStateID).Interruptable;
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
            %Need to stop analog outputs?
            for output_ind = 1:machine.States(machine.CurrentStateID).NumAnalogOutput,
                if ((machine.AnalogOutputs(machine.States(machine.CurrentStateID).AnalogOutput(output_ind).AOIndex).DAQSession.IsRunning) & ...
                    (machine.States(machine.CurrentStateID).AnalogOutput(output_ind).ForceStop)),
                    machine.AnalogOutputs(machine.States(machine.CurrentStateID).AnalogOutput(output_ind).AOIndex).DAQSession.stop;
                end
            end
            
            %Transition to new state
            machine.CurrentStateID = eval(machine.States(machine.CurrentStateID).Transitions(trans_ind).ToState);
            machine.TrialStateExitTimeList{machine.CurrentTrial}(machine.TrialStateCount) = now;
            
            %If ITI or end of trial, just skip rest of the transition
            if machine.CurrentStateID <= 0,
                machine.TrialStateCount = machine.TrialStateCount + 1;
                machine.TimeEnterState = now; % Time entered current state
                machine.TrialStateList{machine.CurrentTrial}(machine.TrialStateCount) = machine.CurrentStateID;
                machine.TrialStateEnterTimeList{machine.CurrentTrial}(machine.TrialStateCount) = machine.TimeEnterState;
                machine.Interruptable = 1;
                break;
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
            didStrobe = 0; didTrue = 0;
            for output_ind = 1:machine.States(machine.CurrentStateID).NumDigitalOutput,                
                machine.States(machine.CurrentStateID).DigitalOutput(output_ind).CurrentData = ...
                    eval(machine.States(machine.CurrentStateID).DigitalOutput(output_ind).Data);
                putvalue(machine.DigitalOutputs(machine.States(machine.CurrentStateID).DigitalOutput(output_ind).DIOIndex).DigitalOutputObject, ...
                    machine.States(machine.CurrentStateID).DigitalOutput(output_ind).CurrentData(1));
                didStrobe = didStrobe | machine.States(machine.CurrentStateID).DigitalOutput(output_ind).doStrobe;
                didTrue = didTrue | machine.States(machine.CurrentStateID).DigitalOutput(output_ind).doTrue;
            end
            
            %Set trial start time to now
            machine.TimeEnterState = now; % Time entered current state
            machine.TrialStateCount = machine.TrialStateCount + 1;
            machine.TrialStateList{machine.CurrentTrial}(machine.TrialStateCount) = machine.CurrentStateID;
            machine.TrialStateEnterTimeList{machine.CurrentTrial}(machine.TrialStateCount) = machine.TimeEnterState;
            machine.Interruptable = machine.States(machine.CurrentStateID).Interruptable;
            
            %Do we need to re-set any strobe bits or monitor any 'true' digital outputs?
            while didStrobe | didTrue,
                %Update time in state
                machine.TimeInState = (now - machine.TimeEnterState)*86400000;
                if didStrobe & (machine.TimeInState >= 1),
                    %Waited 1 ms, now re-set strobe
                    for output_ind = 1:machine.States(machine.CurrentStateID).NumDigitalOutput,
                        if machine.States(machine.CurrentStateID).DigitalOutput(output_ind).doStrobe,
                            putvalue(machine.DigitalOutputs(machine.States(machine.CurrentStateID).DigitalOutput(output_ind).DIOIndex).DigitalOutputObject, 0);
                        end
                    end
                    didStrobe = 0;
                end
                if didTrue,
                    didTrue = 0;
                    digi_output_time = max(1, round(machine.TimeInState));
                    for output_ind = 1:machine.States(machine.CurrentStateID).NumDigitalOutput,
                        if machine.States(machine.CurrentStateID).DigitalOutput(output_ind).doTrue, 
                            if (digi_output_time >= length(machine.States(machine.CurrentStateID).DigitalOutput(output_ind).CurrentData)),
                                digi_output_time = length(machine.States(machine.CurrentStateID).DigitalOutput(output_ind).CurrentData);
                            else
                                didTrue = 1;
                            end
                            putvalue(machine.DigitalOutputs(machine.States(machine.CurrentStateID).DigitalOutput(output_ind).DIOIndex).DigitalOutputObject, ...
                                machine.States(machine.CurrentStateID).DigitalOutput(output_ind).CurrentData(digi_output_time));
                        end
                    end
                end
            end %did strobe or true?
            
            break; %out of transition loop
            
        end %test transition
    end %transition loop
   
    
end %run loop

% End trial
machine = FinalizeTrial(machine);