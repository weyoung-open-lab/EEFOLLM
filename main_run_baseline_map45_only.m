function main_run_baseline_map45_only(algo_name)
%MAIN_RUN_BASELINE_MAP45_ONLY Same maps/budget/K as llm_sfo_map45_only, but a classic optimizer with static weights.
% Default is BA (Bat): simpler/weaker zoo baseline than PSO for contrast with LLM-SFO.
%
%   main_run_baseline_map45_only      % default BA
%   main_run_baseline_map45_only('PSO')
%   main_run_baseline_map45_only('FA')   % Firefly, another weak classic
%   main_run_baseline_map45_only('SFO')

if nargin < 1 || isempty(algo_name)
    algo_name = 'BA';
end

root_dir = fileparts(mfilename('fullpath'));
addpath(fullfile(root_dir, 'config'));
addpath(fullfile(root_dir, 'utils'));
cfg = default_config();
init_paths(cfg.paths.root);
ensure_dir(cfg.paths.results);
ensure_dir(cfg.paths.figures);
ensure_dir(cfg.paths.logs);

safe = matlab.lang.makeValidName(algo_name);
fig_dir = fullfile(cfg.paths.figures, ['baseline_map45_', safe]);
ensure_dir(fig_dir);
log_file = fullfile(cfg.paths.logs, ['baseline_map45_', safe, '.log']);

fprintf(1, '=== %s on Map4+Map5 only | pop=%d iter=%d k=%d (static weights) ===\n', ...
    algo_name, cfg.exp.population, cfg.exp.iterations, cfg.path.default_k);

map_list_full = generate_maps(cfg);
want = {'Map4', 'Map5'};
map_list = {};
for i = 1:numel(map_list_full)
    if any(strcmp(want, map_list_full{i}.name))
        map_list{end+1} = map_list_full{i}; %#ok<AGROW>
    end
end
if numel(map_list) ~= 2
    error('Need Map4 and Map5 in cfg.maps.names; found %d matches.', numel(map_list));
end

opts = struct();
opts.pop_size = cfg.exp.population;
opts.max_iter = cfg.exp.iterations;
opts.k_waypoints = cfg.path.default_k;
opts.log_file = log_file;
opts.verbose_console = true;

out = run_experiment_batch(cfg, map_list, {algo_name}, cfg.exp.smoke_runs, opts);

out_mat = fullfile(cfg.paths.results, ['baseline_map45_', safe, '_smoke.mat']);
out_csv = fullfile(cfg.paths.results, ['baseline_map45_', safe, '_smoke.csv']);
save(out_mat, 'out', 'cfg', 'algo_name');
writetable(out.records, out_csv);

algo_field = matlab.lang.makeValidName(algo_name);
for i = 1:numel(map_list)
    map_name = map_list{i}.name;
    c = struct();
    c.(algo_field) = out.curves.(map_name).(algo_field);
    plot_convergence(c, fullfile(fig_dir, ['curve_', map_name]), ...
        [algo_name, ' Convergence - ', map_name], cfg);
    p = struct();
    p.(algo_field) = out.best_paths.(map_name).(algo_field);
    plot_paths(map_list{i}, p, fullfile(fig_dir, ['path_', map_name]), ...
        [algo_name, ' Best Path - ', map_name], cfg);
end

n = height(out.records);
ok = sum(out.records.CollisionFree);
fprintf(1, '=== %s done. CollisionFree %d / %d | see %s ===\n', algo_name, ok, n, out_csv);
end
