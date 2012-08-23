function machine = UpdateVariables(machine)

% Update the variables in the Var structure -- this involves reading from
% inputs and evaluating condition statements
%
% Created 6/12/12, TJB

%Loop through analog input variables
for i = 1:machine.NumConditionVars,
    machine.Vars.(machine.ConditionVars(i).Name) = eval(machine.ConditionVars(i).Function);
end

%Loop through digital input variables
for i = 1:machine.NumConditionVars,
    machine.Vars.(machine.ConditionVars(i).Name) = eval(machine.ConditionVars(i).Function);
end

%Loop through condition variables
for i = 1:machine.NumConditionVars,
    machine.Vars.(machine.ConditionVars(i).Name) = eval(machine.ConditionVars(i).Function);
end