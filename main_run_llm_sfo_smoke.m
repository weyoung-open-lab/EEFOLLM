function main_run_llm_sfo_smoke()
%MAIN_RUN_LLM_SFO_SMOKE Smoke test for LLM-SFO only (no baseline algorithms).
%
% LLM is used ONLY before optimization to produce stage-wise reward weights
% (early/mid/late) from map features. The SFO search loop is unchanged;
% only the fitness weighting schedule differs from plain SFO.
%
% Outputs:
%   results/llm_sfo_smoke.mat, results/llm_sfo_smoke.csv
%   results/llm_weights_<MapName>.json (per-map weights for inspection)
%   figures/llm_sfo_smoke/llm_sfo_smoke_*.png/.fig
%   logs/llm_sfo_smoke.log

root_dir = fileparts(mfilename('fullpath'));
addpath(fullfile(root_dir, 'config'));
addpath(fullfile(root_dir, 'utils'));
cfg = default_config();
init_paths(cfg.paths.root);
ensure_dir(cfg.paths.results);
ensure_dir(cfg.paths.figures);
ensure_dir(cfg.paths.logs);
fig_dir = fullfile(cfg.paths.figures, 'llm_sfo_smoke');
ensure_dir(fig_dir);

log_file = fullfile(cfg.paths.logs, 'llm_sfo_smoke.log');
status_path = fullfile(cfg.paths.logs, 'run_status.txt');
fid = fopen(status_path, 'w');
if fid > 0, fclose(fid); end
write_run_status(cfg, 'LLM-SFO smoke START. If Command Window is silent, open logs/run_status.txt and refresh.');
fprintf(1, '=== LLM-SFO smoke: loading maps ===\n');
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

fprintf(1, '=== Running LLM-SFO: %d maps x %d runs | pop=%d iter=%d ===\n', ...
    nmaps, cfg.exp.smoke_runs, cfg.exp.population, cfg.exp.iterations);
drawnow;
opts = struct();
opts.pop_size = cfg.exp.population;
opts.max_iter = cfg.exp.iterations;
opts.k_waypoints = cfg.path.default_k;
opts.stage_weights_map = stage_weights_map;
opts.log_file = log_file;
opts.verbose_console = true;

out = run_experiment_batch(cfg, map_list, {'LLM-SFO'}, cfg.exp.smoke_runs, opts);
fprintf(1, '=== Optimization done. Saving results ===\n');
drawnow;
save(fullfile(cfg.paths.results, 'llm_sfo_smoke.mat'), 'out');
writetable(out.records, fullfile(cfg.paths.results, 'llm_sfo_smoke.csv'));

algo_field = matlab.lang.makeValidName('LLM-SFO');
fprintf(1, '=== Plotting figures ===\n');
drawnow;
for i = 1:numel(map_list)
    map_name = map_list{i}.name;
    c = struct();
    c.(algo_field) = out.curves.(map_name).(algo_field);
    plot_convergence(c, fullfile(fig_dir, ['llm_sfo_smoke_curve_', map_name]), ...
        ['LLM-SFO Convergence - ', map_name], cfg);
    p = struct();
    p.(algo_field) = out.best_paths.(map_name).(algo_field);
    plot_paths(map_list{i}, p, fullfile(fig_dir, ['llm_sfo_smoke_path_', map_name]), ...
        ['LLM-SFO Best Path - ', map_name], cfg);
    fprintf(1, '    plotted %s\n', map_name);
    drawnow;
end
fprintf(1, '=== LLM-SFO smoke finished. See results/ and figures/llm_sfo_smoke/ ===\n');
end
