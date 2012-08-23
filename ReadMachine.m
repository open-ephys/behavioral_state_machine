function machine = ReadMachine(fid)

% Reads a machine in from a BSM data file.
%
% Created 6/28/12 by TJB

%Read header information
machine = ReadMachineHeader(fid);

% Iteratively try to read trial information
trial_struct = ReadMachineTrial(fid);
while ~isempty(trial_struct),
    machine.Trials(trial_struct.CurrentTrial) = trial_struct;
    trial_struct = ReadMachineTrial(fid);
end

%Read footer information
machine = ReadMachineFooter(fid, machine);