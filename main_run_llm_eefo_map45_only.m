function main_run_llm_eefo_map45_only()
%MAIN_RUN_LLM_EEFO_MAP45_ONLY Same as llm_sfo_map45_only but optimizer is EEFO + LLM stage weights.
%
% Outputs:
%   results/llm_eefo_map45_smoke.mat, results/llm_eefo_map45_smoke.csv
%   results/llm_weights_Map4.json, llm_weights_Map5.json (same filenames as LLM-SFO run; shared weights)
%   figures/llm_eefo_map45_smoke/
%   logs/llm_eefo_map45_smoke.log

root_dir = fileparts(mfilename('fullpath'));
addpath(fullfile(root_dir, 'config'));
addpath(fullfile(root_dir, 'utils'));
cfg = default_config();
init_paths(cfg.paths.root);
ensure_dir(cfg.paths.results);
ensure_dir(cfg.paths.figures);
ensure_dir(cfg.paths.logs);
fig_dir = fullfile(cfg.paths.figures, 'llm_eefo_map45_smoke');
ensure_dir(fig_dir);

log_file = fullfile(cfg.paths.logs, 'llm_eefo_map45_smoke.log');
fprintf(1, '=== EEFOLLM: Map4 + Map5 only | pop=%d iter=%d k=%d ===\n', ...
    cfg.exp.population, cfg.exp.iterations, cfg.path.default_k);
drawnow;

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

stage_weights_map = struct();
for i = 1:numel(map_list)
    map_name = map_list{i}.name;
    fprintf(1, '--- %s | features + LLM weights ---\n', map_name);
    drawnow;
    feat = extract_map_features(map_list{i}, '');
    [sw, meta] = generate_llm_weights(feat, cfg, '');
    stage_weights_map.(map_name) = sw;
    save_json(fullfile(cfg.paths.results, ['llm_weights_', map_name, '.json']), sw);
    log_message(log_file, sprintf('Map=%s llm_fallback=%d', map_name, meta.used_fallback));
    fprintf(1, '    fallback=%d\n', meta.used_fallback);
    drawnow;
end

opts = struct();
opts.pop_size = cfg.exp.population;
opts.max_iter = cfg.exp.iterations;
opts.k_waypoints = cfg.path.default_k;
opts.stage_weights_map = stage_weights_map;
opts.log_file = log_file;
opts.verbose_console = true;

out = run_experiment_batch(cfg, map_list, {'EEFOLLM'}, cfg.exp.smoke_runs, opts);
save(fullfile(cfg.paths.results, 'llm_eefo_map45_smoke.mat'), 'out');
writetable(out.records, fullfile(cfg.paths.results, 'llm_eefo_map45_smoke.csv'));

algo_field = matlab.lang.makeValidName('EEFOLLM');
for i = 1:numel(map_list)
    map_name = map_list{i}.name;
    c = struct();
    c.(algo_field) = out.curves.(map_name).(algo_field);
    plot_convergence(c, fullfile(fig_dir, ['curve_', map_name]), ...
        ['EEFOLLM Convergence - ', map_name], cfg);
    p = struct();
    p.(algo_field) = out.best_paths.(map_name).(algo_field);
    plot_paths(map_list{i}, p, fullfile(fig_dir, ['path_', map_name]), ...
        ['EEFOLLM Best Path - ', map_name], cfg);
end

n = height(out.records);
ok = sum(out.records.CollisionFree);
fprintf(1, '=== Done. CollisionFree runs: %d / %d ===\n', ok, n);
fprintf(1, 'See results/llm_eefo_map45_smoke.csv and figures/llm_eefo_map45_smoke/\n');
end
