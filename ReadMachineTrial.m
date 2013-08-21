<<<<<<< HEAD
function trial_struct = ReadMachineTrial(fid)

% Read information about the machine's last trial from the current file.
% File should be ended by writing footer.
%
% Create 6/24/12 by TJB

%% Read tag from file identifying it as a trial
tag = char(fread(fid, 3, 'char*1')');
if strcmpi(tag, 'FTR'),
    fseek(fid, -3, 'cof'); %Move back
    trial_struct = [];
    return;
end

%% Read general trial information

%Trial number
trial_struct.CurrentTrial = fread(fid, 1, 'double');
trial_struct.MaximumTrials = fread(fid, 1, 'double');
%Current condition
trial_struct.CurrentCondition = fread(fid, 1, 'double');
%Current condition set
trial_struct.CurrentConditionSet = fread(fid, 1, 'double');

%Timing of the trial
trial_struct.LastCycleStartTime = fread(fid, 1, 'double');
trial_struct.LastCycleLength = fread(fid, 1, 'double');
trial_struct.AverageTrialCycleLength = fread(fid, 1, 'double');
trial_struct.MaxTrialCycleLength = fread(fid, 1, 'double');
trial_struct.MinTrialCycleLength = fread(fid, 1, 'double');
trial_struct.TrialNumCycles = fread(fid, 1, 'uint32');

%Current state information
trial_struct.CurrentStateID = fread(fid, 1, 'uint32');
str_len = fread(fid, 1, 'uint32'); trial_struct.CurrentStateName = char(fread(fid, str_len, 'char*1')');
trial_struct.TimeInState = fread(fid, 1, 'double');
trial_struct.TimeEnterState = fread(fid, 1, 'double');

%Any hotkeys executed before this trial
num = fread(fid, 1, 'double');
trial_struct.doHotkey = logical(fread(fid, num, 'uint8'));

%% Read trial state list and times

% Starting state of the trial
trial_struct.TrialStartState = fread(fid, 1, 'int32');
%Ending state of the trial
trial_struct.TrialEndState = fread(fid, 1, 'int32');
%Number of states in the trial
trial_struct.TrialStateCount = fread(fid, 1, 'uint32');
% For each state in the trial
for cur_state_ind = 1:trial_struct.TrialStateCount,
    %record it's ID
    trial_struct.TrialStateList(cur_state_ind) = fread(fid, 1, 'int32');
    %enter time
    trial_struct.TrialStateEnterTimeList(cur_state_ind) = fread(fid, 1, 'double');
    %exit time
    trial_struct.TrialStateExitTimeList(cur_state_ind) = fread(fid, 1, 'double');
    %did any analog outputs fail
    len = fread(fid, 1, 'uint32');
    if len > 0,
        trial_struct.TrialStateAnalogOutputFailed(cur_state_ind) = fread(fid, len, 'double');
    else
        trial_struct.TrialStateAnalogOutputFailed(cur_state_ind) = [];
    end    
end %state loop

%% Read variables information

%Condition variables
trial_struct.NumConditionVars = fread(fid, 1, 'uint32');
for cur_var = 1:trial_struct.NumConditionVars,
    %Name
    str_len = fread(fid, 1, 'uint32'); trial_struct.ConditionVars(cur_var).Name = char(fread(fid, str_len, 'char*1')');
    %Function
    str_len = fread(fid, 1, 'uint32'); trial_struct.ConditionVars(cur_var).Function = char(fread(fid, str_len, 'char*1')');
    %Default value
    len = fread(fid, 1, 'uint32');
    if len > 0,
        trial_struct.ConditionVars(cur_var).DefaultValue = fread(fid, len, 'double');
    else
        trial_struct.ConditionVars(cur_var).DefaultValue = [];
    end    
    %Editable?
    trial_struct.ConditionVars(cur_var).Editable = logical(fread(fid, 1, 'uint8'));
end %condition variables loop

%Variables loop
num_vars = fread(fid, 1, 'uint32');
var_names = cell(num_vars, 1);
for cur_var = 1:num_vars,
    %Name
    str_len = fread(fid, 1, 'uint32'); var_names{cur_var} = char(fread(fid, str_len, 'char*1')');
    %Loop through states, saving each in turn
    for cur_state_ind = 1:trial_struct.TrialStateCount,
        %What is the type of variable?
        var_type = fread(fid, 1, 'uint8');
        if (var_type == 0),
            %Is numeric, read array in
            
            %# dimensions
            num_dims = fread(fid, 1, 'uint8');
            %Size of each dimension
            var_size = fread(fid, num_dims, 'uint32')';
            if prod(var_size) == 0,
                temp_var = [];
            else
                %Read all of the values (in serial order)
                temp_var = fread(fid, prod(var_size), 'double');
                temp_var = reshape(temp_var, var_size);
            end
        elseif (var_type == 2),
            %Is a cell array, have to treat each element in turn
            
            %# dimensions
            num_dims = fread(fid, 1, 'uint8');
            %Size of each dimension
            var_size = fread(fid, num_dims, 'uint8');
            %Write all of the values (in serial order)
            for cur_ind = 1:prod(var_size),
                cell_type = fread(fid, 1, 'uint8');
                if cell_type == 20,
                    %# dimensions
                    cell_dims = fread(fid, 1, 'uint8');
                    %Size of each dimension
                    cell_var_size = fread(fid, cell_dims, 'uint32')';
                    if prod(var_size) == 0,
                        cur_cell_val = [];
                    else
                        %Read all of the values (in serial order)
                        cur_cell_val = fread(fid, prod(cell_var_size), 'double');
                        cur_cell_val = reshape(cur_cell_val, var_size);
                    end
                elseif cell_type == 21,
                    str_len = fread(fid, 1, 'uint32');
                    cur_cell_val = char(fread(fid, str_len, 'char*1')');
                elseif cell_type == 23,
                    %# dimensions
                    cell_dims = fread(fid, 1, 'uint8');
                    %Size of each dimension
                    cell_var_size = fread(fid, cell_dims, 'uint32')';
                    if prod(var_size) == 0,
                        cur_cell_val = [];
                    else
                        %Read all of the values (in serial order)
                        cur_cell_val = logical(fread(fid, prod(cell_var_size), 'uint1'));
                        cur_cell_val = reshape(cur_cell_val, var_size);
                    end
                else
                    error('Cell array contains a type of data not supported.');
                end
                temp_var{cur_ind} = cur_cell_val;
            end
        elseif (var_type == 1),
            %Character string
            str_len = fread(fid, 1, 'uint32');
            temp_var = char(fread(fid, str_len, 'char*1')');
        elseif (var_type == 3),
            %Is logical, read array in
            
            %# dimensions
            num_dims = fread(fid, 1, 'uint8');
            %Size of each dimension
            var_size = fread(fid, num_dims, 'uint32')';
            if prod(var_size) == 0,
                temp_var = [];
            else
                %Read all of the values (in serial order)
                temp_var = logical(fread(fid, prod(var_size), 'ubit1'));
                temp_var = reshape(temp_var, var_size);
            end            
        elseif (var_type == 255),
            warning('Couldn''t read in value for variable %s because it wasn''t a known type at the time of writing the file.', var_names{cur_var});
        else
            error('Reading in file failed.  Ran into an unknown variable type that wasn''t written properly.');
        end
        trial_struct.StateVarValue(cur_state_ind).(var_names{cur_var}) = temp_var;
    end %state loop
end %variables loop

%Saved variables loop
num_vars = fread(fid, 1, 'uint32');
for cur_var = 1:num_vars,
    %Name
    str_len = fread(fid, 1, 'uint32'); var_name = char(fread(fid, str_len, 'char*1')');
    
    %# dimensions
    num_dims = fread(fid, 1, 'uint8');
    %Size of each dimension
    var_size = fread(fid, num_dims, 'uint32')';
    num_samples = var_size(find(var_size > 1, 1, 'first'));
    if prod(var_size) == 0,
        temp_var = [];
        temp_ts = [];
    else
        %Read all of the values (in serial order)
        temp_var = fread(fid, prod(var_size), 'double');
        temp_var = reshape(temp_var, var_size);
        %Read all of the timestamps (in serial order)
        temp_ts = fread(fid, num_samples, 'double');
    end
    
    trial_struct.SaveVarValue.(var_name) = temp_var;
    trial_struct.SaveVarTimestamp.(var_name) = temp_ts;
=======
function trial_struct = ReadMachineTrial(fid)

% Read information about the machine's last trial from the current file.
% File should be ended by writing footer.
%
% Create 6/24/12 by TJB

%% Read tag from file identifying it as a trial
tag = char(fread(fid, 3, 'char*1')');
if strcmpi(tag, 'FTR'),
    fseek(fid, -3, 'cof'); %Move back
    trial_struct = [];
    return;
end

%% Read general trial information

%Trial number
trial_struct.CurrentTrial = fread(fid, 1, 'double');
trial_struct.MaximumTrials = fread(fid, 1, 'double');
%Current condition
trial_struct.CurrentCondition = fread(fid, 1, 'double');
%Current condition set
trial_struct.CurrentConditionSet = fread(fid, 1, 'double');

%Timing of the trial
trial_struct.LastCycleStartTime = fread(fid, 1, 'double');
trial_struct.LastCycleLength = fread(fid, 1, 'double');
trial_struct.AverageTrialCycleLength = fread(fid, 1, 'double');
trial_struct.MaxTrialCycleLength = fread(fid, 1, 'double');
trial_struct.MinTrialCycleLength = fread(fid, 1, 'double');
trial_struct.TrialNumCycles = fread(fid, 1, 'uint32');

%Current state information
trial_struct.CurrentStateID = fread(fid, 1, 'uint32');
str_len = fread(fid, 1, 'uint32'); trial_struct.CurrentStateName = char(fread(fid, str_len, 'char*1')');
trial_struct.TimeInState = fread(fid, 1, 'double');
trial_struct.TimeEnterState = fread(fid, 1, 'double');

%Any hotkeys executed before this trial
num = fread(fid, 1, 'double');
trial_struct.doHotkey = logical(fread(fid, num, 'uint8'));

%% Read trial state list and times

% Starting state of the trial
trial_struct.TrialStartState = fread(fid, 1, 'int32');
%Ending state of the trial
trial_struct.TrialEndState = fread(fid, 1, 'int32');
%Number of states in the trial
trial_struct.TrialStateCount = fread(fid, 1, 'uint32');
% For each state in the trial
for cur_state_ind = 1:trial_struct.TrialStateCount,
    %record it's ID
    trial_struct.TrialStateList(cur_state_ind) = fread(fid, 1, 'int32');
    %enter time
    trial_struct.TrialStateEnterTimeList(cur_state_ind) = fread(fid, 1, 'double');
    %and exit time
    trial_struct.TrialStateExitTimeList(cur_state_ind) = fread(fid, 1, 'double');
    %did any analog outputs fail
    len = fread(fid, 1, 'uint32');
    if len > 0,
        trial_struct.TrialStateAnalogOutputFailed(cur_state_ind) = fread(fid, len, 'double');
    else
        trial_struct.TrialStateAnalogOutputFailed(cur_state_ind) = [];
    end    
end %state loop

%% Read variables information

%Condition variables
trial_struct.NumConditionVars = fread(fid, 1, 'uint32');
for cur_var = 1:trial_struct.NumConditionVars,
    %Name
    str_len = fread(fid, 1, 'uint32'); trial_struct.ConditionVars(cur_var).Name = char(fread(fid, str_len, 'char*1')');
    %Function
    str_len = fread(fid, 1, 'uint32'); trial_struct.ConditionVars(cur_var).Function = char(fread(fid, str_len, 'char*1')');
    %Default value
    len = fread(fid, 1, 'uint32');
    if len > 0,
        trial_struct.ConditionVars(cur_var).DefaultValue = fread(fid, len, 'double');
    else
        trial_struct.ConditionVars(cur_var).DefaultValue = [];
    end    
    %Editable?
    trial_struct.ConditionVars(cur_var).Editable = logical(fread(fid, 1, 'uint8'));
end %condition variables loop

%Variables loop
num_vars = fread(fid, 1, 'uint32');
var_names = cell(num_vars, 1);
for cur_var = 1:num_vars,
    %Name
    str_len = fread(fid, 1, 'uint32'); var_names{cur_var} = char(fread(fid, str_len, 'char*1')');
    %Loop through states, saving each in turn
    for cur_state_ind = 1:trial_struct.TrialStateCount,
        %What is the type of variable?
        var_type = fread(fid, 1, 'uint8');
        if (var_type == 0),
            %Is numeric, read array in
            
            %# dimensions
            num_dims = fread(fid, 1, 'uint8');
            %Size of each dimension
            var_size = fread(fid, num_dims, 'uint32')';
            if prod(var_size) == 0,
                temp_var = [];
            else
                %Read all of the values (in serial order)
                temp_var = fread(fid, prod(var_size), 'double');
                temp_var = reshape(temp_var, var_size);
            end
        elseif (var_type == 2),
            %Is a cell array, have to treat each element in turn
            
            %# dimensions
            num_dims = fread(fid, 1, 'uint8');
            %Size of each dimension
            var_size = fread(fid, num_dims, 'uint8');
            %Write all of the values (in serial order)
            for cur_ind = 1:prod(var_size),
                cell_type = fread(fid, 1, 'uint8');
                if cell_type == 20,
                    %# dimensions
                    cell_dims = fread(fid, 1, 'uint8');
                    %Size of each dimension
                    cell_var_size = fread(fid, cell_dims, 'uint32')';
                    if prod(var_size) == 0,
                        cur_cell_val = [];
                    else
                        %Read all of the values (in serial order)
                        cur_cell_val = fread(fid, prod(cell_var_size), 'double');
                        cur_cell_val = reshape(cur_cell_val, var_size);
                    end
                elseif cell_type == 21,
                    str_len = fread(fid, 1, 'uint32');
                    cur_cell_val = char(fread(fid, str_len, 'char*1')');
                elseif cell_type == 23,
                    %# dimensions
                    cell_dims = fread(fid, 1, 'uint8');
                    %Size of each dimension
                    cell_var_size = fread(fid, cell_dims, 'uint32')';
                    if prod(var_size) == 0,
                        cur_cell_val = [];
                    else
                        %Read all of the values (in serial order)
                        cur_cell_val = logical(fread(fid, prod(cell_var_size), 'uint1'));
                        cur_cell_val = reshape(cur_cell_val, var_size);
                    end
                else
                    error('Cell array contains a type of data not supported.');
                end
                temp_var{cur_ind} = cur_cell_val;
            end
        elseif (var_type == 1),
            %Character string
            str_len = fread(fid, 1, 'uint32');
            temp_var = char(fread(fid, str_len, 'char*1')');
        elseif (var_type == 3),
            %Is logical, read array in
            
            %# dimensions
            num_dims = fread(fid, 1, 'uint8');
            %Size of each dimension
            var_size = fread(fid, num_dims, 'uint32')';
            if prod(var_size) == 0,
                temp_var = [];
            else
                %Read all of the values (in serial order)
                temp_var = logical(fread(fid, prod(var_size), 'ubit1'));
                temp_var = reshape(temp_var, var_size);
            end            
        elseif (var_type == 255),
            warning('Couldn''t read in value for variable %s because it wasn''t a known type at the time of writing the file.', var_names{cur_var});
        else
            error('Reading in file failed.  Ran into an unknown variable type that wasn''t written properly.');
        end
        trial_struct.StateVarValue(cur_state_ind).(var_names{cur_var}) = temp_var;
    end %state loop
end %variables loop

%Saved variables loop
num_vars = fread(fid, 1, 'uint32');
for cur_var = 1:num_vars,
    %Name
    str_len = fread(fid, 1, 'uint32'); var_name = char(fread(fid, str_len, 'char*1')');
    
    %# dimensions
    num_dims = fread(fid, 1, 'uint8');
    %Size of each dimension
    var_size = fread(fid, num_dims, 'uint32')';
    num_samples = var_size(find(var_size > 1, 1, 'first'));
    if prod(var_size) == 0,
        temp_var = [];
        temp_ts = [];
    else
        %Read all of the values (in serial order)
        temp_var = fread(fid, prod(var_size), 'double');
        temp_var = reshape(temp_var, var_size);
        %Read all of the timestamps (in serial order)
        temp_ts = fread(fid, num_samples, 'double');
    end
    
    trial_struct.SaveVarValue.(var_name) = temp_var;
    trial_struct.SaveVarTimestamp.(var_name) = temp_ts;
>>>>>>> BSM 0.22, bug fixes in ExecuteFunction
end %variables loop