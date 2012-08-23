function DisplayBlocksConditions(machine)

% Function to graphically display the block and conditions for a given
% machine.  Need to load the condition file into a machine first.
%
% Created TJB - 5/14/12

if nargin ~= 1,
    error('Must pass a state machine to display.');
end

figure;
subplot(2,1,1);
title(sprintf('Block/Condition Diagram: Change Function = %s', machine.ChangeBlockFunction));

for cur_block = 1:machine.NumBlocks,
    for cur_condition = 1:machine.NumConditions,
        if ismember(cur_condition, machine.ConditionsInBlock{cur_block}),
            patch(cur_condition + [-1 -1 0 0] + 0.5, cur_block + [-1 0 0 -1] + 0.5, [0.2 0.4 0.9], 'EdgeColor', [0 0 0]);
        else
            patch(cur_condition + [-1 -1 0 0] + 0.5, cur_block + [-1 0 0 -1] + 0.5, [0.1 0.1 0.3], 'EdgeColor', [0 0 0]);
        end
    end
end
set(gca, 'XLim', [0 machine.NumConditions]+0.5, 'YLim', [0 machine.NumBlocks]+0.5, ...
    'XTick', [1:machine.NumConditions], 'YTick', [1:machine.NumBlocks]);
xlabel('Condition Number'); ylabel('Block Number');
set(gca, 'UserData', 'block');

%Set callback function in response to click
set(gcf, 'WindowButtonDownFcn', @ClickCallback);

%Set machine to userdata
set(gcf, 'UserData', machine);

%Create second axis to plot variables for different conditions
cond_axes = subplot(2,1,2);
DisplayConditionVariables(cond_axes, machine, 1);


function ClickCallback(src, evt)

machine = get(src, 'UserData');
ch_axes = findobj(get(src, 'Children'), 'Type', 'axes');
block_axes = ch_axes(find(strcmpi(get(ch_axes, 'UserData'), 'block'), 1, 'first'));
cond_axes = ch_axes(find(~strcmpi(get(ch_axes, 'UserData'), 'block'), 1, 'first'));
set(ch_axes, 'Units', 'pixels');
set(src, 'Units', 'pixels');
cp = get(src, 'CurrentPoint');
ap = get(block_axes, 'Position');
click_pos = cp(:)' - ap(1:2);

cur_condition = floor(click_pos(1)./ap(3)*machine.NumConditions)+1;
cur_block = floor(click_pos(2)./ap(4)*machine.NumBlocks)+1;

if ~((cur_condition <= 0) || (cur_condition > machine.NumConditions) || (cur_block <= 0) || (cur_block > machine.NumBlocks))
    DisplayConditionVariables(cond_axes, machine, cur_condition);
end



function DisplayConditionVariables(cond_axes, machine, cur_condition)

axes(cond_axes); cla;

condition_vars = fieldnames(machine.Conditions(cur_condition));

for i = 1:length(condition_vars),
    cur_var = machine.Conditions(cur_condition).(condition_vars{i});
    cur_var = cur_var./max(cur_var); 
    
    plot([1:length(cur_var)]./machine.DAQRate, cur_var + i - 0.5, 'k-'); hold on;
end
set(gca, 'YLim', [-0.5 length(condition_vars)+1], 'YTick', [1:length(condition_vars)]-0.5, 'YTickLabel', condition_vars);
title(sprintf('Variables for Condition %d, Change Function: %s', cur_condition, machine.ChooseConditionFunction));

