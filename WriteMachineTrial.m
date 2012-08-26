function err = WriteMachineTrial(fid, machine)

% Writes information about the machine's last trial to the current file.
% File should be ended by writing footer.
%
% Create 6/24/12 by TJB

%% Write tag to file identifying it as a trial
fwrite(fid, 'TRL', 'char*1'); %This will be HDR and FTR for header and footer, respectively

%% Write general trial information

%Trial number (and maximum, in case it changes)
fwrite(fid, machine.CurrentTrial, 'double');
fwrite(fid, machine.MaximumTrials, 'double');
%Current condition
fwrite(fid, machine.CurrentCondition, 'double');

%Timing of the trial
fwrite(fid, machine.LastCycleStartTime, 'double');
fwrite(fid, machine.LastCycleLength, 'double');
fwrite(fid, machine.AverageTrialCycleLength, 'double');
fwrite(fid, machine.MaxTrialCycleLength, 'double');
fwrite(fid, machine.MinTrialCycleLength, 'double');
fwrite(fid, machine.TrialNumCycles, 'uint32');

%Current state information
fwrite(fid, machine.CurrentStateID, 'uint32');
fwrite(fid, length(machine.CurrentStateName), 'uint32'); fwrite(fid, machine.CurrentStateName, 'char*1');
fwrite(fid, machine.TimeInState, 'double');
fwrite(fid, machine.TimeEnterState, 'double');

%% Write trial state list and times

% Starting state of the trial
fwrite(fid, machine.TrialStartState(machine.CurrentTrial), 'int32');
%Ending state of the trial
fwrite(fid, machine.TrialEndState(machine.CurrentTrial), 'int32');
%Number of states in the trial
fwrite(fid, machine.TrialStateCount, 'uint32');
% For each state in the trial
for cur_state_ind = 1:machine.TrialStateCount,
    %record it's ID
    fwrite(fid, machine.TrialStateList{machine.CurrentTrial}(cur_state_ind), 'int32');
    %enter time
    fwrite(fid, machine.TrialStateEnterTimeList{machine.CurrentTrial}(cur_state_ind), 'double');
    %and exit time
    fwrite(fid, machine.TrialStateExitTimeList{machine.CurrentTrial}(cur_state_ind), 'double');
end %state loop

%% Write variables information

%Condition variables
fwrite(fid, machine.NumConditionVars, 'uint32');
for cur_var = 1:machine.NumConditionVars,
    %Name
    fwrite(fid, length(machine.ConditionVars(cur_var).Name), 'uint32'); fwrite(fid, machine.ConditionVars(cur_var).Name, 'char*1');
    %Function
    fwrite(fid, length(machine.ConditionVars(cur_var).Function), 'uint32'); fwrite(fid, machine.ConditionVars(cur_var).Function, 'char*1');
    %Default value
    fwrite(fid, machine.ConditionVars(cur_var).DefaultValue, 'double');
end %condition variables loop

%Variables loop (saved after each state transition)
var_names = fieldnames(machine.Vars);
num_vars = length(var_names);
fwrite(fid, num_vars, 'uint32');
for cur_var = 1:num_vars,
    %Name
    fwrite(fid, length(var_names{cur_var}), 'uint32'); fwrite(fid, var_names{cur_var}, 'char*1');
    
    %Loop through states, saving each in turn
    for cur_state_ind = 1:machine.TrialStateCount,
        %Type of variable defines how to save it to disk
        if isnumeric(machine.StateVarValue(cur_state_ind).(var_names{cur_var})),
            %Is numeric, write array out
            fwrite(fid, 0, 'uint8');
            
            %# dimensions
            fwrite(fid, ndims(machine.StateVarValue(cur_state_ind).(var_names{cur_var})), 'uint8');
            %Size of each dimension
            var_size = size(machine.StateVarValue(cur_state_ind).(var_names{cur_var}));
            for i = 1:ndims(machine.StateVarValue(cur_state_ind).(var_names{cur_var})), fwrite(fid, var_size(i), 'uint32'); end
            %Write all of the values (in serial order)
            fwrite(fid, machine.StateVarValue(cur_state_ind).(var_names{cur_var})(:), 'double');
        elseif iscell(machine.StateVarValue(cur_state_ind).(var_names{cur_var})),
            %Is a cell array, have to treat each element in turn
            fwrite(fid, 2, 'uint8');
            
            %# dimensions
            fwrite(fid, ndims(machine.StateVarValue(cur_state_ind).(var_names{cur_var})), 'uint8');
            %Size of each dimension
            var_size = size(machine.StateVarValue(cur_state_ind).(var_names{cur_var}));
            for i = 1:ndims(machine.StateVarValue(cur_state_ind).(var_names{cur_var})), fwrite(fid, var_size(i), 'uint32'); end
            %Write all of the values (in serial order)
            for cur_ind = 1:numel(machine.StateVarValue(cur_state_ind).(var_names{cur_var})),
                cur_cell_val = machine.StateVarValue(cur_state_ind).(var_names{cur_var}){cur_ind};
                if isnumeric(cur_cell_val),
                    fwrite(fid, 20, 'uint8'); %Numeric data type in cell
                    %# dimensions
                    fwrite(fid, ndims(cur_cell_val), 'uint8');
                    %Size of each dimension
                    var_size = size(cur_cell_val);
                    for i = 1:ndims(cur_cell_val), fwrite(fid, var_size(i), 'uint32'); end
                    %Write all of the values (in serial order)
                    fwrite(fid, cur_cell_val(:), 'double');
                elseif ischar(cur_cell_var),
                    fwrite(fid, 21, 'uint8'); %String data type in cell
                    fwrite(fid, length(cur_cell_val), 'uint32');
                    fwrite(fid, cur_cell_val, 'char*1');
                else
                    error('Cell arrays must either be of character strings or matrices.  Nested cell arrays not supported.');
                end
            end
        elseif ischar(machine.StateVarValue(cur_state_ind).(var_names{cur_var})),
            %Character string
            fwrite(fid, 1, 'uint8');
            fwrite(fid, length(machine.StateVarValue(cur_state_ind).(var_names{cur_var})), 'uint32');
            fwrite(fid, machine.StateVarValue(cur_state_ind).(var_names{cur_var}), 'char*1');
        end
    end %state loop
end %variables loop

%Saved variables loop
var_names = fieldnames(machine.SaveVarValue);
num_vars = length(var_names);
fwrite(fid, num_vars, 'uint32');
for cur_var = 1:num_vars,
    %Name
    fwrite(fid, length(var_names{cur_var}), 'uint32'); fwrite(fid, var_names{cur_var}, 'char*1');
    %# dimensions
    fwrite(fid, ndims(machine.SaveVarValue.(var_names{cur_var})), 'uint8');
    %Size of each dimension
    var_size = size(machine.SaveVarValue.(var_names{cur_var}));
    for i = 1:ndims(machine.SaveVarValue.(var_names{cur_var})), fwrite(fid, var_size(i), 'uint32'); end
    %Write all of the values (in serial order)
    fwrite(fid, machine.SaveVarValue.(var_names{cur_var})(:), 'double');
    %Write all of the timestamps (in serial order)
    fwrite(fid, machine.SaveVarTimestamp.(var_names{cur_var}), 'double');
end %variables loop