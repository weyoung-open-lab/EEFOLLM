function main_run_llm_eefo_smoke()
%MAIN_RUN_LLM_EEFO_SMOKE LLM stage weights + EEFO on Map1–Map5 (same layout as main_run_llm_sfo_smoke).
%
% Outputs:
%   results/llm_eefo_smoke.mat, results/llm_eefo_smoke.csv
%   results/llm_weights_<MapName>.json
%   figures/llm_eefo_smoke/
%   logs/llm_eefo_smoke.log

root_dir = fileparts(mfilename('fullpath'));
addpath(fullfile(root_dir, 'config'));
addpath(fullfile(root_dir, 'utils'));
cfg = default_config();
init_paths(cfg.paths.root);
ensure_dir(cfg.paths.results);
ensure_dir(cfg.paths.figures);
ensure_dir(cfg.paths.logs);
fig_dir = fullfile(cfg.paths.figures, 'llm_eefo_smoke');
ensure_dir(fig_dir);

log_file = fullfile(cfg.paths.logs, 'llm_eefo_smoke.log');
status_path = fullfile(cfg.paths.logs, 'run_status.txt');
fid = fopen(status_path, 'w');
if fid > 0, fclose(fid); end
write_run_status(cfg, 'EEFOLLM smoke START. If Command Window is silent, open logs/run_status.txt and refresh.');
fprintf(1, '=== EEFOLLM smoke: loading Map1–Map5 ===\n');
fprintf(1, 'Tip: also watch logs\\run_status.txt (Notepad, F5 refresh) during long Python calls.\n');
drawnow;
map_list = generate_maps(cfg);

stage_weights_map = struct();
nmaps = numel(map_list);
for i = 1:nmaps
    map_name = map_list{i}.name;
    fprintf(1, '--- Map %d/%d: %s | features + LLM weights ---\n', i, nmaps, map_name);
    drawnow;
    feat = extract_map_features(map_list{i}, '');
    [sw, meta] = generate_llm_weights(feat, cfg, '');
    stage_weights_map.(map_name) = sw;
    save_json(fullfile(cfg.paths.results, ['llm_weights_', map_name, '.json']), sw);
    log_message(log_file, sprintf( ...
        'Map=%s llm_fallback=%d msg=%s', map_name, meta.used_fallback, meta.message));
    fprintf(1, '    weights saved | fallback=%d\n', meta.used_fallback);
    drawnow;
end

fprintf(1, '=== Running EEFOLLM: %d maps x %d runs | pop=%d iter=%d k=%d ===\n', ...
    nmaps, cfg.exp.smoke_runs, cfg.exp.population, cfg.exp.iterations, cfg.path.default_k);
drawnow;
opts = struct();
opts.pop_size = cfg.exp.population;
opts.max_iter = cfg.exp.iterations;
opts.k_waypoints = cfg.path.default_k;
opts.stage_weights_map = stage_weights_map;
opts.log_file = log_file;
opts.verbose_console = true;

out = run_experiment_batch(cfg, map_list, {'EEFOLLM'}, cfg.exp.smoke_runs, opts);
fprintf(1, '=== Optimization done. Saving results ===\n');
drawnow;
save(fullfile(cfg.paths.results, 'llm_eefo_smoke.mat'), 'out');
writetable(out.records, fullfile(cfg.paths.results, 'llm_eefo_smoke.csv'));

algo_field = matlab.lang.makeValidName('EEFOLLM');
fprintf(1, '=== Plotting figures ===\n');
drawnow;
for i = 1:numel(map_list)
    map_name = map_list{i}.name;
    c = struct();
    c.(algo_field) = out.curves.(map_name).(algo_field);
    plot_convergence(c, fullfile(fig_dir, ['llm_eefo_smoke_curve_', map_name]), ...
        ['EEFOLLM Convergence - ', map_name], cfg);
    p = struct();
    p.(algo_field) = out.best_paths.(map_name).(algo_field);
    plot_paths(map_list{i}, p, fullfile(fig_dir, ['llm_eefo_smoke_path_', map_name]), ...
        ['EEFOLLM Best Path - ', map_name], cfg);
    fprintf(1, '    plotted %s\n', map_name);
    drawnow;
end
n = height(out.records);
ok = sum(out.records.CollisionFree);
fprintf(1, '=== EEFOLLM smoke finished. CollisionFree %d / %d | results/llm_eefo_smoke.csv ===\n', ok, n);
end
