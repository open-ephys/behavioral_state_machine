function [h, line_points] = draw_arrow(start_pos, end_pos, varargin)

%First draw an ellipse that goes from the start position to the end
%position.  The ratio of major/minor axis is given by curve_ratio.

%Error-check inputs
if (length(start_pos) ~= 2), 
    error('Starting position must be (x, y).');
end
if (length(end_pos) ~= 2), 
    error('Ending position must be (x, y).');
end

% Parse optional inputs
opts.ControlPoints = [];
opts.ControlPointWeights = [];
opts.NumSteps = 1000;
opts.MidlineOffset = 0.5;

opts.ArrowHeadSize = [0.03 0.06];
opts.ArrowHeadSizeUnits = 1; %0 - pixels; 1 - ratio of major axis
opts.ArrowDirection = [0 1]; % back/forward
opts.FillArrow = 1;
opts.ArrowHeadColor = [0 0 0];
opts.ArrowColor = [0 0 0];
opts.ArrowShape = [0 0]; %0-triangle, 1-rectangle

if mod(length(varargin), 2) ~= 0,
    error('Must pass optional variables in pairs.');
end
for i = 1:length(varargin)/2,
    try
        opts.(varargin{2*i-1}) = varargin{2*i};
    catch
        fprintf('No option %s.\n\nValid options are:\n', (varargin{2*i-1}));
        opts_fieldnames = fieldnames(opts);
        fprintf('\t%s\n', opts_fieldnames{:});
    end
end
if length(opts.ArrowShape) == 1, opts.ArrowShape = opts.ArrowShape*ones(size(opts.ArrowDirection)); end

% Add midline point if no control points were specified
len = sqrt(sum((start_pos - end_pos).^2));
if isempty(opts.ControlPoints),
    ang = atan2(end_pos(2) - start_pos(2), end_pos(1) - start_pos(1));
    
    %Rotation matrix for line between points
    R = [cos(ang) -sin(ang); sin(ang) cos(ang)];
    mid_point = [(len/2) (opts.MidlineOffset*len)]';
    opts.ControlPoints = R*mid_point + start_pos(:);
end
%Add start and end to control points
opts.ControlPoints = cat(2, start_pos(:), opts.ControlPoints, end_pos(:));

% Calculate Bezier curve
line_points = CalcBezierCurve(opts.ControlPoints, opts.NumSteps, opts.ControlPointWeights);

%Plot points
h(1) = plot(line_points(1, :), line_points(2, :), '-', 'Color', opts.ArrowColor);

if (opts.ArrowHeadSizeUnits == 1), %ratio of total curve length
    opts.ArrowHeadSize = opts.ArrowHeadSize*sum(sum(abs(diff(line_points, [], 2))));
end

%Place arrowheads at ends?
if opts.ArrowDirection(1),
    %Draw one at beginning
    tip_dist = sqrt(sum((line_points - repmat(line_points(:, 1), [1 size(line_points, 2)])).^2, 1));
    [~,min_ind] = min(abs(tip_dist - sqrt(sum(opts.ArrowHeadSize.^2))));
    if (min_ind == 1), min_ind = 2; end
    arrowhead_angle = atan2(line_points(2, min_ind(1)) - line_points(2, 1), line_points(1, min_ind(1)) - line_points(1, 1));
    h = cat(1, h, DrawArrowhead(line_points(:, 1), opts.ArrowHeadSize(1), opts.ArrowHeadSize(2), arrowhead_angle, opts.FillArrow, opts.ArrowShape(1), opts.ArrowHeadColor));
end
if opts.ArrowDirection(2),
    %Draw one at end
    tip_dist = sqrt(sum((line_points - repmat(line_points(:, end), [1 size(line_points, 2)])).^2, 1));
    [~,min_ind] = min(abs(tip_dist - sqrt(sum(opts.ArrowHeadSize.^2))));
    if (min_ind == size(line_points, 2)), min_ind = size(line_points, 2) - 1; end
    arrowhead_angle = atan2(line_points(2, min_ind(1)) - line_points(2, end), line_points(1, min_ind(1)) - line_points(1, end));
    h = cat(1, h, DrawArrowhead(line_points(:, end), opts.ArrowHeadSize(1), opts.ArrowHeadSize(2), arrowhead_angle, opts.FillArrow, opts.ArrowShape(2), opts.ArrowHeadColor));
end


function h = DrawArrowhead(tip_point, width, height, angle, fill, shape, color)

R = [cos(angle) -sin(angle); sin(angle) cos(angle)];

if shape == 0,
    %Draw a triangle
    all_points(1, :) = height*[0 1 1]; %zero (tip), plus left and right side
    all_points(2, :) = width/2*[0 1 -1]; %zero (tip), plus left and right side
    all_points = R*all_points + repmat(tip_point(:), [1 3]); %rotate and then move to tip
elseif shape == 1,
    %Draw a rectangle at end
    all_points(1, :) = height*[0 0 1 1]; %zero (front), zero (front), plus back edge
    all_points(2, :) = width/2*[-1 1 1 -1]; %front left, back left, back right, front right
    all_points = R*all_points + repmat(tip_point(:), [1 4]); %rotate and then move to tip
end

if fill,
    h = patch(all_points(1, :), all_points(2, :), color);
else
    h = patch(all_points(1, :), all_points(2, :), color, 'FaceColor', 'none');
end