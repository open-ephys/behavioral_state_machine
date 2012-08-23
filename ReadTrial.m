function [trial, err] = ReadTrial(fid)

% Reads from the provided trial information to the file.  File is assumed
% to be opened with read permissions ** and be at the correct location **.
%
% Created 5/16/12 -- TJB

%Trial variables
% NumStates = 1;
% Condition = [];
% Block = [];
% States = machine(cur_machine).CurrentState;
% Times = machine(cur_machine).States(machine(cur_machine).CurrentState).EnterTime;


trial.NumStates = fread(fid, 1, 'uint32');
trial.Condition = fread(fid, 1, 'uint32');
trial.Block = fread(fid, 1, 'uint32');
trial.States = fread(fid, trial.NumStates, 'uint32');
trial.Times = fread(fid, trial.NumStates, 'double');