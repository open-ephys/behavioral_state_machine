function C = CalcBezierCurve(P, varargin)

% Function to estimate a bezier curve given the control points (first
% argument, must be DxN where D is the dimensionality and N is the number
% of control points.  Bezier curves always begin and end at the first and
% last control point.
%
% Optional parameters:
%   num_steps : specify the number of steps to take along curve.  
%   w         : specify the weighting of each control point.
%
% Created 5/15/12 by TJB.


N = size(P, 2) - 1;
if (N <= 0), error('Must pass in at least two control points.'); end
ndims = size(P, 1);
if ~isempty(varargin) & ~isempty(varargin{1}),
    num_steps = varargin{1};
else
    num_steps = 1000;
end
if (length(varargin) > 1) & ~isempty(varargin{2}),
    w = varargin{2};
    w = w(:);
else
    w = ones(N+1, 1);
end

%Initialize curve points
C = zeros(ndims, num_steps);
%Create matrix of binomial coefficients
B_const = NaN*ones(N+1, 1);
for i = 0:N,
    B_const(i+1) = nchoosek(N, i);
end
%Travel along the curve, finding points
for tind = 1:num_steps,
    t = (tind - 1)./(num_steps - 1);
    C(:, tind) = (P(:, :) * (B_const.*(t.^[0:N]').*((1-t).^(N-[0:N]')).*w))./sum(B_const.*(t.^[0:N]').*((1-t).^(N-[0:N]')).*w);
end
