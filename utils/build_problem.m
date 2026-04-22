function problem = build_problem(map_data, cfg, k_waypoints)
%BUILD_PROBLEM Build optimization problem struct for one map.
if nargin < 3 || isempty(k_waypoints)
    k_waypoints = cfg.path.default_k;
end
dim = 2 * k_waypoints;
lb = ones(1, dim);
ub = repmat([map_data.size(2), map_data.size(1)], 1, k_waypoints);
problem.dim = dim;
problem.lb = lb;
problem.ub = ub;
problem.fitness_handle = @fitness_pathplanning;
problem.map_data = map_data;
problem.k_waypoints = k_waypoints;
end
