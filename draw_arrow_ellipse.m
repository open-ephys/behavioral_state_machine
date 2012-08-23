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
min_len = sqrt(sum((start_pos - end_pos).^2));

% Parse optional inputs
opts.IntersectPoints = [];
opts.ArrowHeadSize = [0.03 0.06];
opts.ArrowHeadSizeUnits = 1; %0 - pixels; 1 - ratio of major axis
opts.CurveRatio = 2;
opts.ArrowDirection = [0 1]; % back/forward
opts.FillArrow = 1;
opts.AngleStep = pi/100;
opts.MajorAxisAngle = 0;
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

%Rotation matrix
R = [cos(opts.MajorAxisAngle) -sin(opts.MajorAxisAngle); sin(opts.MajorAxisAngle) cos(opts.MajorAxisAngle)];

%Add start/finish to points to fit
if ~isempty(opts.IntersectPoints) && (size(opts.IntersectPoints, 1) ~= 2),
    if (size(opts.IntersectPoints, 2) == 2),
        opts.IntersectPoints = opts.IntersectPoints';
    else
        error('Intersect points must be 2xN.');
    end
end
opts.IntersectPoints = cat(2, opts.IntersectPoints, start_pos(:), end_pos(:));
opts.IntersectPoints

%Apply inverse rotation (we'll re-rotate later)
opts.IntersectPoints = R*opts.IntersectPoints;

%Is curve_ratio non-zero?
if opts.CurveRatio == 0,
    %Just draw a straight line
    line_points(1, :) = linspace(start_pos(1), end_pos(1), 2*pi/opts.AngleStep);
    if start_pos(1) == end_pos(1), %Vertical line
        line_points(2, :) = linspace(start_pos(2), end_pos(2), 2*pi/opts.AngleStep);
    else
        p = polyfit([start_pos(1) end_pos(1)], [start_pos(2) end_pos(2)], 1);
        line_points(2, :) = polyval(p, line_points(1, :));
    end
    a = sqrt(sum((start_pos - end_pos).^2));
else
    %Fit ellipse to points
    x = fminsearch(@(x) EllipseEnergy(x, opts.IntersectPoints, opts.CurveRatio), ...
        [0 0 min_len min_len./opts.CurveRatio], optimset('Display', 'off', 'MaxIter', 10^5))
    opts.EllipseCenter = x(1:2);
    a = x(3); b = x(4);
    
    start_pos
    end_pos
    %What is the angle for the start/end point of the line?
    start_ang = fminbnd(@(x) sqrt(sum((start_pos(:) - EvalEllipse(x, opts.EllipseCenter(1), opts.EllipseCenter(2), a, b, 0)).^2)), 0, 2*pi)
    end_ang = fminbnd(@(x) sqrt(sum((end_pos(:) - EvalEllipse(x, opts.EllipseCenter(1), opts.EllipseCenter(2), a, b, 0)).^2)), 0, 2*pi)
    if abs(start_ang - end_ang) <= eps,
        end_ang = end_ang + opts.AngleStep;
    end
    %Create vector of points - We always proceed clockwise around ellipse
    line_points = EvalEllipse(start_ang + [0:opts.AngleStep:mod(end_ang - start_ang, 2*pi)], opts.EllipseCenter(1), opts.EllipseCenter(2), a, b, 0);
end

%Un-rotate points
line_points = R'*line_points;

%Plot points
h(1) = plot(line_points(1, :), line_points(2, :), 'k-');

if (opts.ArrowHeadSizeUnits == 1), %ratio of major axis
    opts.ArrowHeadSize = opts.ArrowHeadSize*a;
end

%Place arrowheads at ends?
if opts.ArrowDirection(1),
    %Draw one at beginning
    tip_dist = sqrt(sum((line_points - repmat(line_points(:, 1), [1 size(line_points, 2)])).^2, 1));
    [~,min_ind] = min(abs(tip_dist - sqrt(sum(opts.ArrowHeadSize.^2))));
    if (min_ind == 1), min_ind = 2; end
    arrowhead_angle = atan2(line_points(2, min_ind(1)) - line_points(2, 1), line_points(1, min_ind(1)) - line_points(1, 1));
    h = cat(1, h, DrawArrowhead(line_points(:, 1), opts.ArrowHeadSize(1), opts.ArrowHeadSize(2), arrowhead_angle, opts.FillArrow, opts.ArrowShape(1)));
end
if opts.ArrowDirection(2),
    %Draw one at end
    tip_dist = sqrt(sum((line_points - repmat(line_points(:, end), [1 size(line_points, 2)])).^2, 1));
    [~,min_ind] = min(abs(tip_dist - sqrt(sum(opts.ArrowHeadSize.^2))));
    if (min_ind == size(line_points, 2)), min_ind = size(line_points, 2) - 1; end
    arrowhead_angle = atan2(line_points(2, min_ind(1)) - line_points(2, end), line_points(1, min_ind(1)) - line_points(1, end));
    h = cat(1, h, DrawArrowhead(line_points(:, end), opts.ArrowHeadSize(1), opts.ArrowHeadSize(2), arrowhead_angle, opts.FillArrow, opts.ArrowShape(2)));
end


function h = DrawArrowhead(tip_point, width, height, angle, fill, shape)

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
    h = patch(all_points(1, :), all_points(2, :), [0 0 0]);
else
    h = patch(all_points(1, :), all_points(2, :), [0 0 0], 'FaceColor', 'none');
end


function x = EvalEllipse(tau, xc, yc, a, b, phi)
x(1, :) = xc + a*cos(tau(:))*cos(phi) - b*sin(tau(:))*sin(phi);
x(2, :) = yc + a*cos(tau(:))*sin(phi) - b*sin(tau(:))*cos(phi);

function err = EllipseEnergy(x, points, curve_ratio)

xc = x(1); yc = x(2);
a = x(3); b = x(4);

err = 0;

%Punish a/b not being at the right curve ratio
err = err + 10^4*abs(a - b*curve_ratio);

%Punish for not going through points
err = err + 10^2*sum((1 - (points(1, :)-xc).^2./a^2 - (points(2, :)-yc).^2./b^2).^2);

%Punish for having large axes
err = err + a^2 + b^2;% + 10^4*double(b > a);

%Punish for not having center near center of mass of points
err = err + 10^2*sqrt((xc - mean(points(1, :)))^2 + (yc - mean(points(2, :)))^2) + 10*abs(yc);
