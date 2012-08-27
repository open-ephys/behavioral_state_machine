function DisplayMachine(machine)

% Function to display the state machine.
%
% Created TJB - 5/14/12
% Updated 7/5/12 TJB to add evaluation of transitions

%Define constants
EarlyResponseEndState = -5;
NoResponseEndState = -4;
IncorrectEndState = -3;
CorrectEndState = -2;
EndState = -1;
ITIState = 0;

%Variable to hold all variables
clear state_h;

%Some constants
state_h.CircleRadius = 5;
circle_angles = [0:(pi/100):2*pi];
state_h.CircleOffset = 20;
state_h.TextLabels = [];

%Create figure
figure;
set(gcf, 'Color', [1 1 1]);

%Center of state nodes
state_h.StateCenters(1, :) = state_h.CircleOffset*[1:machine.NumStates];
state_h.StateCenters(2, :) = 0;
state_h.Machine = machine;

%Plot all of the states
for cur_state = 1:machine.NumStates,
    
    %Draw circle for state
    state_h.StateObj(cur_state).Fill = patch(state_h.CircleRadius*sin(circle_angles) + state_h.StateCenters(1, cur_state), state_h.CircleRadius*cos(circle_angles) + state_h.StateCenters(2, cur_state), [0.9 0.9 0.9]); hold on;
    state_h.StateObj(cur_state).Outline = plot(state_h.CircleRadius*sin(circle_angles) + state_h.StateCenters(1, cur_state), state_h.CircleRadius*cos(circle_angles) + state_h.StateCenters(2, cur_state), '-', 'LineWidth', 2);
    if machine.States(cur_state).Interruptable,
        set(state_h.StateObj(cur_state).Outline, 'Color', [0.2 0.2 0.2]);
    else
        set(state_h.StateObj(cur_state).Outline, 'Color', [0 0 0]);
    end
    text(state_h.CircleOffset*cur_state, 0, sprintf('%d: %s', cur_state, machine.States(cur_state).Name), 'HorizontalAlignment', 'center', 'Color', [0 0 0]);
end

%Plot all of the transitions
for cur_state = 1:machine.NumStates,
    
    for cur_trans = 1:machine.States(cur_state).NumTransitions,
        connect_to = eval(machine.States(cur_state).Transitions(cur_trans).ToState);
        
        if connect_to < 0,
            %End trial
            start_pos = state_h.StateCenters(:, cur_state) + state_h.CircleRadius*[0 1]';
            end_pos = state_h.StateCenters(:, cur_state) + (cur_trans*0.5 + 1)*state_h.CircleRadius*[0 1]';
            
            switch connect_to,
                case CorrectEndState
                    arrowhead_color = [0 0.7 0];
                case IncorrectEndState
                    arrowhead_color = [0.7 0 0];
                case NoResponseEndState
                    arrowhead_color = [0.4 0.4 0.4];
                case EarlyResponseEndState
                    arrowhead_color = [0.3 0.3 0.8];
                otherwise
                    arrowhead_color = [0 0 0];
            end
            [state_h.StateObj(cur_state).Transitions{cur_trans}, arrow_points] = ...
                draw_arrow(start_pos, end_pos, 'MidlineOffset', 0, 'ArrowDirection', [0 1], 'ArrowShape', 1, ...
                'ArrowHeadSize', [0.1*state_h.CircleRadius 0.1*state_h.CircleRadius], 'ArrowHeadSizeUnits', 0, 'ArrowHeadColor', arrowhead_color);
        elseif connect_to == cur_state,
            %Connect back onto oneself
            start_pos = state_h.StateCenters(:, cur_state) + state_h.CircleRadius*[0.05 -1]';
            end_pos = state_h.StateCenters(:, cur_state) + state_h.CircleRadius*[-0.05 -1]';
            control_pos(:, 1) = state_h.StateCenters(:, cur_state) + state_h.CircleRadius*[1 -2]';
            control_pos(:, 2) = state_h.StateCenters(:, cur_state) + state_h.CircleRadius*[-1 -2]';
            
            [state_h.StateObj(cur_state).Transitions{cur_trans}, arrow_points] = ...
                draw_arrow(start_pos, end_pos, 'ControlPoints', control_pos, 'ArrowDirection', [1 0]);
        else
            %Connect forward or backward
            cur_angle = pi/2 - atan(0.5*(connect_to - cur_state));
            start_pos = state_h.StateCenters(:, cur_state) + state_h.CircleRadius*[sin(cur_angle) cos(cur_angle)]';
            end_pos = state_h.StateCenters(:, connect_to) + state_h.CircleRadius*[-sin(cur_angle) cos(cur_angle)]';
            
            [state_h.StateObj(cur_state).Transitions{cur_trans}, arrow_points] = ...
                draw_arrow(start_pos, end_pos, 'ArrowDirection', [0 1]);
        end
        
        % Label of each transition will be displayed at these coordinates
        if mean(arrow_points(2, :)) >= state_h.StateCenters(2, cur_state),
            state_h.StateObj(cur_state).TransitionCenter(:, cur_trans) = [mean(arrow_points(1, :)) max(arrow_points(2, :))];
        else
            state_h.StateObj(cur_state).TransitionCenter(:, cur_trans) = [mean(arrow_points(1, :)) min(arrow_points(2, :))];
        end
    end %transition loop
end %state loop

axis image;
axis off;

%Set callback function in response to click
set(gcf, 'WindowButtonDownFcn', @ClickCallback);

%Set state handles to userdata
set(gcf, 'UserData', state_h);


function ClickCallback(src, evt)

state_h = get(src, 'UserData');

% Are text labels already displayed?  Turn them off
if ~isempty(state_h.TextLabels),
    delete(state_h.TextLabels);
    state_h.TextLabels = [];
end

% Get click and gather information
ch_axes = findobj(get(src, 'Children'), 'Type', 'axes');
set(ch_axes, 'Units', 'pixels'); set(src, 'Units', 'pixels');
cp = get(src, 'CurrentPoint');
ap = get(ch_axes, 'Position');

%Convert click position to axis values
click_pos = (cp(:)' - ap(1:2))./ap(3:4);
xlim = get(ch_axes, 'XLim'); ylim = get(ch_axes, 'YLim');
click_pos = click_pos.*[diff(xlim) diff(ylim)] + [xlim(1) ylim(1)];

%Is click in a boundary of any state
click_dist = sqrt(sum((state_h.StateCenters - repmat(click_pos(:), [1 size(state_h.StateCenters, 2)])).^2));
click_ind = find(click_dist <= state_h.CircleRadius);
if ~isempty(click_ind),
    state_h.TextLabels = DisplayTransitionLabels(click_ind(1), state_h);
end

%Update userdata
set(src, 'UserData', state_h);

function h = DisplayTransitionLabels(cur_state, state_h)

h = [];
for cur_trans = 1:state_h.Machine.States(cur_state).NumTransitions,
    
    h = cat(2, h, text(state_h.StateObj(cur_state).TransitionCenter(1, cur_trans), state_h.StateObj(cur_state).TransitionCenter(2, cur_trans), ...
        state_h.Machine.States(cur_state).Transitions(cur_trans).Logic, 'HorizontalAlignment', 'center', ...
        'BackgroundColor',[0.7 0.7 0.7], 'EdgeColor', 'k'));
end