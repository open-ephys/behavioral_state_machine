function machine = InitializeFunctionCalls(machine)

% Initializes the function calls to reference the variables structure (by
% substitution).
%
% Created 6/11/12, TJB

%Get list of variables
state_list = {machine.States(:).Name};
var_list = fieldnames(machine.Vars);
ListOfVariables;

% Check variables
for i = 1:length(var_list),
    if any(strcmp(var_list{i}, {machine_var_list{:}, 'machine', 'Vars'})),
        error('Cannot use some protected variable names.');
    end
    if sum(strcmp(var_list{i}, var_list)) > 1,
        error('Cannot use the same variable name twice.');
    end
end
for i = 1:length(state_list),
    if any(strcmp(state_list{i}, {machine_var_list{:}, 'machine', 'Vars'})),
        error('Cannot use some protected variable names in state names (can cause collisions when evaluating transitions).');
    end
    if sum(strcmp(state_list{i}, state_list)) > 1,
        error('Cannot use the same state name twice.');
    end
    if sum(strcmp(state_list{i}, var_list)) > 1,
        error('Cannot use a state name that matches a variable name (collisions can arise when evaluating transitions).');
    end
end

% Loop through condition function calls
for i = 1:machine.NumConditionVars,
    machine.ConditionVars(i).Function = ReplaceVariables(machine.ConditionVars(i).Function, var_list, machine_var_list);
end

% Parse the choose first condition function call
machine.FirstCondition = ReplaceVariables(machine.FirstCondition, var_list, machine_var_list);

% Parse the choose next condition function call
machine.ChooseNextCondition.Logic = ReplaceVariables(machine.ChooseNextCondition.Logic, var_list, machine_var_list);

% Parse the choose start state function call
machine.ChooseStartState.Logic = ReplaceVariables(machine.ChooseStartState.Logic, var_list, machine_var_list);

% Parse the transition functions for each state
for state_ind = 1:machine.NumStates,
    for trans_ind = 1:machine.States(state_ind).NumTransitions,
        %Parse and correct transition logic
        machine.States(state_ind).Transitions(trans_ind).Logic = ...
            ReplaceVariables(machine.States(state_ind).Transitions(trans_ind).Logic, var_list, machine_var_list);
        
        %Parse and correct state transition
        cur_trans_str = machine.States(state_ind).Transitions(trans_ind).ToState;
        
        %Extract variable strings
        [token_strings, token_extents] = regexp(cur_trans_str, '[^a-zA-Z]*(\w+)[^a-zA-Z]*', 'tokens', 'tokenExtents');
        
        %Check to see if state names are included
        for cur_token = 1:length(token_strings),
            match = strcmp(token_strings{cur_token}, state_list);
            if ~any(match), continue; end %not one of our states
            match_ind = find(match, 1, 'first');
            rep_str = sprintf('%d', machine.States(match_ind).ID);
            %Replace the name with the ID
            cur_trans_str = strcat(cur_trans_str(1:(token_extents{cur_token}(1)-1)), rep_str, cur_trans_str((token_extents{cur_token}(2)+1):end));
            rep_str_added_len = length(rep_str) - length(state_list{match_ind});
            for j = (cur_token+1):length(token_strings), token_extents{j} = token_extents{j} + rep_str_added_len; end
        end %token string loop
        
        %Update transitions string to new one, but also make sure to fix any
        %other variables
        machine.States(state_ind).Transitions(trans_ind).ToState = ReplaceVariables(cur_trans_str, var_list, machine_var_list);
        
    end %transition loop
    
    for analog_out_ind = 1:machine.States(state_ind).NumAnalogOutput,
        machine.States(state_ind).AnalogOutput(analog_out_ind).Data = ...
            ReplaceVariables(machine.States(state_ind).AnalogOutput(analog_out_ind).Data, var_list, machine_var_list);
    end %analog output loop
    
    for counter_out_ind = 1:machine.States(state_ind).NumCounterOutput,
        machine.States(state_ind).CounterOutput(counter_out_ind).Data = ...
            ReplaceVariables(machine.States(state_ind).CounterOutput(counter_out_ind).Data, var_list, machine_var_list);
    end %counter output loop
    
    for digital_out_ind = 1:machine.States(state_ind).NumDigitalOutput,
        machine.States(state_ind).DigitalOutput(digital_out_ind).Data = ...
            ReplaceVariables(machine.States(state_ind).DigitalOutput(digital_out_ind).Data, var_list, machine_var_list);
    end %digital output loop
    
    for exec_ind = 1:machine.States(state_ind).NumExecuteFunction,
        machine.States(state_ind).ExecuteFunction(exec_ind).Function = ...
            ReplaceVariables(machine.States(state_ind).ExecuteFunction(exec_ind).Function, var_list, machine_var_list);
    end %execute function list
end %state loop

end %initialize function calls function

function cur_func_str = ReplaceVariables(cur_func_str, var_list, machine_var_list)

%Extract variable strings
[token_strings, token_extents] = regexp(cur_func_str, '[^a-zA-Z'']*([''\w]+)[^a-zA-Z'']*', 'tokens', 'tokenExtents');

%Check to see if user-defined variables are included
for cur_token = 1:length(token_strings),
    match = strcmp(token_strings{cur_token}, var_list);
    if ~any(match), continue; end %not one of our variables
    match_ind = find(match, 1, 'first');
    rep_str = sprintf('machine.Vars.%s', var_list{match_ind});
    if strcmp(cur_func_str(max(1, token_extents{cur_token}(1) - length(rep_str) + length(var_list{match_ind})):token_extents{cur_token}(2)), ...
            rep_str), continue; end %already correct
    cur_func_str = [cur_func_str(1:(token_extents{cur_token}(1)-1)), rep_str, cur_func_str((token_extents{cur_token}(2)+1):end)];
    rep_str_added_len = length(rep_str) - length(var_list{match_ind});
    for j = (cur_token+1):length(token_strings), token_extents{j} = token_extents{j} + rep_str_added_len; end
end %token string loop

%Check to see if protected variables are included
for cur_token = 1:length(token_strings),
    match = strcmp(token_strings{cur_token}, machine_var_list);
    if ~any(match), continue; end %not one of our variables
    match_ind = find(match, 1, 'first');
    rep_str = sprintf('machine.%s', machine_var_list{match_ind});
    if strcmp(cur_func_str(max(1, token_extents{cur_token}(1) - length(rep_str) + length(machine_var_list{match_ind})):token_extents{cur_token}(2)), ...
            rep_str), continue; end %already correct
    cur_func_str = [cur_func_str(1:(token_extents{cur_token}(1)-1)), rep_str, cur_func_str((token_extents{cur_token}(2)+1):end)];
    rep_str_added_len = length(rep_str) - length(machine_var_list{match_ind});
    for j = (cur_token+1):length(token_strings), token_extents{j} = token_extents{j} + rep_str_added_len; end
end %token string loop
end %Replace variable function