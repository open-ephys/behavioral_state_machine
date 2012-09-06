function machine = ReadMachineHeader(fid)

%% Read header from file identifying it as BSM
key_string = 'Behavioral State Machine';
if ~strcmpi(char(fread(fid, length(key_string), 'char*1')'), key_string), error('File doesn''t appear to be a behavioral state machine file.'); end
if ~strcmpi(char(fread(fid, 3, 'char*1')'), 'HDR'), error('File doesn''t appear to have a behavioral state machine header.'); end
machine.BSMVersion = fread(fid, 1, 'single');

%% Read general information
%         Name: 'Test'
%                     Subject: 'testy'
%                SaveFilename: ''
%                   StartTime: 7.3504e+05
%                   ITILength: NaN
%               MaximumTrials: 100

str_len = fread(fid, 1, 'uint32'); machine.Name = char(fread(fid, str_len, 'char*1')');
str_len = fread(fid, 1, 'uint32'); machine.Subject = char(fread(fid, str_len, 'char*1')');
machine.StartTime = fread(fid, 1, 'double');
machine.ITILength = fread(fid, 1, 'double');
machine.MaximumTrials = fread(fid, 1, 'double');
str_len = fread(fid, 1, 'uint32'); machine.SaveFilename = char(fread(fid, str_len, 'char*1')');

%% Write condition information
%               NumConditions: 2
%              FirstCondition: NaN
%         ChooseNextCondition: [1x1 struct]

machine.NumConditions = fread(fid, 1, 'double');
str_len = fread(fid, 1, 'uint32'); machine.FirstCondition = char(fread(fid, str_len, 'char*1')');
str_len = fread(fid, 1, 'uint32'); machine.ChooseNextCondition.ParserName = char(fread(fid, str_len, 'char*1')');
str_len = fread(fid, 1, 'uint32'); machine.ChooseNextCondition.ParserCall = char(fread(fid, str_len, 'char*1')');
str_len = fread(fid, 1, 'uint32'); machine.ChooseNextCondition.Logic = char(fread(fid, str_len, 'char*1')');

%% Read state information

machine.NumStates = fread(fid, 1, 'double');
str_len = fread(fid, 1, 'uint32'); machine.ChooseStartState.ParserName = char(fread(fid, str_len, 'char*1')');
str_len = fread(fid, 1, 'uint32'); machine.ChooseStartState.ParserCall = char(fread(fid, str_len, 'char*1')');
str_len = fread(fid, 1, 'uint32'); machine.ChooseStartState.Logic = char(fread(fid, str_len, 'char*1')');

for cur_state = 1:machine.NumStates,
    % Basic information about the state
    machine.States(cur_state).ID = fread(fid, 1, 'double');
    machine.States(cur_state).Interruptable = fread(fid, 1, 'uint8');
    str_len = fread(fid, 1, 'uint32'); machine.States(cur_state).Name = char(fread(fid, str_len, 'char*1')');
    
    % Read this state's transitions
    machine.States(cur_state).NumTransitions = fread(fid, 1, 'double'); %# of transitions
    for cur_trans = 1:machine.States(cur_state).NumTransitions,
        % Logic
        str_len = fread(fid, 1, 'uint32'); machine.States(cur_state).Transitions(cur_trans).Logic = char(fread(fid, str_len, 'char*1')');
        %Parser
        str_len = fread(fid, 1, 'uint32'); machine.States(cur_state).Transitions(cur_trans).ParserName = char(fread(fid, str_len, 'char*1')');
        str_len = fread(fid, 1, 'uint32'); machine.States(cur_state).Transitions(cur_trans).ParserCall = char(fread(fid, str_len, 'char*1')');
        %To state
        str_len = fread(fid, 1, 'uint32'); machine.States(cur_state).Transitions(cur_trans).ToState = char(fread(fid, str_len, 'char*1')');
    end %transition loop
    
    % Read this state's analog outputs
    machine.States(cur_state).NumAnalogOutput = fread(fid, 1, 'double'); %# of transitions
    for cur_output = 1:machine.States(cur_state).NumAnalogOutput,
        % Channel
        str_len = fread(fid, 1, 'uint32'); machine.States(cur_state).AnalogOutput(cur_output).Channel = char(fread(fid, str_len, 'char*1')');
        %Data
        str_len = fread(fid, 1, 'uint32'); machine.States(cur_state).AnalogOutput(cur_output).Data = char(fread(fid, str_len, 'char*1')');
        %ForceStop
        machine.States(cur_state).AnalogOutput(cur_output).ForceStop = fread(fid, 1, 'uint8');
        %AOIndex
        machine.States(cur_state).AnalogOutput(cur_output).AOIndex = fread(fid, 1, 'uint32');
    end %analog output loop
    
    % Read this state's digital outputs
    machine.States(cur_state).NumDigitalOutput = fread(fid, 1, 'double'); %# of transitions
    for cur_output = 1:machine.States(cur_state).NumDigitalOutput,
        % VarName
        str_len = fread(fid, 1, 'uint32'); machine.States(cur_state).DigitalOutput(cur_output).Channel = char(fread(fid, str_len, 'char*1')');
        %Function
        str_len = fread(fid, 1, 'uint32'); machine.States(cur_state).DigitalOutput(cur_output).Data = char(fread(fid, str_len, 'char*1')');
        %doStrobe
        machine.States(cur_state).DigitalOutput(cur_output).doStrobe = fread(fid, 1, 'uint8');
        %doTrue
        machine.States(cur_state).DigitalOutput(cur_output).doTrue = fread(fid, 1, 'uint8');
    end %digital output loop
    
    % Read this state's functions to-be-executed
    machine.States(cur_state).NumExecuteFunction = fread(fid, 1, 'double'); %# of transitions
    for cur_func = 1:machine.States(cur_state).NumExecuteFunction,
        % Logic
        str_len = fread(fid, 1, 'uint32'); machine.States(cur_state).ExecuteFunction(cur_func).Function = char(fread(fid, str_len, 'char*1')');
        %Parser
        str_len = fread(fid, 1, 'uint32'); machine.States(cur_state).ExecuteFunction(cur_func).ParserName = char(fread(fid, str_len, 'char*1')');
        str_len = fread(fid, 1, 'uint32'); machine.States(cur_state).ExecuteFunction(cur_func).ParserCall = char(fread(fid, str_len, 'char*1')');
    end %transition loop
    
end %state loop

%% Read input/output information

%Analog outputs
machine.NumAnalogOutputs = fread(fid, 1, 'uint32');
for cur_output = 1:machine.NumAnalogOutputs,
    %Name
    str_len = fread(fid, 1, 'uint32'); machine.AnalogOutputs(cur_output).Name = char(fread(fid, str_len, 'char*1')');
    %Source name
    str_len = fread(fid, 1, 'uint32'); machine.AnalogOutputs(cur_output).SourceName = char(fread(fid, str_len, 'char*1')');
    %Source type
    str_len = fread(fid, 1, 'uint32'); machine.AnalogOutputs(cur_output).SourceType = char(fread(fid, str_len, 'char*1')');
    %Source rate
    machine.AnalogOutputs(cur_output).SourceRate = fread(fid, 1, 'double');
    %Default value
    machine.AnalogOutputs(cur_output).DefaultValue = fread(fid, 1, 'double');
    %Channel(s)
    num_chan = fread(fid, 1, 'uint32');
    machine.AnalogOutputs(cur_output).Channel = fread(fid, num_chan, 'uint32');
    %Source parameters
    num_param = fread(fid, 1, 'uint32');
    for i = 1:num_param,
        str_len = fread(fid, 1, 'uint32'); machine.AnalogOutputs(cur_output).SourceParameters{i} = char(fread(fid, str_len, 'char*1')');
    end
end %analog output loop

%Digital outputs
machine.NumDigitalOutputs = fread(fid, 1, 'uint32');
for cur_output = 1:machine.NumDigitalOutputs,
    %Name
    str_len = fread(fid, 1, 'uint32'); machine.DigitalOutputs(cur_output).Name = char(fread(fid, str_len, 'char*1')');
    %Source name
    str_len = fread(fid, 1, 'uint32'); machine.DigitalOutputs(cur_output).SourceName = char(fread(fid, str_len, 'char*1')');
    %Source type
    str_len = fread(fid, 1, 'uint32'); machine.DigitalOutputs(cur_output).SourceType = char(fread(fid, str_len, 'char*1')');
    %Source rate
    machine.DigitalOutputs(cur_output).SourceRate = fread(fid, 1, 'double');
    %Default value
    machine.DigitalOutputs(cur_output).DefaultValue = fread(fid, 1, 'double');
    %Channel(s)
    num_chan = fread(fid, 1, 'uint32');
    machine.DigitalOutputs(cur_output).Channel = fread(fid, num_chan, 'uint32');
    %Source parameters
    num_param = fread(fid, 1, 'uint32');
    for i = 1:num_param,
        str_len = fread(fid, 1, 'uint32'); machine.DigitalOutputs(cur_output).SourceParameters{i} = char(fread(fid, str_len, 'char*1')');
    end
end %digital output loop

%Analog inputs
machine.NumAnalogInputs = fread(fid, 1, 'uint32');
for cur_input = 1:machine.NumAnalogInputs,
    %Name
    str_len = fread(fid, 1, 'uint32'); machine.AnalogInputs(cur_input).Name = char(fread(fid, str_len, 'char*1')');
    %Source name
    str_len = fread(fid, 1, 'uint32'); machine.AnalogInputs(cur_input).SourceName = char(fread(fid, str_len, 'char*1')');
    %Source type
    str_len = fread(fid, 1, 'uint32'); machine.AnalogInputs(cur_input).SourceType = char(fread(fid, str_len, 'char*1')');
    %Source rate
    machine.AnalogInputs(cur_input).SourceRate = fread(fid, 1, 'double');
    %Keep samples -- how many samples to keep
    machine.AnalogInputs(cur_input).KeepSamples = fread(fid, 1, 'double');
    %Save samples -- whether to store all of the samples read
    machine.AnalogInputs(cur_input).SaveSamples = boolean(fread(fid, 1, 'uint8'));
    %Default value
    machine.AnalogInputs(cur_input).DefaultValue = fread(fid, 1, 'double');
    %Channel(s)
    num_chan = fread(fid, 1, 'uint32');
    machine.AnalogInputs(cur_input).Channel = fread(fid, num_chan, 'uint32');
    %Source parameters
    num_param = fread(fid, 1, 'uint32');
    for i = 1:num_param,
        str_len = fread(fid, 1, 'uint32'); machine.AnalogInputs(cur_input).SourceParameters{i} = char(fread(fid, str_len, 'char*1')');
    end
end %analog inputs loop

%Digital inputs
machine.NumDigitalInputs = fread(fid, 1, 'uint32');
for cur_input = 1:machine.NumDigitalInputs,
    %Name
    str_len = fread(fid, 1, 'uint32'); machine.DigitalInputs(cur_input).Name = char(fread(fid, str_len, 'char*1')');
    %Source name
    str_len = fread(fid, 1, 'uint32'); machine.DigitalInputs(cur_input).SourceName = char(fread(fid, str_len, 'char*1')');
    %Source type
    str_len = fread(fid, 1, 'uint32'); machine.DigitalInputs(cur_input).SourceType = char(fread(fid, str_len, 'char*1')');
    %Source rate
    machine.DigitalInputs(cur_input).SourceRate = fread(fid, 1, 'double');
    %Keep samples -- how many samples to keep
    machine.DigitalInputs(cur_input).KeepSamples = fread(fid, 1, 'double');
    %Save samples -- whether to store all of the samples read
    machine.DigitalInputs(cur_input).SaveSamples = boolean(fread(fid, 1, 'uint8'));
    %Default value
    machine.DigitalInputs(cur_input).DefaultValue = fread(fid, 1, 'double');
    %Channel(s)
    num_chan = fread(fid, 1, 'uint32');
    machine.DigitalInputs(cur_input).Channel = fread(fid, num_chan, 'uint32');
    %Source parameters
    num_param = fread(fid, 1, 'uint32');
    for i = 1:num_param,
        str_len = fread(fid, 1, 'uint32'); machine.DigitalInputs(cur_input).SourceParameters{i} = char(fread(fid, str_len, 'char*1')');
    end
end %digital inputs loop


%% Write variables information

%Condition variables
machine.NumConditionVars = fread(fid, 1, 'uint32');
for cur_var = 1:machine.NumConditionVars,
    %Name
    str_len = fread(fid, 1, 'uint32'); machine.ConditionVars(cur_var).Name = char(fread(fid, str_len, 'char*1')');
    %Function
    str_len = fread(fid, 1, 'uint32'); machine.ConditionVars(cur_var).Function = char(fread(fid, str_len, 'char*1')');
    %Default value
    machine.ConditionVars(cur_var).DefaultValue = fread(fid, 1, 'double');
end %condition variables loop

%Variables loop
num_vars = fread(fid, 1, 'uint32');
var_names = cell(num_vars, 1);
for cur_var = 1:num_vars,
    %Name
    str_len = fread(fid, 1, 'uint32'); var_names{cur_var} = char(fread(fid, str_len, 'char*1')');
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
    machine.Vars.(var_names{cur_var}) = temp_var;
end %variables loop