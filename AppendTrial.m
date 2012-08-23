function err = AppendTrial(fid, trial)

% Appends the provided trial information to the file.  File is assumed to
% be opened with write permissions.
%
% Created 5/16/12 -- TJB

%Trial variables
% NumStates = 1;
% Condition = [];
% Block = [];
% States = machine(cur_machine).CurrentState;
% Times = machine(cur_machine).States(machine(cur_machine).CurrentState).EnterTime;

if (numel(trial.NumStates) ~= 1) || (numel(trial.Condition) ~= 1) || ...
        (numel(trial.Block) ~= 1) || (numel(trial.States) ~= trial.NumStates) || (numel(trial.Times) ~= trial.NumStates),
    err = MException('BSM:AppendTrial:BadFormat', 'Inputs were not in correct format.');
end
try
    fwrite(fid, trial.NumStates, 'uint32');
    fwrite(fid, trial.Condition, 'uint32');
    fwrite(fid, trial.Block, 'uint32');
    fwrite(fid, trial.States, 'uint32');
    fwrite(fid, trial.Times, 'double');
catch err
end

