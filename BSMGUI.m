function varargout = BSMGUI(varargin)
% BSMGUI MATLAB code for BSMGUI.fig
%      BSMGUI, by itself, creates a new BSMGUI or raises the existing
%      singleton*.
%
%      H = BSMGUI returns the handle to a new BSMGUI or the handle to
%      the existing singleton*.
%
%      BSMGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in BSMGUI.M with the given input arguments.
%
%      BSMGUI('Property','Value',...) creates a new BSMGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before BSMGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to BSMGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help BSMGUI

% Last Modified by GUIDE v2.5 24-Sep-2012 08:17:26

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @BSMGUI_OpeningFcn, ...
    'gui_OutputFcn',  @BSMGUI_OutputFcn, ...
    'gui_LayoutFcn',  [] , ...
    'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before BSMGUI is made visible.
function BSMGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to BSMGUI (see VARARGIN)

% Choose default command line output for BSMGUI
handles.output = hObject;

%Initialize some variables
handles.machine = [];
handles.doRunMachine = 0;
handles.doPauseMachine = 0;
handles.doStopMachine = 0;
handles.NextConditionSet = -1;

%Change panel background to 'stop' color
set([handles.ExecutePanel handles.text8 handles.text22 handles.text6 handles.text7 handles.text9 handles.text11 ...
    handles.text15 handles.text17 handles.text24 handles.text30 handles.CurrentTrialText handles.CurrentConditionText handles.StartTimeText ...
    handles.RunningTimeText handles.CycleRateText handles.EndTimeText handles.EndStateListTextLabel handles.EndStateListText handles.CondListTextLabel handles.CondListText], ...
    'BackgroundColor', get(handles.StopMachine, 'BackgroundColor'));

%Define end states
handles.EndStateConstants.EarlyResponseEndState = -5;
handles.EndStateConstants.NoResponseEndState = -4;
handles.EndStateConstants.IncorrectEndState = -3;
handles.EndStateConstants.CorrectEndState = -2;
handles.EndStateConstants.EndState = -1;

% Define handle sets for later use in GUI manipulation
handles.TopElements = [handles.text1 handles.BSMFilenameEdit handles.BrowseBSMButton handles.LoadBSMButton handles.ViewBSMButton handles.SaveBSMButton handles.ClearBSMButton];
handles.ExecutePanelElements = findobj(handles.ExecutePanel, '-depth', 1);

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes BSMGUI wait for user response (see UIRESUME)
% uiwait(handles.BSMFigure);


% --- Outputs from this function are returned to the command line.
function varargout = BSMGUI_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;



function BSMFilenameEdit_Callback(hObject, eventdata, handles)
% hObject    handle to BSMFilenameEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of BSMFilenameEdit as text
%        str2double(get(hObject,'String')) returns contents of BSMFilenameEdit as a double

handles.BSMFilename = get(hObject,'String');
% Update handles structure
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function BSMFilenameEdit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to BSMFilenameEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in LoadBSMButton.
function LoadBSMButton_Callback(hObject, eventdata, handles)
% hObject    handle to LoadBSMButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%Does BSM exist?
if ~isempty(handles.machine),
    % Include the desired Default answer
    choice = questdlg({'A Behavioral State Machine is already loaded.', '', 'Overwrite?'},...
        'Overwrite BSM?', 'Yes', 'No', 'No');
    if strcmpi(choice, 'Yes'),
        handles.machine = DestroyMachine(handles.machine);
    elseif strcmpi(choice, 'No'),
        return;
    end
end

%Load BSM
set(handles.StatusText, 'String', 'Loading machine...'); drawnow;
handles.machine = LoadBehavioralStateMachine(handles.BSMFilename);

%Initialize machine
set(handles.StatusText, 'String', 'Initializing machine...'); drawnow;
%Initialize machine, variables, and function calls
handles.machine = InitializeMachine(handles.machine);
handles.machine = InitializeVariables(handles.machine);
handles.machine = InitializeFunctionCalls(handles.machine);

%Set all fields
set(handles.StatusText, 'String', 'Setting fields...'); drawnow;
SetAllFields(hObject, handles);

%Enable buttons and turn on panels
set([handles.ViewBSMButton handles.ClearBSMButton handles.SaveBSMButton], 'Enable', 'on');
set(handles.ExecutePanel, 'Visible', 'on');

%Check to see if we should display the condition set panel
if handles.machine.NumConditionSets > 1,
    %Turn on panel
    set(handles.CondSetPanel, 'Visible', 'on');
    %Sort (from left to right) and then initialize buttons
    CondSetButtons = findobj('Tag', 'CondSetToggleButton');
    CondSetButtonsPosition = cell2mat(get(CondSetButtons, 'Position'));
    [~, sort_ind] = sort(CondSetButtonsPosition(:, 1));
    CondSetButtons = CondSetButtons(sort_ind);
    %Enable/disable used condition sets
    set(CondSetButtons(1:min(5, handles.machine.NumConditionSets)), 'Visible', 'on', 'Enable', 'on');
    set(CondSetButtons((min(5, handles.machine.NumConditionSets)+1):5), 'Visible', 'on', 'Enable', 'off');
    %Set toggle state for first button
    set(CondSetButtons(1), 'Value', 1); set(CondSetButtons(2:end), 'Value', 0);
else
    set(handles.CondSetPanel, 'Visible', 'off');
end

%Check to see if we should display the condition set panel
if handles.machine.NumHotkeys > 0,
    %Turn on panel, resize figure?
    if ~strcmpi(get(handles.HotkeyPanel, 'Visible'), 'on'),
        set(handles.HotkeyPanel, 'Visible', 'on'); %turn on panel
        cur_panel_pos = get(handles.HotkeyPanel, 'Position'); %get size of panel
        %Adjust size of the overall figure
        cur_pos = get(findobj('Tag', 'BSMFigure'), 'Position');
        cur_pos([2 4]) = cur_pos([2 4]) + cur_panel_pos(4)*[-1 1];
        set(findobj('Tag', 'BSMFigure'), 'Position', cur_pos);
        %Move all of the top elements (outside ExecutePanel) up
        for i = 1:length(handles.TopElements),
            cur_pos = get(handles.TopElements(i), 'Position');
            cur_pos(2) = cur_pos(2) + cur_panel_pos(4);
            set(handles.TopElements(i), 'Position', cur_pos);
        end
        %Move all of the elements in ExecutePanel up
        for i = 1:length(handles.ExecutePanelElements),
            cur_pos = get(handles.ExecutePanelElements(i), 'Position');
            cur_pos(2) = cur_pos(2) + cur_panel_pos(4);
            set(handles.ExecutePanelElements(i), 'Position', cur_pos);
        end
        %Adjust ExecutePanel (need to downwardly adjust vertical position
        %since it was just moved up)
        cur_pos = get(handles.ExecutePanel, 'Position');
        cur_pos([2 4]) = cur_pos([2 4]) + cur_panel_pos(4)*[-1 1];
        set(handles.ExecutePanel, 'Position', cur_pos);
    end
    
    %Initialize hotkey state to false
    handles.doHotkey = false(min(5, handles.machine.NumHotkeys), 1);
    %Need to sort them from left to right
    HotkeyButtons = findobj('Tag', 'Hotkey');
    HotkeyButtonsPosition = cell2mat(get(HotkeyButtons, 'Position'));
    [~, sort_ind] = sort(HotkeyButtonsPosition(:, 1));
    HotkeyButtons = HotkeyButtons(sort_ind);
    %Name all of the hotkeys (hide others)
    for i = 1:min(5, handles.machine.NumHotkeys),
        set(HotkeyButtons(i), 'String', handles.machine.Hotkey(i).Name, 'Visible', 'on', 'Enable', 'on');
    end
    set(HotkeyButtons((min(5, handles.machine.NumHotkeys)+1):5), 'String', 'undefined', 'Visible', 'on', 'Enable', 'off');
else
    %Turn off panel, resize figure?
    if strcmpi(get(handles.HotkeyPanel, 'Visible'), 'on'),
        cur_panel_pos = get(handles.HotkeyPanel, 'Position'); %get size of panel
        %Adjust size of the overall figure
        cur_pos = get(findobj('Tag', 'BSMFigure'), 'Position');
        cur_pos([2 4]) = cur_pos([2 4]) - cur_panel_pos(4)*[-1 1];
        set(findobj('Tag', 'BSMFigure'), 'Position', cur_pos);
        %Move all of the top elements (outside ExecutePanel) down
        for i = 1:length(handles.TopElements),
            cur_pos = get(handles.TopElements(i), 'Position');
            cur_pos(2) = cur_pos(2) - cur_panel_pos(4);
            set(handles.TopElements(i), 'Position', cur_pos);
        end
        %Move all of the elements in ExecutePanel down
        for i = 1:length(handles.ExecutePanelElements),
            cur_pos = get(handles.ExecutePanelElements(i), 'Position');
            cur_pos(2) = cur_pos(2) - cur_panel_pos(4);
            set(handles.ExecutePanelElements(i), 'Position', cur_pos);
        end
        %Adjust ExecutePanel (need to upwardly adjust vertical position
        %since it was just moved down)
        cur_pos = get(handles.ExecutePanel, 'Position');
        cur_pos([2 4]) = cur_pos([2 4]) - cur_panel_pos(4)*[-1 1];
        set(handles.ExecutePanel, 'Position', cur_pos);
        %Turn off panel
        set(handles.HotkeyPanel, 'Visible', 'off');
    end
    %Initialize hotkey state to false
    handles.doHotkey = [];
end

set(handles.StatusText, 'String', '');
guidata(hObject, handles);


function SetAllFields(hObject, handles),

% Set values of fields from machine
set(handles.SubjectEdit, 'String', handles.machine.Subject);
set(handles.NumTrialsEdit, 'String', num2str(handles.machine.MaximumTrials));
set(handles.SaveFilenameEdit, 'String', handles.machine.SaveFilename);

%Editable variable names
var_names = cell(handles.machine.NumConditionVars, 1); var_values = cell(handles.machine.NumConditionVars, 1); var_editable = true(handles.machine.NumConditionVars, 1);
for i = 1:handles.machine.NumConditionVars,
    var_names{i} = handles.machine.ConditionVars(i).Name;
    var_values{i} = handles.machine.ConditionVars(i).Function;
    var_editable(i) = handles.machine.ConditionVars(i).Editable;
end
set(handles.VarPopup, 'String', var_names(var_editable), 'Value', 1);
set(handles.VarEdit, 'String', handles.machine.ConditionVars(find(var_editable, 1, 'first')).Function);

%Set condition/trial information
UpdateTrialText(handles, handles.machine);

%Set timers
UpdateStartText(handles, handles.machine);
UpdateRunningText(handles, handles.machine);

% Update handles structure
guidata(hObject, handles);


function ClearAllFields(hObject, handles),

% Set values of fields from machine
set(handles.SubjectEdit, 'String', '');
set(handles.NumTrialsEdit, 'String', 0);
set(handles.SaveFilenameEdit, 'String', '');

%Editable variable names
set(handles.VarPopup, 'String', {});
set(handles.VarEdit, 'String', '');

%Set condition/trial information
set(handles.CurrentTrialText, 'String', '0');
set(handles.CurrentConditionText, 'String', '0');

%Set timers
set(handles.StartTimeText, 'String', 'HH:MM:SS');
set(handles.RunningTimeText, 'String', 'HH:MM:SS');
set(handles.CycleRateText, 'String', 'XXXX Hz');

% Update handles structure
guidata(hObject, handles);



function UpdateTrialText(handles, machine),

set(handles.CurrentTrialText, 'String', num2str(machine.CurrentTrial));
set(handles.CurrentConditionText, 'String', num2str(machine.CurrentCondition));

% Update end state list text
num_trials_to_use = 15; cond_list = NaN*ones(1, num_trials_to_use); len = length(machine.TrialCondition);
cond_list(max(1, num_trials_to_use-len+1):num_trials_to_use) = machine.TrialCondition(max(1, len-num_trials_to_use+1):len);
cur_str = '';
for i = 1:length(cond_list),
    if ~isnan(cond_list(i)), cur_str = strcat(cur_str, sprintf('%d/', cond_list(i))); end
end
cur_str = cur_str(1:(end-1));
set(handles.CondListText, 'String', cur_str);
set(handles.CondListTextLabel, 'String', sprintf('Prev. Conditions [%d trials]', num_trials_to_use));

% Update end state list text
num_trials_to_use = 20; cur_str = ' '*ones(1, num_trials_to_use);
len = length(machine.TrialEndState);
cur_str(max(1, num_trials_to_use-len+1):num_trials_to_use) = machine.TrialEndState(max(1, len-num_trials_to_use+1):len);
cur_str(cur_str == handles.EndStateConstants.EarlyResponseEndState) = 'R'; %early response
cur_str(cur_str == handles.EndStateConstants.NoResponseEndState) = 'N'; %no response
cur_str(cur_str == handles.EndStateConstants.IncorrectEndState) = 'E'; %incorrect/error response
cur_str(cur_str == handles.EndStateConstants.CorrectEndState) = 'C'; %correct response
cur_str(cur_str == handles.EndStateConstants.EndState) = '?'; %Generic end of trial response
set(handles.EndStateListText, 'String', char(cur_str));
set(handles.EndStateListTextLabel, 'String', sprintf('End States: %3.0fC (%2.0f%%/%2.0f%%)', ...
    sum(machine.TrialEndState == handles.EndStateConstants.CorrectEndState), ...
    100*sum(machine.TrialEndState == handles.EndStateConstants.CorrectEndState)./sum(ismember(machine.TrialEndState, [handles.EndStateConstants.CorrectEndState handles.EndStateConstants.IncorrectEndState])), ...
    100*mean(machine.TrialEndState == handles.EndStateConstants.CorrectEndState)));

function UpdateStartText(handles, machine),

if ~isempty(machine.StartTime) & ~isnan(machine.StartTime),
    set(handles.StartTimeText, 'String', datestr(machine.StartTime, 'HH:MM:SS'));
end

function UpdateRunningText(handles, machine),

if ~isempty(machine.StartTime) & ~isnan(machine.StartTime),
    %Set running time
    running_time = now - machine.StartTime; %start and end time is still in 'now' format; everything else is from GetSecs
    set(handles.RunningTimeText, 'String', datestr(running_time, 'HH:MM:SS'));
    
    %Set cycle rate
    if ~isnan(machine.AverageTrialCycleLength) & ~isempty(machine.AverageTrialCycleLength),
        t = [machine.AverageTrialCycleLength machine.MinTrialCycleLength machine.MaxTrialCycleLength].*1000; %in ms
        set(handles.CycleRateText, 'String', sprintf('%4.0fHz [%4.0f:%4.0f]', 1000./t));
    end
    
    %Estimate and set finish time
    finish_time = running_time/machine.CurrentTrial*machine.MaximumTrials;
    set(handles.EndTimeText, 'String', datestr(finish_time, 'HH:MM:SS'));
end




% --- Executes on button press in RunMachine.
function RunMachine_Callback(hObject, eventdata, handles)
% hObject    handle to RunMachine (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if handles.doRunMachine,
    %Then user clicked button when it is a 'pause' button
    handles.doRunMachine = 1;
    handles.doPauseMachine = 1;
    handles.doStopMachine = 0;
    set(handles.StatusText, 'String', 'Machine is currently paused...');
    %Enable some of the buttons
    set([handles.VarPopup handles.NumTrialsEdit handles.VarEdit], 'Enable', 'on');
    %Update handle structure
    guidata(hObject, handles);
    return;
end
if handles.doPauseMachine,
    %Machine is currently paused and user clicked button.
    %Machine needs to be restarted, not initialized
    handles.doRunMachine = 1;
    handles.doPauseMachine = 0;
    handles.doStopMachine = 0;
    set(handles.StatusText, 'String', 'Running machine...');
    %Update handle structure
    guidata(hObject, handles);
    return;
end

%Make sure we are ready to run
if isempty(handles.machine.SaveFilename),
    error('Please specify a save file.');
end
if isempty(handles.machine.MaximumTrials) || isnan(handles.machine.MaximumTrials),
    error('Must define the number of trials to run first.');
end
if isempty(handles.machine.Subject),
    error('Please specify a subject.');
end
try
    if exist(handles.machine.SaveFilename, 'file'),
        choice = questdlg(sprintf('%s already exists.  Overwrite?', handles.machine.SaveFilename), ...
            'Overwrite file?', 'Yes', 'No', 'No');
        if strcmpi(choice, 'No'),
            return;
        end
    end
    handles.SaveFID = fopen(handles.machine.SaveFilename, 'w');
catch
    error('Couldn''t open file %s to save data.', handles.machine.SaveFilename);
end

%Get ready to run machine
handles.doRunMachine = 1;
handles.doPauseMachine = 0;
handles.doStopMachine = 0;
my_machine = handles.machine; %local copy of machine so it can be updated

%Open file for writing
WriteMachineHeader(handles.SaveFID, my_machine);

%Enable stop button
set(handles.StopMachine, 'enable', 'on');
%Change button to pause button
set(hObject, 'ForegroundColor', [0.165 0.275 0.384], 'BackgroundColor', [0.871 0.922 0.98], 'String', 'PAUSE');
%Set status text
set(handles.StatusText, 'String', 'Running machine...');
%Disable all of the buttons
set([handles.BSMFilenameEdit handles.BrowseBSMButton handles.LoadBSMButton handles.ViewBSMButton handles.SaveBSMButton handles.ClearBSMButton handles.SubjectEdit handles.SaveFilenameEdit], 'Enable', 'off');
set([handles.VarPopup handles.NumTrialsEdit handles.VarEdit], 'Enable', 'off');
%Change background of the execute panel to 'run' color
set([handles.ExecutePanel handles.text8 handles.text22 handles.text6 handles.text7 handles.text9 handles.text11 ...
    handles.text15 handles.text17 handles.text24 handles.text30 handles.CurrentTrialText handles.CurrentConditionText handles.StartTimeText ...
    handles.RunningTimeText handles.CycleRateText handles.EndTimeText handles.EndStateListTextLabel handles.EndStateListText handles.CondListTextLabel handles.CondListText], ...
    'BackgroundColor', [0.757 0.867 0.776]);

%Update handle structure
guidata(hObject, handles);

%Initialize state machine (get ready for first trial)
my_machine = InitializeMachineState(my_machine);

while (my_machine.Active) && (handles.doRunMachine) && (my_machine.CurrentTrial < my_machine.MaximumTrials),
    
    %Execute trial
    set(handles.StatusText, 'String', 'Executing trial...'); drawnow;
    try
        my_machine = ExecuteTrial(my_machine);
    catch errmsg
        set(handles.StatusText, 'String', 'ERROR in executing trial!'); drawnow;
        fprintf('ERROR: %s\n', errmsg.getReport);
        fprintf('Current trial: %d\n', my_machine.CurrentTrial);
        fprintf('Current condition: %d\n', my_machine.CurrentCondition);
        fprintf('Current state: %d\n', my_machine.CurrentStateID);
        my_machine.Active = 0;
        continue;
    end
    
    %Write trial to file
    WriteMachineTrial(handles.SaveFID, my_machine);
    set(handles.StatusText, 'String', 'Inter-trial interval...'); drawnow;
    
    %Can we interrupt the machine?
    if my_machine.Interruptable,
        %Get handles from GUI
        handles = guidata(hObject);
        
        %Update the GUI displays
        UpdateTrialText(handles, my_machine);
        UpdateStartText(handles, my_machine);
        UpdateRunningText(handles, my_machine);
        drawnow;
        
        %Check if user clicked a hotkey button
        my_machine.doHotkey = handles.doHotkey;
        if any(handles.doHotkey),
            for i = 1:length(handles.doHotkey),
                if handles.doHotkey(i),
                    eval(my_machine.Hotkey(i).Logic);
                    handles.doHotkey(i) = 0;
                end
            end
            guidata(hObject, handles);
        end
        
        %Check to see if we need to change condition set
        if handles.NextConditionSet >= 0,
            my_machine.CurrentConditionSet = handles.NextConditionSet;
            handles.NextConditionSet = -1;
            guidata(hObject, handles);
        end
        
        %Check if user wants to pause/stop machine
        if (handles.doStopMachine) || (handles.doPauseMachine),
            
            handles.doRunMachine = 0;
            if handles.doStopMachine,
                %Stop machine
                handles.doPauseMachine = 0;
                handles.doStopMachine = 0;
            end
            
            %Update the state machine the overall program has
            handles.machine = my_machine;
            
            %Update handles
            guidata(hObject, handles);
            
            %Should we pause in this state?
            if handles.doPauseMachine,
                %Change panel background to 'paused' color
                set([handles.ExecutePanel handles.text8 handles.text22 handles.text6 handles.text7 handles.text9 handles.text11 ...
                    handles.text15 handles.text17 handles.text24 handles.text30 handles.CurrentTrialText handles.CurrentConditionText handles.StartTimeText ...
                    handles.RunningTimeText handles.CycleRateText handles.EndTimeText handles.EndStateListTextLabel handles.EndStateListText handles.CondListTextLabel handles.CondListText], ...
                    'BackgroundColor', [0.871 0.922 0.98]);
                
                set(hObject, 'ForegroundColor', [0.165 0.384 0.275], 'BackgroundColor', [0.757 0.867 0.776], 'String', 'RUN');
                guidata(hObject, handles);
                drawnow;
                
                %Wait until flag is unset
                while handles.doPauseMachine,
                    pause(0.1);
                    handles = guidata(hObject);
                    if handles.doStopMachine,
                        %Stop machine
                        handles.doRunMachine = 0;
                        handles.doPauseMachine = 0;
                        handles.doStopMachine = 0;
                    end % user pressed 'stop' button while paused
                end % while still paused
                
                %Update the local machine with the global copy
                handles = guidata(hObject);
                my_machine = handles.machine;
                
                %Change background of the execute panel to 'run' color
                set([handles.ExecutePanel handles.text8 handles.text22 handles.text6 handles.text7 handles.text9 handles.text11 ...
                    handles.text15 handles.text17 handles.text24 handles.text30 handles.CurrentTrialText handles.CurrentConditionText handles.StartTimeText ...
                    handles.RunningTimeText handles.CycleRateText handles.EndTimeText handles.EndStateListTextLabel handles.EndStateListText handles.CondListTextLabel handles.CondListText], ...
                    'BackgroundColor', [0.757 0.867 0.776]);
                guidata(hObject, handles);
                drawnow;
            end %pause machine?
            
        end %should we stop/pause machine?
    end %is machine interruptable?
    
end %trial loop

%Finished running, clean up
set(handles.StatusText, 'String', 'Finished running.  Cleaning up...'); drawnow;
my_machine = DestroyMachine(my_machine);
WriteMachineFooter(handles.SaveFID, my_machine);
fclose(handles.SaveFID);
handles.machine = my_machine;

%Update handle structure
handles.doRunMachine = 0;
handles.doPauseMachine = 0;
handles.doStopMachine = 0;

%Re-enable all of the buttons
set([handles.BSMFilenameEdit handles.BrowseBSMButton handles.LoadBSMButton handles.ViewBSMButton handles.SaveBSMButton handles.ClearBSMButton handles.SubjectEdit handles.SaveFilenameEdit], 'Enable', 'on');
set([handles.VarPopup handles.NumTrialsEdit handles.VarEdit], 'Enable', 'on');
%Change button to run button
set(handles.StopMachine, 'enable', 'off');
set(hObject, 'ForegroundColor', [0.165 0.384 0.275], 'BackgroundColor', [0.757 0.867 0.776], 'String', 'RUN');
%Change background to 'stop' color
%Change panel background to 'stop' color
set([handles.ExecutePanel handles.text8 handles.text22 handles.text6 handles.text7 handles.text9 handles.text11 ...
    handles.text15 handles.text17 handles.text24 handles.text30 handles.CurrentTrialText handles.CurrentConditionText handles.StartTimeText ...
    handles.RunningTimeText handles.CycleRateText handles.EndTimeText handles.EndStateListTextLabel handles.EndStateListText handles.CondListTextLabel handles.CondListText], ...
    'BackgroundColor', get(handles.StopMachine, 'BackgroundColor'));
set(handles.StatusText, 'String', ''); drawnow;
guidata(hObject, handles);

% --- Executes on button press in ViewBSMButton.
function ViewBSMButton_Callback(hObject, eventdata, handles)
% hObject    handle to ViewBSMButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

DisplayMachine(handles.machine);

% --- Executes on button press in SaveBSMButton.
function SaveBSMButton_Callback(hObject, eventdata, handles)
% hObject    handle to SaveBSMButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%Get filename
[fn, pn, fi] = uiputfile({'*.bsm', 'Behavioral State Machine (*.bsm)'; '*.mat', 'MATLAB File (*.mat)'}, 'Save behavioral state machine...', handles.BSMFilename);
save_fn = sprintf('%s\\%s', pn, fn);

%Write machine
if fi == 1,
    %Write BSM file -- note this doesn't save any trial information, just
    %the general structure
    fid = fopen(save_fn, 'w');
    WriteMachineHeader(fid, handles.machine);
    WriteMachineFooter(fid, handles.machine);
    fclose(fid);
elseif fi == 2,
    %Write MAT file -- preferrable
    machine = handles.machine;
    save(save_fn, 'machine');
end


% --- Executes on button press in ClearBSMButton.
function ClearBSMButton_Callback(hObject, eventdata, handles)
% hObject    handle to ClearBSMButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%Does BSM exist?
if isempty(handles.machine),
    error('A behavioral state machine isn''t loaded to stop.');
else
    choice = questdlg('Are you sure you want to completely clear the current machine?',...
        'Clear BSM?', 'Yes', 'No', 'No');
    if strcmpi(choice, 'No'),
        return;
    end
end

%Destroy machine
set(handles.StatusText, 'String', 'Destroying machine...'); drawnow;
handles.machine = DestroyMachine(handles.machine);
handles.machine = [];

%Clear all fields
set(handles.StatusText, 'String', 'Clearing fields...'); drawnow;
ClearAllFields(hObject, handles);

%Enable buttons and turn on panels
set([handles.ViewBSMButton handles.ClearBSMButton handles.SaveBSMButton], 'Enable', 'off');
set(handles.ExecutePanel, 'Visible', 'off');

set(handles.StatusText, 'String', '');


function ChooseConditionEdit_Callback(hObject, eventdata, handles)
% hObject    handle to ChooseConditionEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of ChooseConditionEdit as text
%        str2double(get(hObject,'String')) returns contents of ChooseConditionEdit as a double

handles.machine.ChooseConditionFunction = get(hObject,'String');

% Update handles structure
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function ChooseConditionEdit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ChooseConditionEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function ChooseBlockEdit_Callback(hObject, eventdata, handles)
% hObject    handle to ChooseBlockEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of ChooseBlockEdit as text
%        str2double(get(hObject,'String')) returns contents of ChooseBlockEdit as a double

handles.machine.ChangeBlockFunction = get(hObject,'String');

% Update handles structure
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function ChooseBlockEdit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ChooseBlockEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function SubjectEdit_Callback(hObject, eventdata, handles)
% hObject    handle to SubjectEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of SubjectEdit as text
%        str2double(get(hObject,'String')) returns contents of SubjectEdit as a double

cur_str = get(hObject,'String');
if isempty(cur_str), set(handles.SubjectEdit, 'String', handles.machine.Subject); return; end
handles.machine.Subject = cur_str;

% Update handles structure
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function SubjectEdit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to SubjectEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function NumTrialsEdit_Callback(hObject, eventdata, handles)
% hObject    handle to NumTrialsEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of NumTrialsEdit as text
%        str2double(get(hObject,'String')) returns contents of NumTrialsEdit as a double

cur_str = get(hObject,'String');
if ~isempty(cur_str),
    cur_val = NaN;
    try cur_val = str2double(get(hObject,'String')); end
    if ~isnan(cur_val), handles.machine.MaximumTrials = cur_val; end
end
% Update handles structure
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function NumTrialsEdit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to NumTrialsEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in VarPopup.
function VarPopup_Callback(hObject, eventdata, handles)
% hObject    handle to VarPopup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns VarPopup contents as cell array
%        contents{get(hObject,'Value')} returns selected item from VarPopup

contents = cellstr(get(hObject,'String'));
cur_var_str = contents{get(hObject,'Value')};
handles.CondVarPopupSel = find(strcmp({handles.machine.ConditionVars(:).Name}, cur_var_str));
if isempty(handles.CondVarPopupSel), error('Couldn''t find the selected condition variable.'); end %should never happen
set(handles.VarEdit, 'String', handles.machine.ConditionVars(handles.CondVarPopupSel).Function);

% Update handles structure
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function VarPopup_CreateFcn(hObject, eventdata, handles)
% hObject    handle to VarPopup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function VarEdit_Callback(hObject, eventdata, handles)
% hObject    handle to VarEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of VarEdit as text
%        str2double(get(hObject,'String')) returns contents of VarEdit as a double

cur_str = get(hObject, 'String');
if isempty(handles.CondVarPopupSel), error('No condition variable is currently selected.'); end

%Set condition variable function string
handles.machine.ConditionVars(handles.CondVarPopupSel).Function = cur_str;

%Re-initialize all of the variables
handles.machine = InitializeVariables(handles.machine);

% Update handles structure
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function VarEdit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to VarEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in BrowseBSMButton.
function BrowseBSMButton_Callback(hObject, eventdata, handles)
% hObject    handle to BrowseBSMButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

[fn, pn, fi] = uigetfile({'*.xml', 'Behavioral State Machine File (*.xml)'; '*.m', 'Matlab Script File (*.m)'; '*.mat', 'Matlab Data File (*.mat)'});
if fi == 0, %Cancel was hit
    return;
elseif ismember(fi, [1:3]), %Chose a BSM/M/MAT file
    handles.BSMFilename = sprintf('%s%s', pn, fn);
    set(handles.BSMFilenameEdit, 'String', handles.BSMFilename);
    
    %Turn on the load button
    set(handles.LoadBSMButton, 'Enable', 'on');
    
    % Update handles structure
    guidata(hObject, handles);
end



function SaveFilenameEdit_Callback(hObject, eventdata, handles)
% hObject    handle to SaveFilenameEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of SaveFilenameEdit as text
%        str2double(get(hObject,'String')) returns contents of SaveFilenameEdit as a double

cur_str = get(hObject,'String');
if isempty(cur_str),
    cur_str = sprintf('%s_%s', handles.machine.Subject, datestr(now, 'mmddyy'));
    if exist(sprintf('%s.bsm', cur_str), 'file'),
        count = 1;
        test_str = sprintf('%s(%02.0f)', cur_str, count);
        while exist(sprintf('%s.bsm', test_str), 'file'),
            count = count + 1;
            test_str = sprintf('%s(%02.0f)', cur_str, count);
        end
        cur_str = test_str;
    end
end
[pathstr, name, ext] = fileparts(cur_str);
if isempty(ext),
    cur_str = fullfile(pathstr, [name '.bsm']);
end
handles.machine.SaveFilename = cur_str;
set(hObject, 'String', handles.machine.SaveFilename);

% Update handles structure
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function SaveFilenameEdit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to SaveFilenameEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in StopMachine.
function StopMachine_Callback(hObject, eventdata, handles)
% hObject    handle to StopMachine (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.doStopMachine = 1;
guidata(hObject, handles);

% --- Executes when user attempts to close BSMFigure.
function BSMFigure_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to BSMFigure (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%Does BSM exist?
if ~isempty(handles.machine),
    if handles.doRunMachine, return; end
    choice = questdlg('Are you sure you want to close the current machine?',...
        'Clear BSM?', 'Yes', 'No', 'No');
    if strcmpi(choice, 'No'),
        return;
    end
    %Destroy machine
    set(handles.StatusText, 'String', 'Destroying machine...'); drawnow;
    handles.machine = DestroyMachine(handles.machine);
    handles.machine = [];
end

%Clear all fields
set(handles.StatusText, 'String', 'Clearing fields...'); drawnow;
ClearAllFields(hObject, handles);

%Enable buttons and turn on panels
set([handles.ViewBSMButton handles.ClearBSMButton handles.SaveBSMButton], 'Enable', 'off');
set(handles.ExecutePanel, 'Visible', 'off');

set(handles.StatusText, 'String', '');

% Hint: delete(hObject) closes the figure
delete(hObject);


% --- Executes on button press in CondSetToggleButton.
function CondSetToggleButton_Callback(hObject, eventdata, handles)
% hObject    handle to CondSetToggleButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of CondSetToggleButton

if ~get(hObject, 'Value'), %already clicked
    set(hObject, 'Value', 1);
    return;
end
CondSetToggleButtons = findobj('Tag', 'CondSetToggleButton');
set(CondSetToggleButtons, 'Value', 0); set(hObject, 'Value', 1);
if strcmpi(get(hObject, 'String'), 'Baseline (0)'),
    %Clicked baseline button
    handles.NextConditionSet = 0;
else
    handles.NextConditionSet = eval(get(hObject, 'String'));
end
guidata(hObject, handles);

% --- Executes on button press in Hotkey.
function Hotkey_Callback(hObject, eventdata, handles)
% hObject    handle to Hotkey (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

for i = 1:handles.machine.NumHotkeys,
    if strcmpi(get(hObject, 'String'), handles.machine.Hotkey(i).Name),
        handles.doHotkey(i) = 1;
    end
end
guidata(hObject, handles);

