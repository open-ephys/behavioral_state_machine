function machine = InitializeVariables(machine)

% Initializes the variables structure.  Included variables are a
% combination of both condition variables as well as analog and digitial
% input variables.
%
% Created 6/11/12, TJB

machine.Vars = [];
machine.SaveVarValue = [];
machine.SaveVarTimestamp = [];

%Loop through condition variables
for i = 1:machine.NumConditionVars,
    if ~isempty(machine.ConditionVars(i).DefaultValue) && ~isnan(machine.ConditionVars(i).DefaultValue),
        machine.Vars.(machine.ConditionVars(i).Name) = machine.ConditionVars(i).DefaultValue;
    else
        machine.Vars.(machine.ConditionVars(i).Name) = [];
    end
end

%Loop through analog input variables, initialize them
for i = 1:machine.NumAnalogInputs,
    if isempty(machine.AnalogInputs(i).DefaultValue), machine.AnalogInputs(i).DefaultValue = NaN; end
    machine.Vars.(machine.AnalogInputs(i).Name) = machine.AnalogInputs(i).DefaultValue*...
        ones(machine.AnalogInputs(i).KeepSamples, length(machine.AnalogInputs(i).Channel));
    if machine.AnalogInputs(i).SaveSamples,
        machine.SaveVarValue.(machine.AnalogInputs(i).Name) = [];
        machine.SaveVarTimestamp.(machine.AnalogInputs(i).Name) = [];
    end
end

%Loop through digital input variables
for i = 1:machine.NumDigitalInputs,
    if isempty(machine.DigitalInputs(i).DefaultValue), machine.DigitalInputs(i).DefaultValue = NaN; end
    machine.Vars.(machine.DigitalInputs(i).Name) = machine.DigitalInputs(i).DefaultValue*ones(machine.DigitalInputs(i).KeepSamples, 1);
    if machine.DigitalInputs(i).SaveSamples,
        machine.SaveVarValue.(machine.DigitalInputs(i).Name) = [];
        machine.SaveVarTimestamp.(machine.DigitalInputs(i).Name) = [];
    end
end