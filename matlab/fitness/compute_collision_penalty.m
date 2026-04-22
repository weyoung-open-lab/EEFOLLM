function C = compute_collision_penalty(path_pts, map_data, cfg)
%COMPUTE_COLLISION_PENALTY Collision and near-obstacle penalty.
grid_map = map_data.grid;
C = 0;
for i = 1:size(path_pts, 1) - 1
    p1 = path_pts(i, :);
    p2 = path_pts(i + 1, :);
    [collide, min_d] = line_collision_check(p1, p2, grid_map, cfg.path.sample_step);
    if collide
        C = C + cfg.penalty.collision_hard;
    else
        prox = max(0, cfg.penalty.min_obstacle_dist - min_d);
        C = C + cfg.penalty.obstacle_proximity * prox;
    end
end
end
