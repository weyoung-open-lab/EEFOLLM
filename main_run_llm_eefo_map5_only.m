function main_run_llm_eefo_map5_only(n_runs)
%MAIN_RUN_LLM_EEFO_MAP5_ONLY EEFOLLM on Map5 only (same pop/iter/K as cfg; mean BestFit over n_runs).
% Seeds align with full experiments: Map index 5, algorithm index 1 (EEFOLLM).
%
%   main_run_llm_eefo_map5_only          % uses cfg.exp.runs_per_map (e.g. 20)
%   main_run_llm_eefo_map5_only(30)      % override run count
%
% Output: results/llm_eefo_map5_only.csv, figures/llm_eefo_map5_only/, logs/llm_eefo_map5_only.log

if nargin < 1 || isempty(n_runs)
    n_runs = [];
end

root_dir = fileparts(mfilename('fullpath'));
addpath(fullfile(root_dir, 'config'));
addpath(fullfile(root_dir, 'utils'));
cfg = default_config();
init_paths(cfg.paths.root);
ensure_dir(cfg.paths.results);
ensure_dir(cfg.paths.figures);
ensure_dir(cfg.paths.logs);
fig_dir = fullfile(cfg.paths.figures, 'llm_eefo_map5_only');
ensure_dir(fig_dir);
log_file = fullfile(cfg.paths.logs, 'llm_eefo_map5_only.log');

if isempty(n_runs)
    n_runs = cfg.exp.runs_per_map;
end

fprintf(1, '=== EEFOLLM: Map5 only | runs=%d | pop=%d iter=%d k=%d ===\n', ...
    n_runs, cfg.exp.population, cfg.exp.iterations, cfg.path.default_k);

map_list_full = generate_maps(cfg);
map_list = {};
for i = 1:numel(map_list_full)
    if strcmp(map_list_full{i}.name, 'Map5')
        map_list{1} = map_list_full{i}; %#ok<NASGU>
        break;
    end
end
if isempty(map_list)
    error('Map5 not found in generate_maps output.');
end

map_name = map_list{1}.name;
fprintf(1, '--- %s | LLM weights ---\n', map_name);
feat = extract_map_features(map_list{1}, '');
[sw, meta] = generate_llm_weights(feat, cfg, '');
stage_weights_map = struct();
stage_weights_map.(map_name) = sw;
save_json(fullfile(cfg.paths.results, ['llm_weights_', map_name, '.json']), sw);
log_message(log_file, sprintf('Map=%s llm_fallback=%d', map_name, meta.used_fallback));

opts = struct();
opts.pop_size = cfg.exp.population;
opts.max_iter = cfg.exp.iterations;
opts.k_waypoints = cfg.path.default_k;
opts.stage_weights_map = stage_weights_map;
opts.log_file = log_file;
opts.verbose_console = true;
opts.seed_algo_offset = 0;
opts.force_map_seed_index = 5; % match Map5 seeds in full runs (mi=5)

out = run_experiment_batch(cfg, map_list, {'EEFOLLM'}, n_runs, opts);
out_csv = fullfile(cfg.paths.results, 'llm_eefo_map5_only.csv');
out_mat = fullfile(cfg.paths.results, 'llm_eefo_map5_only.mat');
writetable(out.records, out_csv);
save(out_mat, 'out', 'cfg', 'n_runs');

algo_field = matlab.lang.makeValidName('EEFOLLM');
c = struct();
c.(algo_field) = out.curves.(map_name).(algo_field);
plot_convergence(c, fullfile(fig_dir, 'curve_Map5'), ['EEFOLLM Convergence - Map5'], cfg);
p = struct();
p.(algo_field) = out.best_paths.(map_name).(algo_field);
plot_paths(map_list{1}, p, fullfile(fig_dir, 'path_Map5'), ['EEFOLLM Best Path - Map5'], cfg);

bf = out.records.BestFit;
fprintf(1, '=== Done. Mean BestFit=%.6g  Std=%.6g  Min=%.6g  Max=%.6g ===\n', ...
    mean(bf, 'omitnan'), std(bf, 0, 'omitnan'), min(bf), max(bf));
fprintf(1, 'CollisionFree rate: %.2f | see %s\n', mean(out.records.CollisionFree), out_csv);
end
