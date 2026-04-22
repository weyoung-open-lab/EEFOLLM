function [has_collision, min_dist] = line_collision_check(p1, p2, grid_map, step)
%LINE_COLLISION_CHECK Check collision and obstacle distance on segment.
if nargin < 4, step = 0.5; end
cells = sample_line_cells(p1, p2, step);
rows = size(grid_map, 1);
cols = size(grid_map, 2);
has_collision = false;
min_dist = inf;
obs_idx = find(grid_map > 0);
[obs_r, obs_c] = ind2sub(size(grid_map), obs_idx);
obs_pts = [obs_c, obs_r];

for i = 1:size(cells, 1)
    x = cells(i, 1);
    y = cells(i, 2);
    if x < 1 || x > cols || y < 1 || y > rows
        has_collision = true;
        min_dist = 0;
        return;
    end
    if grid_map(y, x) > 0
        has_collision = true;
        min_dist = 0;
        return;
    end
    if ~isempty(obs_pts)
        d = sqrt(sum((obs_pts - [x, y]).^2, 2));
        min_dist = min(min_dist, min(d));
    end
end
if isinf(min_dist)
    min_dist = max(rows, cols);
end
end
