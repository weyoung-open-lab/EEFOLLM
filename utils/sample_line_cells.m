function cells = sample_line_cells(p1, p2, step)
%SAMPLE_LINE_CELLS Sample grid cells along a line segment.
if nargin < 3, step = 0.5; end
d = norm(p2 - p1);
n = max(2, ceil(d / step) + 1);
t = linspace(0, 1, n)';
pts = p1 + t .* (p2 - p1);
cells = round(pts);
end
