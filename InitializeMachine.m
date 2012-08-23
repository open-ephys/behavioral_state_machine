function machine = InitializeMachine(machine)

%Initializes behavioral control state machine.
%
% Created 5/16/12 by TJB

%% Set flag that DAQs are initialized
if machine.IsDAQInitialized,
    error('DAQs are already initialized.');
    return;
end
machine.IsDAQInitialized = 1;

%% Initialize DAQ sessions and objects for inputs

%Create session for analog inputs
if machine.NumAnalogInputs > 0,
[~,uniq_analog_inputs_ind,matching_analog_inputs] = unique(strcat({machine.AnalogInputs(:).SourceName}, {machine.AnalogInputs(:).SourceType}, {machine.AnalogInputs(:).SourceRate}));
machine.NumInputDAQSession = length(uniq_analog_inputs_ind);
for cur_ind = 1:length(uniq_analog_inputs_ind),
    %Establish session
    machine.InputDAQSession(cur_ind) = daq.createSession(machine.AnalogInputs(uniq_analog_inputs_ind(cur_ind)).SourceType);
    machine.InputDAQSession(cur_ind).Rate = machine.AnalogInputs(uniq_analog_inputs_ind(cur_ind)).SourceRate;
    machine.InputDAQSession(cur_ind).IsContinuous = 1;
    
    %Need to add all of the channels for this input device
    cur_matching_ind = find(matching_analog_inputs == cur_ind);
    for i = 1:length(cur_matching_ind),
        %Create the channel (and save it's handle and index)
        [machine.AnalogInputs(cur_matching_ind(i)).ChannelHandle, ...
            machine.AnalogInputs(cur_matching_ind(i)).ChannelIndex] = machine.InputDAQSession(cur_ind).addAnalogInputChannel(...
            machine.AnalogInputs(cur_matching_ind(i)).SourceName, ...
            machine.AnalogInputs(cur_matching_ind(i)).Channel, 'Voltage');
        
        set(machine.AnalogInputs(cur_matching_ind(i)).ChannelHandle, 'InputType', 'SingleEnded');
    end %matching channel loop
    %Save what DAQ source each variable should point to
    machine.AnalogInputs(cur_matching_ind).MatchingSource = cur_ind;
    
    machine.InputDAQSession(cur_ind).prepare();
end %unique analog input types loop
else
    machine.NumInputDAQSession = 0;
end


%Create DIO for inputs
if machine.NumDigitalInputs > 0,
    [~,uniq_digital_inputs_ind, matching_digital_inputs] = unique(strcat({machine.DigitalInputs(:).SourceName}, {machine.DigitalInputs(:).SourceType}, {machine.DigitalInputs(:).SourceRate}));
    machine.NumDigitalInputObject = length(uniq_digital_inputs_ind);
    for cur_ind = 1:length(uniq_digital_inputs_ind),
        %Establish session
        machine.DigitalInputObject(cur_ind) = digitalio(machine.DigitalInputs(uniq_digital_inputs_ind(cur_ind)).SourceType, ...
            machine.DigitalInputs(uniq_digital_inputs_ind(cur_ind)).SourceName);
        
        %Need to add all of the channels for this input device
        cur_matching_ind = find(matching_digital_inputs == cur_ind);
        num_chans = 0;
        for i = 1:length(cur_matching_ind),
            %Create the channel (and save it's handle and index)
            machine.DigitalInputs(cur_matching_ind(i)).ChannelHandle = ...
                addline(machine.DigitalInputObject(cur_ind), machine.DigitalInputs(cur_matching_ind(i)).Channel, 'in');
            machine.DigitalInputs(cur_matching_ind(i)).ChannelIndex = num_chans + [1:length(machine.DigitalInputs(cur_matching_ind(i)).Channel)];
            num_chans = num_chans + length(machine.DigitalInputs(cur_matching_ind(i)).Channel);
        end %matching channel loop
        
        %Save what DAQ source each variable should point to
        machine.DigitalInputs(cur_matching_ind).MatchingSource = cur_ind;
    end
else
    machine.NumDigitalInputObject = 0;
end

%% Initialize DAQ sessions and objects for outputs

%Create session for analog outputs
for cur_ind = 1:machine.NumAnalogOutputs,
    
    %Establish session
    machine.AnalogOutputs(cur_ind).DAQSession = daq.createSession(machine.AnalogOutputs(cur_ind).SourceType);
    machine.AnalogOutputs(cur_ind).DAQSession.Rate = machine.AnalogOutputs(cur_ind).SourceRate;
    
    [machine.AnalogOutputs(cur_ind).ChannelHandle, ...
        machine.AnalogOutputs(cur_matching_ind(i)).ChannelIndex] = ...
        machine.AnalogOutputs(cur_ind).DAQSession.addAnalogOutputChannel(...
        machine.AnalogOutputs(cur_ind).SourceName, ...
        machine.AnalogOutputs(cur_ind).Channel, 'Voltage');
    
    if isnan(machine.AnalogOutputs(cur_ind).DefaultValue), machine.AnalogOutputs(cur_ind).DefaultValue = 0; end
    machine.AnalogOutputs(cur_ind).DAQSession.outputSingleScan(machine.AnalogOutputs(cur_ind).DefaultValue.*ones(1, length(machine.AnalogOutputs(cur_ind).Channel)));
end %analog output loop

%Validate all of the state analog output variables
for state_ind = 1:machine.NumStates,
    for cur_ind = 1:machine.States(state_ind).NumAnalogOutput,
        cur_ao_index = find(strcmp({machine.AnalogOutputs(:).Name}, machine.States(state_ind).AnalogOutput(cur_ind).Channel));
        if isempty(cur_ao_index), error('State %d: %s will attempt to output to channel %s, which doesn''t exist.', ...
                state_ind, machine.States(state_ind).Name, machine.States(state_ind).AnalogOutput(cur_ind).Channel); end
        machine.States(state_ind).AnalogOutput(cur_ind).AOIndex = cur_ao_index;
    end
end

%Create DIO for outputs
for cur_ind = 1:machine.NumDigitalOutputs,    
    machine.DigitalOutputs(cur_ind).DigitalOutputObject = digitalio(machine.DigitalOutputs(cur_ind).SourceType, machine.DigitalOutputs(cur_ind).SourceName);
    addline(machine.DigitalOutputs(cur_ind).DigitalOutputObject, machine.DigitalOutputs(cur_ind).Channel, 'out');
    
    if isnan(machine.DigitalOutputs(cur_ind).DefaultValue), machine.DigitalOutputs(cur_ind).DefaultValue = 0; end
    putvalue(machine.DigitalOutputs(cur_ind).DigitalOutputObject, dec2binvec(machine.DigitalOutputs(cur_ind).DefaultValue, length(machine.DigitalOutputs(cur_ind).Channel)));
end %analog output loop

%Validate all of the state digital output variables
for state_ind = 1:machine.NumStates,
    for cur_ind = 1:machine.States(state_ind).NumDigitalOutput,
        cur_var_index = find(strcmp({machine.DigitalOutputs(:).Name}, machine.States(state_ind).DigitalOutput(cur_ind).Channel));
        if isempty(cur_var_index), error('State %d: %s will attempt to output to digital output variable %s, which doesn''t exist.', ...
                state_ind, machine.States(state_ind).Name, machine.States(state_ind).DigitalOutput(cur_ind).Channel); end
        machine.States(state_ind).DigitalOutput(cur_ind).DIOIndex = cur_var_index;
    end
end

%% Make sure the digital inputs and outputs don't collide

for cur_out_ind = 1:machine.NumDigitalOutputs,
    for cur_in_ind = 1:machine.NumDigitalInputObject,
        if strcmpi(machine.DigitalInputObject(cur_in_ind).Name, machine.DigitalOutputs(cur_out_ind).DigitalOutputObject.Name),
            in_ports = machine.DigitalInputObject(cur_in_ind).Line.Port;
            out_ports = machine.DigitalOutputs(cur_out_ind).DigitalOutputObject.Line.Port;
            if iscell(in_ports), in_ports = cell2mat(in_ports); end
            if iscell(out_ports), out_ports = cell2mat(out_ports); end            
            port_ind = find(ismember(in_ports, out_ports));
            for i = 1:length(port_ind),
                warning(sprintf('Port %d on device %s (%s) may not be line configurable.  You may have to move inputs/outputs to different ports.', ...
                    machine.DigitalInputObject(cur_in_ind).Line(port_ind).Port, machine.DigitalOutputs(cur_out_ind).SourceName, machine.DigitalOutputs(cur_out_ind).SourceType));
            end %port loop
        end
    end %input loop
end %output loop