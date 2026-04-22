function main_run_algorithm_smoke()
%MAIN_RUN_ALGORITHM_SMOKE Quick smoke run for all 8 algorithms.
root_dir = fileparts(mfilename('fullpath'));
addpath(fullfile(root_dir, 'config'));
addpath(fullfile(root_dir, 'utils'));
cfg = default_config();
init_paths(cfg.paths.root);
map_list = generate_maps(cfg);

% Build LLM stage weights for each map (fallback safe).
stage_weights_map = struct();
for i = 1:numel(map_list)
    feat = extract_map_features(map_list{i}, '');
    [sw, ~] = generate_llm_weights(feat, cfg, '');
    stage_weights_map.(map_list{i}.name) = sw;
end

opts = struct();
opts.stage_weights_map = stage_weights_map;
opts.log_file = fullfile(cfg.paths.logs, 'algorithm_smoke.log');
out = run_experiment_batch(cfg, map_list(1), cfg.exp.algorithms, 1, opts);

save(fullfile(cfg.paths.results, 'algorithm_smoke.mat'), 'out');
writetable(out.records, fullfile(cfg.paths.results, 'algorithm_smoke.csv'));
end
