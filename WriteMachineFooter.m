function err = WriteMachineFooter(fid, machine)

% Writes the footer for machine to the current file.  This should
% include all header information (followed by individual trial
% information).  File should be ended by writing footer (this function).
%
% Create 6/28/12 by TJB

%% Write tag to file identifying it as footer
fwrite(fid, 'FTR', 'char*1'); %This will be HDR and TRL for header and trial, respectively

%% Write end of file information

fwrite(fid, machine.CurrentTrial, 'double');
fwrite(fid, machine.MaximumTrials, 'double');
fwrite(fid, machine.EndTime, 'double');
