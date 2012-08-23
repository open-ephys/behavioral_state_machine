function machine = ReadMachineFooter(fid, machine)

% Reads the footer for machine to the current file.
%
% Create 6/28/12 by TJB

%% Read tag identifying it as footer
tag = char(fread(fid, 3, 'char*1')');
if ~strcmpi(tag, 'FTR'),
    error('Couldn''t find footer for file.');
end

%% Read end of machine information

machine.CurrentTrial = fread(fid, 1, 'double');
machine.MaximumTrials = fread(fid, 1, 'double');
machine.EndTime = fread(fid, 1, 'double');
