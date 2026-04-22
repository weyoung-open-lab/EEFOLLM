function main_run_zoo_screening()
%MAIN_RUN_ZOO_SCREENING Step 2: run all 30 zoo algorithms under unified cfg; rank vs EEFOLLM.
%
% Prerequisites: set population/iterations/k/penalties in default_config.m (e.g. after
% main_tune_llm_sfo_map45). Uses cfg.exp.runs_per_map (20 is heavy; override runs below).
%
% Outputs:
%   results/zoo_screening/records.csv, zoo_screening.mat
%   results/zoo_screening/summary_vs_llm_eefo.csv, comparison_vs_llm_eefo.csv

root_dir = fileparts(mfilename('fullpath'));
addpath(fullfile(root_dir, 'config'));
addpath(fullfile(root_dir, 'utils'));
cfg = default_config();
init_paths(cfg.paths.root);
ensure_dir(cfg.paths.results);
out_dir = fullfile(cfg.paths.results, 'zoo_screening');
ensure_dir(out_dir);

map_list = generate_maps(cfg);
stage_weights_map = struct();
for i = 1:numel(map_list)
    feat = extract_map_features(map_list{i}, '');
    [sw, meta] = generate_llm_weights(feat, cfg, '');
    stage_weights_map.(map_list{i}.name) = sw;
    log_message(fullfile(cfg.paths.logs, 'zoo_screening.log'), ...
        sprintf('Map=%s llm_fallback=%d', map_list{i}.name, meta.used_fallback));
end

opts = struct();
opts.stage_weights_map = stage_weights_map;
opts.log_file = fullfile(cfg.paths.logs, 'zoo_screening.log');
opts.verbose_console = true;

% screening_runs = 3; % uncomment for quick smoke test (otherwise uses full paper budget)
screening_runs = cfg.exp.runs_per_map;
fprintf(1, 'Zoo screening: %d maps x %d algorithms x %d runs (this can take a long time).\n', ...
    numel(map_list), numel(cfg.exp.algorithms_zoo30), screening_runs);

out = run_experiment_batch(cfg, map_list, cfg.exp.algorithms_zoo30, screening_runs, opts);
writetable(out.records, fullfile(out_dir, 'records.csv'));
save(fullfile(out_dir, 'zoo_screening.mat'), 'out', 'cfg');

summarize_zoo_screening(out.records, fullfile(out_dir, 'summary_vs_llm_eefo.csv'));
fprintf(1, 'Done. See %s\n', out_dir);
end
