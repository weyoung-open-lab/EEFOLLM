function main_run_sfo_smoke()
%MAIN_RUN_SFO_SMOKE Stage-2 quick verification for SFO on 5 maps.
root_dir = fileparts(mfilename('fullpath'));
addpath(fullfile(root_dir, 'config'));
addpath(fullfile(root_dir, 'utils'));
cfg = default_config();
init_paths(cfg.paths.root);
ensure_dir(cfg.paths.results); ensure_dir(cfg.paths.figures); ensure_dir(cfg.paths.logs);
fig_dir = fullfile(cfg.paths.figures, 'sfo_smoke');
ensure_dir(fig_dir);

map_list = generate_maps(cfg);
opts = struct();
opts.pop_size = cfg.exp.population;
opts.max_iter = cfg.exp.iterations;
opts.k_waypoints = cfg.path.default_k;
opts.log_file = fullfile(cfg.paths.logs, 'sfo_smoke.log');

out = run_experiment_batch(cfg, map_list, {'SFO'}, cfg.exp.smoke_runs, opts);
save(fullfile(cfg.paths.results, 'sfo_smoke.mat'), 'out');
writetable(out.records, fullfile(cfg.paths.results, 'sfo_smoke.csv'));

for i = 1:numel(map_list)
    map_name = map_list{i}.name;
    c.SFO = out.curves.(map_name).SFO;
    plot_convergence(c, fullfile(fig_dir, ['sfo_smoke_curve_', map_name]), ...
        ['SFO Convergence - ', map_name], cfg);
    p.SFO = out.best_paths.(map_name).SFO;
    plot_paths(map_list{i}, p, fullfile(fig_dir, ['sfo_smoke_path_', map_name]), ...
        ['SFO Best Path - ', map_name], cfg);
end
end
