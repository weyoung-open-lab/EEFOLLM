function [F, parts, path_pts] = fitness_pathplanning(x, map_data, weights, cfg)
%FITNESS_PATHPLANNING Weighted path-planning objective.
%   F = wL*L + wC*C + wS*S + wT*T
path_pts = decode_path(x, map_data);
if cfg.path.enable_post_smooth
    path_pts = path_postprocess(path_pts, map_data.grid);
end
L = compute_length(path_pts);
C = compute_collision_penalty(path_pts, map_data, cfg);
S = compute_smoothness(path_pts);
T = compute_turning_penalty(path_pts, cfg);

F = weights.wL * L + weights.wC * C + weights.wS * S + weights.wT * T;
parts = struct('L', L, 'C', C, 'S', S, 'T', T);
end
