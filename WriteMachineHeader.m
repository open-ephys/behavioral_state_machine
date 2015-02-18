function err = WriteMachineHeader(fid, machine)

% Writes header information about the machine to the current file.  This
% should be followed by individual trial information and then the file
% should be ended by writing footer.
%
% Create 6/22/12 by TJB

%% Write header to file identifying it as BSM
key_string = 'Behavioral State Machine';
fwrite(fid, key_string, 'char*1');
fwrite(fid, 'HDR', 'char*1'); %This will be TRL and FTR for trial and footer, respectively
fwrite(fid, machine.BSMVersion, 'single');

%% Write general information
%         Name: 'Test'
%                     Subject: 'testy'
%                SaveFilename: ''
%                   StartTime: 7.3504e+05
%                   ITILength: NaN
%               MaximumTrials: 100

fwrite(fid, length(machine.Name), 'uint32'); fwrite(fid, machine.Name, 'char*1');
fwrite(fid, length(machine.Subject), 'uint32'); fwrite(fid, machine.Subject, 'char*1');
fwrite(fid, machine.StartTime, 'double');
fwrite(fid, machine.ITILength, 'double');
fwrite(fid, machine.MaximumTrials, 'double');
fwrite(fid, length(machine.SaveFilename), 'uint32'); fwrite(fid, machine.SaveFilename, 'char*1');

%% Write condition information
%               NumConditions: 2
%              FirstCondition: NaN
%         ChooseNextCondition: [1x1 struct]
fwrite(fid, machine.NumConditions, 'double');
fwrite(fid, length(machine.FirstCondition), 'uint32'); fwrite(fid, machine.FirstCondition, 'char*1');
fwrite(fid, length(machine.ChooseNextCondition.ParserName), 'uint32'); fwrite(fid, machine.ChooseNextCondition.ParserName, 'char*1');
fwrite(fid, length(machine.ChooseNextCondition.ParserCall), 'uint32'); fwrite(fid, machine.ChooseNextCondition.ParserCall, 'char*1');
fwrite(fid, length(machine.ChooseNextCondition.Logic), 'uint32'); fwrite(fid, machine.ChooseNextCondition.Logic, 'char*1');

%% Write condition set information
%            NumConditionSets: 1
%         CurrentConditionSet: 1
fwrite(fid, machine.NumConditionSets, 'double');
fwrite(fid, machine.CurrentConditionSet, 'double');

%% Write Hotkey information
%                  NumHotkeys: 1
%                      Hotkey: function
%                    doHotkey: [0]
fwrite(fid, machine.NumHotkeys, 'double');
for i = 1:machine.NumHotkeys,
    fwrite(fid, length(machine.Hotkey(i).Name), 'uint32'); fwrite(fid, machine.Hotkey(i).Name, 'char*1');
    fwrite(fid, length(machine.Hotkey(i).ParserName), 'uint32'); fwrite(fid, machine.Hotkey(i).ParserName, 'char*1');
    fwrite(fid, length(machine.Hotkey(i).ParserCall), 'uint32'); fwrite(fid, machine.Hotkey(i).ParserCall, 'char*1');
    fwrite(fid, length(machine.Hotkey(i).Logic), 'uint32'); fwrite(fid, machine.Hotkey(i).Logic, 'char*1');
end
fwrite(fid, machine.doHotkey, 'uint8');

%% Write state information

fwrite(fid, machine.NumStates, 'double');
fwrite(fid, length(machine.ChooseStartState.ParserName), 'uint32'); fwrite(fid, machine.ChooseStartState.ParserName, 'char*1');
fwrite(fid, length(machine.ChooseStartState.ParserCall), 'uint32'); fwrite(fid, machine.ChooseStartState.ParserCall, 'char*1');
fwrite(fid, length(machine.ChooseStartState.Logic), 'uint32'); fwrite(fid, machine.ChooseStartState.Logic, 'char*1');
for cur_state = 1:machine.NumStates,
    % Basic information about the state
    fwrite(fid, machine.States(cur_state).ID, 'double');
    fwrite(fid, machine.States(cur_state).Interruptable, 'uint8');
    fwrite(fid, length(machine.States(cur_state).Name), 'uint32'); fwrite(fid, machine.States(cur_state).Name, 'char*1');
    
    % Write this state's transitions
    fwrite(fid, machine.States(cur_state).NumTransitions, 'double'); %# of transitions
    for cur_trans = 1:machine.States(cur_state).NumTransitions,
        % Logic
        fwrite(fid, length(machine.States(cur_state).Transitions(cur_trans).Logic), 'uint32'); fwrite(fid, machine.States(cur_state).Transitions(cur_trans).Logic, 'char*1');
        %Parser
        fwrite(fid, length(machine.States(cur_state).Transitions(cur_trans).ParserName), 'uint32'); fwrite(fid, machine.States(cur_state).Transitions(cur_trans).ParserName, 'char*1');
        fwrite(fid, length(machine.States(cur_state).Transitions(cur_trans).ParserCall), 'uint32'); fwrite(fid, machine.States(cur_state).Transitions(cur_trans).ParserCall, 'char*1');
        %State to transition to
        fwrite(fid, length(machine.States(cur_state).Transitions(cur_trans).ToState), 'uint32'); fwrite(fid, machine.States(cur_state).Transitions(cur_trans).ToState, 'char*1');
    end %transition loop
    
    % Write this state's analog outputs
    fwrite(fid, machine.States(cur_state).NumAnalogOutput, 'double'); %# of analog outputs
    for cur_output = 1:machine.States(cur_state).NumAnalogOutput,
        % Channel
        fwrite(fid, length(machine.States(cur_state).AnalogOutput(cur_output).Channel), 'uint32'); fwrite(fid, machine.States(cur_state).AnalogOutput(cur_output).Channel, 'char*1');
        %Data
        fwrite(fid, length(machine.States(cur_state).AnalogOutput(cur_output).Data), 'uint32'); fwrite(fid, machine.States(cur_state).AnalogOutput(cur_output).Data, 'char*1');
        %ForceStop
        fwrite(fid, machine.States(cur_state).AnalogOutput(cur_output).ForceStop, 'uint8');
        %doContinuous
        fwrite(fid, machine.States(cur_state).AnalogOutput(cur_output).doContinuousUpdates, 'uint8'); 
        %AOIndex
        fwrite(fid, machine.States(cur_state).AnalogOutput(cur_output).AOIndex, 'uint32');
    end %analog output loop
    
    % Write this state's digital outputs
    fwrite(fid, machine.States(cur_state).NumDigitalOutput, 'double'); %# of digital outputs
    for cur_output = 1:machine.States(cur_state).NumDigitalOutput,
        % VarName
        fwrite(fid, length(machine.States(cur_state).DigitalOutput(cur_output).Channel), 'uint32'); fwrite(fid, machine.States(cur_state).DigitalOutput(cur_output).Channel, 'char*1');
        %Function
        fwrite(fid, length(machine.States(cur_state).DigitalOutput(cur_output).Data), 'uint32'); fwrite(fid, machine.States(cur_state).DigitalOutput(cur_output).Data, 'char*1');
        %doStrobe
        fwrite(fid, machine.States(cur_state).DigitalOutput(cur_output).doStrobe, 'uint8');
        %doTrue
        fwrite(fid, machine.States(cur_state).DigitalOutput(cur_output).doTrue, 'uint8');
        %doContinuous
        fwrite(fid, machine.States(cur_state).DigitalOutput(cur_output).doContinuousUpdates, 'uint8');        
    end %digital output loop
    
    % Write this state's functions to-be-executed
    fwrite(fid, machine.States(cur_state).NumExecuteFunction, 'double'); %# of functions to be executed
    for cur_func = 1:machine.States(cur_state).NumExecuteFunction,
        %Function
        fwrite(fid, length(machine.States(cur_state).ExecuteFunction(cur_func).Function), 'uint32'); fwrite(fid, machine.States(cur_state).ExecuteFunction(cur_func).Function, 'char*1');
        %Parser
        fwrite(fid, length(machine.States(cur_state).ExecuteFunction(cur_func).ParserName), 'uint32'); fwrite(fid, machine.States(cur_state).ExecuteFunction(cur_func).ParserName, 'char*1');
        fwrite(fid, length(machine.States(cur_state).ExecuteFunction(cur_func).ParserCall), 'uint32'); fwrite(fid, machine.States(cur_state).ExecuteFunction(cur_func).ParserCall, 'char*1');
    end %transition loop
    
end %state loop

%% Write input/output information

%Analog outputs
fwrite(fid, machine.NumAnalogOutputs, 'uint32');
for cur_output = 1:machine.NumAnalogOutputs,
    %Name
    fwrite(fid, length(machine.AnalogOutputs(cur_output).Name), 'uint32'); fwrite(fid, machine.AnalogOutputs(cur_output).Name, 'char*1');
    %Source name
    fwrite(fid, length(machine.AnalogOutputs(cur_output).SourceName), 'uint32'); fwrite(fid, machine.AnalogOutputs(cur_output).SourceName, 'char*1');
    %Source type
    fwrite(fid, length(machine.AnalogOutputs(cur_output).SourceType), 'uint32'); fwrite(fid, machine.AnalogOutputs(cur_output).SourceType, 'char*1');
    %Source rate
    fwrite(fid, machine.AnalogOutputs(cur_output).SourceRate, 'double');
    %Default value
    fwrite(fid, machine.AnalogOutputs(cur_output).DefaultValue, 'double');
    %Channel(s)
    fwrite(fid, length(machine.AnalogOutputs(cur_output).Channel), 'uint32');
    fwrite(fid, machine.AnalogOutputs(cur_output).Channel, 'uint32');
    %Source parameters
    fwrite(fid, length(machine.AnalogOutputs(cur_output).SourceParameters), 'uint32');
    for i = 1:length(machine.AnalogOutputs(cur_output).SourceParameters),
        fwrite(fid, length(machine.AnalogOutputs(cur_output).SourceParameters{i}), 'uint32');
        fwrite(fid, machine.AnalogOutputs(cur_output).SourceParameters{i}, 'char*1');
    end
end %analog output loop

%Digital outputs
fwrite(fid, machine.NumDigitalOutputs, 'uint32');
for cur_output = 1:machine.NumDigitalOutputs,
    %Name
    fwrite(fid, length(machine.DigitalOutputs(cur_output).Name), 'uint32'); fwrite(fid, machine.DigitalOutputs(cur_output).Name, 'char*1');
    %Source name
    fwrite(fid, length(machine.DigitalOutputs(cur_output).SourceName), 'uint32'); fwrite(fid, machine.DigitalOutputs(cur_output).SourceName, 'char*1');
    %Source type
    fwrite(fid, length(machine.DigitalOutputs(cur_output).SourceType), 'uint32'); fwrite(fid, machine.DigitalOutputs(cur_output).SourceType, 'char*1');
    %Source rate
    fwrite(fid, machine.DigitalOutputs(cur_output).SourceRate, 'double');
    %Default value
    fwrite(fid, machine.DigitalOutputs(cur_output).DefaultValue, 'double');
    %Channel(s)
    fwrite(fid, length(machine.DigitalOutputs(cur_output).Channel), 'uint32');
    fwrite(fid, machine.DigitalOutputs(cur_output).Channel, 'uint32');
    %Source parameters
    fwrite(fid, length(machine.DigitalOutputs(cur_output).SourceParameters), 'uint32');
    for i = 1:length(machine.DigitalOutputs(cur_output).SourceParameters),
        fwrite(fid, length(machine.DigitalOutputs(cur_output).SourceParameters{i}), 'uint32');
        fwrite(fid, machine.DigitalOutputs(cur_output).SourceParameters{i}, 'char*1');
    end
end %digital output loop

%Analog inputs
fwrite(fid, machine.NumAnalogInputs, 'uint32');
for cur_input = 1:machine.NumAnalogInputs,
    %Name
    fwrite(fid, length(machine.AnalogInputs(cur_input).Name), 'uint32'); fwrite(fid, machine.AnalogInputs(cur_input).Name, 'char*1');
    %Source name
    fwrite(fid, length(machine.AnalogInputs(cur_input).SourceName), 'uint32'); fwrite(fid, machine.AnalogInputs(cur_input).SourceName, 'char*1');
    %Source type
    fwrite(fid, length(machine.AnalogInputs(cur_input).SourceType), 'uint32'); fwrite(fid, machine.AnalogInputs(cur_input).SourceType, 'char*1');
    %Source rate
    fwrite(fid, machine.AnalogInputs(cur_input).SourceRate, 'double');
    %Keep samples -- how many samples to keep
    fwrite(fid, machine.AnalogInputs(cur_input).KeepSamples, 'double');
    %Save samples -- whether to store all of the samples read
    fwrite(fid, machine.AnalogInputs(cur_input).SaveSamples, 'uint8');
    %Default value
    fwrite(fid, machine.AnalogInputs(cur_input).DefaultValue, 'double');
    %Channel(s)
    fwrite(fid, length(machine.AnalogInputs(cur_input).Channel), 'uint32');
    fwrite(fid, machine.AnalogInputs(cur_input).Channel, 'uint32');
    %Source parameters
    fwrite(fid, length(machine.AnalogInputs(cur_input).SourceParameters), 'uint32');
    for i = 1:length(machine.AnalogInputs(cur_input).SourceParameters),
        fwrite(fid, length(machine.AnalogInputs(cur_input).SourceParameters{i}), 'uint32');
        fwrite(fid, machine.AnalogInputs(cur_input).SourceParameters{i}, 'char*1');
    end
end %analog inputs loop

%Digital inputs
fwrite(fid, machine.NumDigitalInputs, 'uint32');
for cur_input = 1:machine.NumDigitalInputs,
    %Name
    fwrite(fid, length(machine.DigitalInputs(cur_input).Name), 'uint32'); fwrite(fid, machine.DigitalInputs(cur_input).Name, 'char*1');
    %Source name
    fwrite(fid, length(machine.DigitalInputs(cur_input).SourceName), 'uint32'); fwrite(fid, machine.DigitalInputs(cur_input).SourceName, 'char*1');
    %Source type
    fwrite(fid, length(machine.DigitalInputs(cur_input).SourceType), 'uint32'); fwrite(fid, machine.DigitalInputs(cur_input).SourceType, 'char*1');
    %Source rate
    fwrite(fid, machine.DigitalInputs(cur_input).SourceRate, 'double');
    %Keep samples -- how many samples to keep
    fwrite(fid, machine.DigitalInputs(cur_input).KeepSamples, 'double');
    %Save samples -- whether to store all of the samples read
    fwrite(fid, machine.DigitalInputs(cur_input).SaveSamples, 'uint8');
    %Default value
    fwrite(fid, machine.DigitalInputs(cur_input).DefaultValue, 'double');
    %Channel(s)
    fwrite(fid, length(machine.DigitalInputs(cur_input).Channel), 'uint32');
    fwrite(fid, machine.DigitalInputs(cur_input).Channel, 'uint32');
    %Source parameters
    fwrite(fid, length(machine.DigitalInputs(cur_input).SourceParameters), 'uint32');
    for i = 1:length(machine.DigitalInputs(cur_input).SourceParameters),
        fwrite(fid, length(machine.DigitalInputs(cur_input).SourceParameters{i}), 'uint32');
        fwrite(fid, machine.DigitalInputs(cur_input).SourceParameters{i}, 'char*1');
    end
end %digital inputs loop


%% Write variables information

%Condition variables
fwrite(fid, machine.NumConditionVars, 'uint32');
for cur_var = 1:machine.NumConditionVars,
    %Name
    fwrite(fid, length(machine.ConditionVars(cur_var).Name), 'uint32'); fwrite(fid, machine.ConditionVars(cur_var).Name, 'char*1');
    %Function
    fwrite(fid, length(machine.ConditionVars(cur_var).Function), 'uint32'); fwrite(fid, machine.ConditionVars(cur_var).Function, 'char*1');
    %Default value    
    fwrite(fid, length(machine.ConditionVars(cur_var).DefaultValue), 'uint32');
    if ~isempty(machine.ConditionVars(cur_var).DefaultValue),
        fwrite(fid, machine.ConditionVars(cur_var).DefaultValue, 'double');
    end
    %Editable
    fwrite(fid, machine.ConditionVars(cur_var).Editable, 'uint8');
end %condition variables loop

%Variables loop
var_names = fieldnames(machine.Vars);
fwrite(fid, length(var_names), 'uint32');
for cur_var = 1:length(var_names),
    %Name
    fwrite(fid, length(var_names{cur_var}), 'uint32'); fwrite(fid, var_names{cur_var}, 'char*1');
    %Type of variable defines how to save it to disk
    if isnumeric(machine.Vars.(var_names{cur_var})),
        %Is numeric, write array out
        fwrite(fid, 0, 'uint8');
        
        %# dimensions
        fwrite(fid, ndims(machine.Vars.(var_names{cur_var})), 'uint8');
        %Size of each dimension
        var_size = size(machine.Vars.(var_names{cur_var}));
        for i = 1:ndims(machine.Vars.(var_names{cur_var})), fwrite(fid, var_size(i), 'uint32'); end
        %Write all of the values (in serial order)
        fwrite(fid, machine.Vars.(var_names{cur_var})(:), 'double');
    elseif iscell(machine.Vars.(var_names{cur_var})),
        %Is a cell array, have to treat each element in turn
        fwrite(fid, 2, 'uint8');
        
        %# dimensions
        fwrite(fid, ndims(machine.Vars.(var_names{cur_var})), 'uint8');
        %Size of each dimension
        var_size = size(machine.Vars.(var_names{cur_var}));
        for i = 1:ndims(machine.Vars.(var_names{cur_var})), fwrite(fid, var_size(i), 'uint32'); end
        %Write all of the values (in serial order)
        for cur_ind = 1:numel(machine.Vars.(var_names{cur_var})),
            cur_cell_val = machine.Vars.(var_names{cur_var}){cur_ind};
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
            elseif islogical(cur_cell_var),
                fwrite(fid, 23, 'uint8'); %Logical data type in cell
                %# dimensions
                fwrite(fid, ndims(cur_cell_val), 'uint8');
                %Size of each dimension
                var_size = size(cur_cell_val);
                for i = 1:ndims(cur_cell_val), fwrite(fid, var_size(i), 'uint32'); end
                %Write all of the values (in serial order)
                fwrite(fid, cur_cell_val(:), 'ubit1');
            else
                error('Cell arrays must either be of character strings or matrices.  Nested cell arrays not supported.');
            end
        end
    elseif ischar(machine.Vars.(var_names{cur_var})),
        %Character string
        fwrite(fid, 1, 'uint8');
        
        fwrite(fid, length(machine.Vars.(var_names{cur_var})), 'uint32');
        fwrite(fid, machine.Vars.(var_names{cur_var}), 'char*1');
    elseif islogical(machine.Vars.(var_names{cur_var})),
        %Is logical, write array out
        fwrite(fid, 3, 'uint8');
        
        %# dimensions
        fwrite(fid, ndims(machine.Vars.(var_names{cur_var})), 'uint8');
        %Size of each dimension
        var_size = size(machine.Vars.(var_names{cur_var}));
        for i = 1:ndims(machine.Vars.(var_names{cur_var})), fwrite(fid, var_size(i), 'uint32'); end
        %Write all of the values (in serial order)
        fwrite(fid, machine.Vars.(var_names{cur_var})(:), 'ubit1');
    else
        fwrite(fid, 255, 'uint8'); %this means an unknown data type
    end
end %variables loop