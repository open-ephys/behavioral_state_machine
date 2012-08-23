function BSM_machines = LoadXMLBSM(xml_file)

% Loads a behavioral state machine defined by an XML file.
%
% These files use the BSM.xsd schema.
%
% Created: TJB 6/8/12

try
    xDoc = xmlread(xml_file);
catch err
    error('Failed to read XML file %s:\n%s\n', xml_file, err);
end

% Loop through machines
allMachines = xDoc.getElementsByTagName('machine');
for cur_machine = 1:allMachines.getLength,
    thisMachine = allMachines.item(cur_machine-1);
    
    %Initialize our BSM machine
    clear BSM_machine;
    BSM_machine.Name = char(thisMachine.getAttribute('Name'));
    if ~isempty(thisMachine.getAttribute('Subject')),
        BSM_machine.Subject = char(thisMachine.getAttribute('Subject'));
    else
        BSM_machine.Subject = '';
    end
    BSM_machine.Active = 0;
    BSM_machine.IsDAQInitialized = 0;
    BSM_machine.Interruptable = 0;
    BSM_machine.SaveFilename = '';
    BSM_machine.LastCycleStartTime = NaN;
    BSM_machine.LastCycleLength = 0; % Time (ms) of last cycle length
    BSM_machine.AverageTrialCycleLength = 0; % Average time to cycle for the last trial (ms)
    BSM_machine.TrialNumCycles = 0;
    BSM_machine.StartTime = NaN;
    BSM_machine.EndTime = NaN;
    if ~isempty(thisMachine.getAttribute('BSMVersion')),
        BSM_machine.BSMVersion = str2double(char(thisMachine.getAttribute('BSMVersion')));
    else
        BSM_machine.BSMVersion = 1.0;
    end
    if isnan(BSM_machine.BSMVersion), BSM_machine.BSMVersion = 1.0; end
    if ~isempty(thisMachine.getAttribute('ITILength')),
        BSM_machine.ITILength = str2double(char(thisMachine.getAttribute('ITILength')));
    else
        BSM_machine.ITILength = 0;
    end

    %State variables
    BSM_machine.CurrentStateID = 0; %ID of current state (starting with ITI)
    BSM_machine.CurrentStateName = ''; %Name of current state
    BSM_machine.TimeInState = 0; % Time entered current state
    BSM_machine.TimeEnterState = 0; % Time entered current state
    
    %Trial variables
    BSM_machine.TrialCondition = 0; %List of conditions used over all of the trials
    BSM_machine.TrialStartState = 0; %List of what states trials started with
    BSM_machine.TrialEndState = 0; %List of what states trials ended with (i.e. what transitioned to state -1)
    BSM_machine.TrialStateCount = 0; %Number of states visited during this trial
    BSM_machine.TrialStateList = {}; %List of state sequence for all trials
    BSM_machine.TrialStateEnterTimeList = {}; %List of times when entering each state for all trials
    BSM_machine.TrialStateExitTimeList = {}; %List of times when entering each state for all trials
    BSM_machine.CurrentTrial = 0;
    if ~isempty(thisMachine.getAttribute('MaximumTrials')),
        BSM_machine.MaximumTrials = str2double(char(thisMachine.getAttribute('MaximumTrials')));
    else
        BSM_machine.MaximumTrials = NaN;
    end   
    
    
    % Load conditions and related functions
    if ~isempty(thisMachine.getAttribute('NumConditions')),
        BSM_machine.NumConditions = str2double(char(thisMachine.getAttribute('NumConditions')));
    else
        BSM_machine.NumConditions = NaN;
    end
    if ~isempty(thisMachine.getAttribute('FirstCondition')),
        BSM_machine.FirstCondition = char(thisMachine.getAttribute('FirstCondition'));
    else BSM_machine.FirstCondition = '1'; end
    if isempty(BSM_machine.FirstCondition), BSM_machine.FirstCondition = '1'; end
    BSM_machine.CurrentCondition = 0;
    
    BSM_machine.ChooseNextCondition = ParseFunction(thisMachine.getElementsByTagName('ChooseNextCondition').item(0));
    BSM_machine.ChooseStartState = ParseFunction(thisMachine.getElementsByTagName('ChooseStartState').item(0));
    
    
    %Loop through states
    BSM_machine.States = [];
    machineStates = thisMachine.getElementsByTagName('State');
    for cur_state_ind = 1:machineStates.getLength,
        thisState = machineStates.item(cur_state_ind-1);
        
        clear cur_state;
        %Set attributes
        cur_state.Name = char(thisState.getAttribute('Name'));
        if ~isempty(thisState.getAttribute('ID')),
            cur_state.ID = str2double(char(thisState.getAttribute('ID')));
        else
            if isempty(BSM_machine.States), cur_state.ID = 1;
            else cur_state.ID = max([BSM_machine.States(:).ID])+1; end
        end
        cur_state.Interruptable = strcmpi(char(thisState.getAttribute('Interruptable')), 'true');
        
        %Load transitions
        stateTransitions = thisState.getElementsByTagName('Transition');
        if stateTransitions.getLength > 0,
            for cur_trans_ind = 1:stateTransitions.getLength,
                thisTransition = stateTransitions.item(cur_trans_ind-1);
                
                cur_trans = ParseFunction(thisTransition.getElementsByTagName('Logic').item(0));
                cur_trans.ToState = char(thisTransition.getAttribute('To'));
                
                cur_state.Transitions(cur_trans_ind) = cur_trans;
            end %transitions loop
            cur_state.NumTransitions = length(cur_state.Transitions);
        else
            cur_state.Transitions = [];
            cur_state.NumTransitions = 0;
        end
        
        %Load analog outputs
        stateAnalogOutputs = thisState.getElementsByTagName('AnalogOutput');
        if stateAnalogOutputs.getLength > 0,
            for cur_output_ind = 1:stateAnalogOutputs.getLength,
                thisAnalogOutput = stateAnalogOutputs.item(cur_output_ind-1);
                
                clear cur_output;
                cur_output.Channel = char(thisAnalogOutput.getAttribute('VarName'));
                cur_output.Data = char(thisAnalogOutput.getAttribute('Function'));
                if ~isempty(char(thisAnalogOutput.getAttribute('ForceStop'))),
                    cur_output.ForceStop = strcmpi(char(thisAnalogOutput.getAttribute('ForceStop')), 'true');
                else
                    cur_output.ForceStop = 0;
                end
                
                cur_state.AnalogOutput(cur_output_ind) = cur_output;
            end %analog output loop
            cur_state.NumAnalogOutput = length(cur_state.AnalogOutput);
        else
            cur_state.AnalogOutput = [];
            cur_state.NumAnalogOutput = 0;
        end
        
        %Load digital outputs
        stateDigitalOutputs = thisState.getElementsByTagName('DigitalOutput');
        if stateDigitalOutputs.getLength > 0,
            for cur_output_ind = 1:stateDigitalOutputs.getLength,
                thisDigitalOutput = stateDigitalOutputs.item(cur_output_ind-1);
                
                clear cur_output;
                cur_output.Channel = char(thisDigitalOutput.getAttribute('VarName'));
                cur_output.Data = char(thisDigitalOutput.getAttribute('Function'));
                cur_output.doStrobe = strcmpi(char(thisDigitalOutput.getAttribute('doStrobe')), 'true');
                cur_output.doTrue = strcmpi(char(thisDigitalOutput.getAttribute('doTrue')), 'true');
                
                cur_state.DigitalOutput(cur_output_ind) = cur_output;
            end %analog output loop
            cur_state.NumDigitalOutput = length(cur_state.DigitalOutput);
        else
            cur_state.DigitalOutput = [];
            cur_state.NumDigitalOutput = 0;
        end
        
        %Add to state list
        if isempty(BSM_machine.States),
            BSM_machine.States = struct(cur_state);
        end
        BSM_machine.States(cur_state.ID) = cur_state;
        
    end %state loop
    BSM_machine.NumStates = length(BSM_machine.States);
    
    % Any transitions defined outside of states (not typical)
    machineTransitions = thisMachine.getElementsByTagName('Transition');
    if machineTransitions.getLength > 0,
        for cur_trans_ind = 1:machineTransitions.getLength,
            thisTransition = machineTransitions.item(cur_trans_ind-1);
            
            %Check to make sure this is a direct child (and not in a state)
            if ~strcmpi(thisTransition.getParentNode.getNodeName, 'machine'),
                continue;
            end
            
            cur_trans = ParseFunction(thisTransition.getElementsByTagName('Logic').item(0));
            cur_trans.ToState = char(thisTransition.getAttribute('To'));
            cur_trans.FromState = str2double(char(thisTransition.getAttribute('From')));
            
            %Add to correct state
            cur_state_ind = find([BSM_machine.States(:).ID] == cur_trans.FromState);
            if isempty(cur_state_ind),
                error('Unassociated transition found.');
            else
                BSM_machine.States(cur_state_ind).Transitions(BSM_machine.States(cur_state_ind).NumTransitions + 1).Logic = ...
                    cur_trans.Logic;
                BSM_machine.States(cur_state_ind).Transitions(BSM_machine.States(cur_state_ind).NumTransitions + 1).ToState = ...
                    cur_trans.ToState;
                BSM_machine.States(cur_state_ind).NumTransitions = BSM_machine.States(cur_state_ind).NumTransitions + 1;
            end
        end %transitions loop
    end
            
    % Add analog/digital outputs
    machineAnalogOutputs = thisMachine.getElementsByTagName('AnalogOutput');
    if machineAnalogOutputs.getLength > 0,
        output_count = 0;
        for cur_output_ind = 1:machineAnalogOutputs.getLength,
            thisAnalogOutput = machineAnalogOutputs.item(cur_output_ind-1);
            
            %Check to make sure this is a direct child (and not in a state)
            if ~strcmpi(thisAnalogOutput.getParentNode.getNodeName, 'machine'),
                continue;
            end
            
            %Set output parameters
            clear cur_output;
            cur_output.Name = char(thisAnalogOutput.getAttribute('Name'));
            cur_output.SourceName = char(thisAnalogOutput.getAttribute('SourceName'));
            cur_output.SourceType = char(thisAnalogOutput.getAttribute('SourceType'));
            cur_output.SourceRate = str2double(char(thisAnalogOutput.getAttribute('SourceRate')));
            cur_output.DefaultValue = str2double(char(thisAnalogOutput.getAttribute('Name')));
            
            %Load channels
            cur_output.Channel = [];
            outputChannels = thisAnalogOutput.getElementsByTagName('Channel');
            for cur_channel_ind = 1:outputChannels.getLength,
                cur_output.Channel = cat(1, cur_output.Channel, ...
                    str2double(char(outputChannels.item(cur_channel_ind-1).getFirstChild.getData)));
            end
            
            %Load source parameters
            cur_output.SourceParameters = {};
            outputParameters = thisAnalogOutput.getElementsByTagName('SourceParameter');
            if outputParameters.getLength > 0,
                for cur_channel_ind = 1:outputParameters.getLength,
                    cur_output.SourceParameters.(outputChannels.item(cur_channel_ind-1).getAttribute('Key')) = ...
                        char(outputChannels.item(cur_channel_ind-1).getAttribute('Value'));
                end
            end
            
            output_count = output_count + 1;
            BSM_machine.AnalogOutputs(output_count) = cur_output;
        end %analog output loop
        BSM_machine.NumAnalogOutputs = length(BSM_machine.AnalogOutputs);
    else
        BSM_machine.AnalogOutputs = [];
        BSM_machine.NumAnalogOutputs = 0;
    end
    
    machineDigitalOutputs = thisMachine.getElementsByTagName('DigitalOutput');
    if machineDigitalOutputs.getLength > 0,
        output_count = 0;
        for cur_output_ind = 1:machineDigitalOutputs.getLength,
            thisDigitalOutput = machineDigitalOutputs.item(cur_output_ind-1);
            
            %Check to make sure this is a direct child (and not in a state)
            if ~strcmpi(thisDigitalOutput.getParentNode.getNodeName, 'machine'),
                continue;
            end
            
            %Set output parameters
            clear cur_output;
            cur_output.Name = char(thisDigitalOutput.getAttribute('Name'));
            cur_output.SourceName = char(thisDigitalOutput.getAttribute('SourceName'));
            cur_output.SourceType = char(thisDigitalOutput.getAttribute('SourceType'));
            cur_output.SourceRate = str2double(char(thisDigitalOutput.getAttribute('SourceRate')));
            cur_output.DefaultValue = str2double(char(thisDigitalOutput.getAttribute('Name')));
            
            %Load channels
            cur_output.Channel = [];
            outputChannels = thisDigitalOutput.getElementsByTagName('Channel');
            for cur_channel_ind = 1:outputChannels.getLength,
                cur_output.Channel = cat(1, cur_output.Channel, ...
                    str2double(char(outputChannels.item(cur_channel_ind-1).getFirstChild.getData)));
            end
            
            %Load source parameters
            cur_output.SourceParameters = {};
            outputParameters = thisDigitalOutput.getElementsByTagName('SourceParameter');
            if outputParameters.getLength > 0,
                for cur_channel_ind = 1:outputParameters.getLength,
                    cur_output.SourceParameters.(outputChannels.item(cur_channel_ind-1).getAttribute('Key')) = ...
                        char(outputChannels.item(cur_channel_ind-1).getAttribute('Value'));
                end
            end
            
            output_count = output_count + 1;
            BSM_machine.DigitalOutputs(output_count) = cur_output;
        end %digital output loop
        BSM_machine.NumDigitalOutputs = length(BSM_machine.DigitalOutputs);
    else
        BSM_machine.DigitalOutputs = [];
        BSM_machine.NumDigitalOutputs = 0;
    end
    
    %Load analog/digital input variables
    machineAnalogInputs = thisMachine.getElementsByTagName('AnalogInput');
    if machineAnalogInputs.getLength > 0,
        output_count = 0;
        for cur_output_ind = 1:machineAnalogInputs.getLength,
            thisAnalogOutput = machineAnalogInputs.item(cur_output_ind-1);
            
            %Check to make sure this is a direct child (and not in a state)
            if ~strcmpi(thisAnalogOutput.getParentNode.getNodeName, 'machine'),
                continue;
            end
            
            %Set output parameters
            clear cur_output;
            cur_output.Name = char(thisAnalogOutput.getAttribute('Name'));
            cur_output.SourceName = char(thisAnalogOutput.getAttribute('SourceName'));
            cur_output.SourceType = char(thisAnalogOutput.getAttribute('SourceType'));
            cur_output.SourceRate = str2double(char(thisAnalogOutput.getAttribute('SourceRate')));
            if isnan(cur_output.SourceRate), cur_output.SourceRate = 1000; end
            cur_output.KeepSamples = str2double(char(thisAnalogOutput.getAttribute('KeepSamples')));
            if isnan(cur_output.KeepSamples), cur_output.KeepSamples = 1; end
            cur_output.SaveSamples = strcmpi(char(thisAnalogOutput.getAttribute('SaveSamples')), 'true');
            cur_output.DefaultValue = str2double(char(thisAnalogOutput.getAttribute('Name')));
            
            %Load channels
            cur_output.Channel = [];
            outputChannels = thisAnalogOutput.getElementsByTagName('Channel');
            for cur_channel_ind = 1:outputChannels.getLength,
                cur_output.Channel = cat(1, cur_output.Channel, ...
                    str2double(char(outputChannels.item(cur_channel_ind-1).getFirstChild.getData)));
            end
            
            %Load source parameters
            cur_output.SourceParameters = {};
            outputParameters = thisAnalogOutput.getElementsByTagName('SourceParameter');
            if outputParameters.getLength > 0,
                for cur_channel_ind = 1:outputParameters.getLength,
                    cur_output.SourceParameters.(outputChannels.item(cur_channel_ind-1).getAttribute('Key')) = ...
                        char(outputChannels.item(cur_channel_ind-1).getAttribute('Value'));
                end
            end
            
            output_count = output_count + 1;
            BSM_machine.AnalogInputs(output_count) = cur_output;
        end %analog output loop
        BSM_machine.NumAnalogInputs = length(BSM_machine.AnalogInputs);
    else
        BSM_machine.AnalogInputs = [];
        BSM_machine.NumAnalogInputs = 0;
    end
    
    machineDigitalInputs = thisMachine.getElementsByTagName('DigitalInput');
    if machineDigitalInputs.getLength > 0,
        output_count = 0;
        for cur_output_ind = 1:machineDigitalInputs.getLength,
            thisDigitalOutput = machineDigitalInputs.item(cur_output_ind-1);
            
            %Check to make sure this is a direct child (and not in a state)
            if ~strcmpi(thisDigitalOutput.getParentNode.getNodeName, 'machine'),
                continue;
            end
            
            %Set output parameters
            clear cur_output;
            cur_output.Name = char(thisDigitalOutput.getAttribute('Name'));
            cur_output.SourceName = char(thisDigitalOutput.getAttribute('SourceName'));
            cur_output.SourceType = char(thisDigitalOutput.getAttribute('SourceType'));
            cur_output.SourceRate = str2double(char(thisDigitalOutput.getAttribute('SourceRate')));
            if isnan(cur_output.SourceRate), cur_output.SourceRate = 1000; end
            cur_output.KeepSamples = str2double(char(thisDigitalOutput.getAttribute('KeepSamples')));
            if isnan(cur_output.KeepSamples), cur_output.KeepSamples = 1; end
            cur_output.SaveSamples = strcmpi(char(thisAnalogOutput.getAttribute('SaveSamples')), 'true');
            cur_output.DefaultValue = str2double(char(thisDigitalOutput.getAttribute('Name')));
            
            %Load channels
            cur_output.Channel = [];
            outputChannels = thisDigitalOutput.getElementsByTagName('Channel');
            for cur_channel_ind = 1:outputChannels.getLength,
                cur_output.Channel = cat(1, cur_output.Channel, ...
                    str2double(char(outputChannels.item(cur_channel_ind-1).getFirstChild.getData)));
            end
            
            %Load source parameters
            cur_output.SourceParameters = {};
            outputParameters = thisDigitalOutput.getElementsByTagName('SourceParameter');
            if outputParameters.getLength > 0,
                for cur_channel_ind = 1:outputParameters.getLength,
                    cur_output.SourceParameters.(outputChannels.item(cur_channel_ind-1).getAttribute('Key')) = ...
                        char(outputChannels.item(cur_channel_ind-1).getAttribute('Value'));
                end
            end
            
            output_count = output_count + 1;
            BSM_machine.DigitalInputs(output_count) = cur_output;
        end %analog output loop
        BSM_machine.NumDigitalInputs = length(BSM_machine.DigitalInputs);
    else
        BSM_machine.DigitalInputs = [];
        BSM_machine.NumDigitalInputs = 0;
    end
    
    %Load condition variables
    machineConditionVars = thisMachine.getElementsByTagName('ConditionVar');
    if machineConditionVars.getLength > 0,
        for cur_var_ind = 1:machineConditionVars.getLength,
            thisVar = machineConditionVars.item(cur_var_ind-1);
            
            %Set output parameters
            clear cur_var;
            cur_var.Name = char(thisVar.getAttribute('Name'));
            cur_var.Function = char(thisVar.getAttribute('Function'));
            cur_var.DefaultValue = str2double(char(thisVar.getAttribute('DefaultValue')));
            
            BSM_machine.ConditionVars(cur_var_ind) = cur_var;
        end %analog output loop
        BSM_machine.NumConditionVars = length(BSM_machine.ConditionVars);
    else
        BSM_machine.ConditionVars = [];
        BSM_machine.NumConditionVars = 0;
    end
    
    BSM_machines(cur_machine) = BSM_machine;
end %machine loop

end

function func_struct = ParseFunction(cur_item)

if isempty(cur_item) || isempty(cur_item.getFirstChild),
    func_struct.Logic = '';
    func_struct.ParserName = '';
    func_struct.ParserCall = '';
else
    func_struct.Logic = char(cur_item.getFirstChild.getData);
    if ~isempty(cur_item.getAttribute('ParserName')),
        func_struct.ParserName = char(cur_item.getAttribute('ParserName'));
    else
        func_struct.ParserName = '';
    end
    if ~isempty(cur_item.getAttribute('ParserCall')),
        func_struct.ParserCall = char(cur_item.getAttribute('ParserCall'));
    else
        func_struct.ParserCall = '';
    end
    
end
end