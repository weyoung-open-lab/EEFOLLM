function metrics = evaluate_path_metrics(path_pts, map_data, cfg)
%EVALUATE_PATH_METRICS Compute reporting metrics for one path.
L = compute_length(path_pts);
C = compute_collision_penalty(path_pts, map_data, cfg);
S = compute_smoothness(path_pts);
T = compute_turning_penalty(path_pts, cfg);

turn_angles = [];
for i = 2:size(path_pts, 1) - 1
    v1 = path_pts(i, :) - path_pts(i - 1, :);
    v2 = path_pts(i + 1, :) - path_pts(i, :);
    n1 = norm(v1); n2 = norm(v2);
    if n1 < eps || n2 < eps
        continue;
    end
    c = max(-1, min(1, dot(v1, v2) / (n1 * n2)));
    turn_angles(end + 1) = acosd(c); %#ok<AGROW>
end

metrics.path_length = L;
metrics.collision_penalty = C;
metrics.smoothness = S;
metrics.turning_penalty = T;
metrics.avg_turning_angle = mean(turn_angles, 'omitnan');
metrics.collision_free = C < cfg.penalty.collision_hard;
end
