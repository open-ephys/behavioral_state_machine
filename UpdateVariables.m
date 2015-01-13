function machine = UpdateVariables(machine)

% Update the variables in the Var structure -- this involves reading from
% inputs and evaluating condition statements
%
% Created 6/12/12, TJB

% Loop through analog input variables
for i = 1:machine.NumInputDAQSession,
    x = machine.InputDAQSession(i).inputSingleScan;
    matching_vars = find([machine.AnalogInputs(:).MatchingSource] == i);
    for j = 1:length(matching_vars),
        cur_ind = matching_vars(j);
        machine.Vars.(machine.AnalogInputs(cur_ind).Name)(2:machine.AnalogInputs(cur_ind).KeepSamples, :) = ...
            machine.Vars.(machine.AnalogInputs(cur_ind).Name)(1:(machine.AnalogInputs(cur_ind).KeepSamples-1), :);
        machine.Vars.(machine.AnalogInputs(cur_ind).Name)(1, :) = x(machine.AnalogInputs(j).ChannelIndex);
    end %matching variable loop
end %analog input device loop

% Loop through digital input variables
for i = 1:machine.NumDigitalInputObject,
    x = getvalue(machine.DigitalInputObject(i));
    matching_vars = find([machine.DigitalInputs(:).MatchingSource] == i);
    for j = 1:length(matching_vars),
        cur_ind = matching_vars(j);
        machine.Vars.(machine.DigitalInputs(cur_ind).Name)(2:machine.DigitalInputs(cur_ind).KeepSamples) = ...
            machine.Vars.(machine.DigitalInputs(cur_ind).Name)(1:(machine.DigitalInputs(cur_ind).KeepSamples-1));
        machine.Vars.(machine.DigitalInputs(cur_ind).Name)(1) = binvec2dec(x(machine.DigitalInputs(j).ChannelIndex));
    end %matching variable loop
end %digital input object loop

% % Loop through condition variables
% for i = 1:machine.NumConditionVars,
%     machine.Vars.(machine.ConditionVars(i).Name) = eval(machine.ConditionVars(i).Function);
% end

% Update the time in state variable
machine.TimeInState = (GetSecs - machine.TimeEnterState)*1000; % Time (ms) in current state, multiplying by 24*60*60*1000 to get to ms
