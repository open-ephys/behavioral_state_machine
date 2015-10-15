function machine = ReadMachine(fid)

% Reads a machine in from a BSM data file.
%
% Created 6/28/12 by TJB
tfid = [];
if ischar(fid) && exist(fid, 'file'),
    tfid = fid;
    fid = fopen(fid);
end

%Reset FID to beginning of the file
fseek(fid, 0, 'bof');

%Read header information
machine = ReadMachineHeader(fid);

% Iteratively try to read trial information
try
    trial_struct = ReadMachineTrial(fid);
    while ~isempty(trial_struct),
        machine.Trials(trial_struct.CurrentTrial) = trial_struct;
        trial_struct = ReadMachineTrial(fid);
    end
catch err
    beep;
    fprintf('Ran into error reading a BSM trial. Saving might have been aborted and therefore data may be corrupted.\n\t%s: %s\n', err.identifier, err.message);
end

%Read footer information
try
    machine = ReadMachineFooter(fid, machine);
catch err
    beep;
    fprintf('Ran into error reading the BSM footer. Saving might have been aborted and therefore data may be corrupted.\n\t%s: %s\n', err.identifier, err.message);
end

if ~isempty(tfid),
    fclose(fid);
end