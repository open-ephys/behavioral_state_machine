%Clear machine
clc; clear machine;

% Load machine
tic;
xml_file = 'BSM XML\BSM-test.xml';
xml_file = 'BSM XML\BSM-full.xml';
machine = LoadXMLBSM(xml_file);
fprintf('Time to load XML file: %5.2f ms.\n', 1000*toc);

%Initialize machine, variables, and function calls
tic;
machine = InitializeMachine(machine);
fprintf('Time to initialize machine: %5.2f ms.\n', 1000*toc);
tic;
machine = InitializeVariables(machine);
fprintf('Time to initialize variables: %5.2f ms.\n', 1000*toc);
tic;
machine = InitializeFunctionCalls(machine);
fprintf('Time to initialize functions: %5.2f ms.\n', 1000*toc);

tic;
machine = InitializeMachineState(machine);
fprintf('Time to initialize state machine (get ready for first trial): %5.2f ms.\n', 1000*toc);

%% Run trials
fclose all;
machine.SaveFilename = 'test.bsm';

%Open file for writing
tic
fid = fopen(machine.SaveFilename, 'w');
WriteMachineHeader(fid, machine);
fprintf('Time to write header for the file: %5.2f ms.\n', 1000*toc);
%profile on;
while machine.CurrentTrial < machine.MaximumTrials,
    machine = ExecuteTrial(machine);
    
    fprintf('Finished trial %d.\n', machine.CurrentTrial);
    fprintf('Did %d cycles last trial.\n', machine.TrialNumCycles);
    fprintf('Average cycle length last trial: %5.2f ms.\n', machine.AverageTrialCycleLength*1000);
    
    tic;
    %Write trial to file
    WriteMachineTrial(fid, machine);
    fprintf('Time to write trial data to file: %5.2f ms.\n', 1000*toc);
end
%profile off;

%% Clean-up

% Destroy machine
machine = DestroyMachine(machine);

tic;
%Write footer to file
WriteMachineFooter(fid, machine);
fprintf('Time to write footer data to file: %5.2f ms.\n', 1000*toc);
fclose(fid);

%% Read machine back in?

fid = fopen(machine.SaveFilename, 'r');
tmachine = ReadMachine(fid);
fclose(fid);
