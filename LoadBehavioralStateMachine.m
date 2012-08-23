function machine = LoadBehavioralStateMachine(state_filename)

% Loads behavioral state machine.
%
% 5/11/12 - TJB - very basic functionality.

%Parse filename
[~, ~, ext] = fileparts(state_filename);

%What type of file is passed?
if strcmpi(ext, '.mat'),
    %If a Matlab file, just load the machine
    load(state_filename, 'machine');
    return;
elseif strcmpi(ext, '.m'),
    %If an m-file, just run it to generate the machine
    run(state_filename);
    return;
elseif strcmpi(ext, '.xml'),
    %If a configuration file, need to load it and parse it
    machine = LoadXMLBSM(state_filename);
    return;
end