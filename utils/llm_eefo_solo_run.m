function llm_eefo_solo_run(cfg, result_tag, algo_name)
%LLM_EEFO_SOLO_RUN EEFOLLM (or EEFOLLM-PARETO): 5 maps x runs_per_map (default 20).
%   Output folders: results/<result_tag>/, figures/<result_tag>/
%
%   Optional algo_name: 'EEFOLLM' (default) or 'EEFOLLM-PARETO' (NSGA-II); legacy alias LLM-EEFO still accepted.
%   See main_run_eefollm_benchmark, main_run_llm_eefo_pareto, main_run_llm_eefo_oaw.

if nargin < 3 || isempty(algo_name)
    algo_name = 'EEFOLLM';
end

root_dir = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root_dir, 'config'));
addpath(fullfile(root_dir, 'utils'));
init_paths(root_dir);

ensure_dir(cfg.paths.results);
ensure_dir(cfg.paths.figures);
ensure_dir(cfg.paths.logs);

res_dir = fullfile(cfg.paths.results, result_tag);
fig_dir = fullfile(cfg.paths.figures, result_tag);
wdir = fullfile(res_dir, 'weights');
mat_dir = fullfile(res_dir, 'mat');
ensure_dir(res_dir);
ensure_dir(fig_dir);
ensure_dir(wdir);
ensure_dir(mat_dir);

log_file = fullfile(cfg.paths.logs, [result_tag, '.log']);
use_oaw_cfg = isfield(cfg, 'online_adaptive') && cfg.online_adaptive.enable;
log_message(log_file, sprintf('=== EEFOLLM solo start | tag=%s | algo=%s | oaw=%d ===', ...
    result_tag, algo_name, use_oaw_cfg));

map_list = generate_maps(cfg);
stage_weights_map = struct();
meta_per_map = struct();
raw_runtime_copy = {};

for i = 1:numel(map_list)
    mn = map_list{i}.name;
    feat_path = fullfile(res_dir, ['features_', mn, '.json']);
    feat = extract_map_features(map_list{i}, feat_path);

    [sw, meta] = generate_llm_weights(feat, cfg, '');
    stage_weights_map.(mn) = sw;
    meta_per_map.(mn) = meta;

    save_json(fullfile(wdir, ['weights_llm_validated_', mn, '.json']), meta.weights_llm_validated);
    save_json(fullfile(wdir, ['weights_used_', mn, '.json']), sw);

    if isfile(cfg.llm.weight_json)
        dest_raw = fullfile(wdir, ['llm_runtime_raw_', mn, '.json']);
        try
            copyfile(cfg.llm.weight_json, dest_raw);
            raw_runtime_copy{end+1} = dest_raw; %#ok<AGROW>
        catch ME
            log_message(log_file, ['Copy runtime JSON failed: ', ME.message]);
        end
    end

    plot_weight_bars(meta.weights_llm_validated, fullfile(fig_dir, ['bars_llm_validated_', mn]), ...
        sprintf('LLM validated weights — %s', mn), cfg);
    plot_weight_bars(sw, fullfile(fig_dir, ['bars_weights_used_', mn]), ...
        sprintf('EEFOLLM — used weights — %s', mn), cfg);

    log_message(log_file, sprintf('Map=%s LLM_ok=%d fallback=%d msg=%s', ...
        mn, meta.llm_validation_ok, isfield(meta, 'used_fallback') && meta.used_fallback, meta.validation_msg));
end

opts = struct();
opts.stage_weights_map = stage_weights_map;
opts.log_file = log_file;
opts.verbose_console = true;
out = run_experiment_batch(cfg, map_list, {algo_name}, cfg.exp.runs_per_map, opts);

if strcmpi(algo_name, 'EEFOLLM-PARETO') || strcmpi(algo_name, 'LLM-EEFO-PARETO')
    nm = 'EEFOLLM-PARETO';
else
    nm = 'EEFOLLM';
end
if use_oaw_cfg
    tag_title = sprintf('%s + OAW', nm);
else
    tag_title = sprintf('%s (LLM stage weights)', nm);
end
for i = 1:numel(map_list)
    mn = map_list{i}.name;
    curves = out.curves.(mn);
    plot_convergence(curves, fullfile(fig_dir, ['conv_', mn]), ...
        sprintf('%s — Convergence — %s', tag_title, mn), cfg);
    pths = out.best_paths.(mn);
    plot_paths(map_list{i}, pths, fullfile(fig_dir, ['path_', mn]), ...
        sprintf('%s — Best Path — %s', tag_title, mn), cfg);
end

result_mat = fullfile(mat_dir, 'llm_eefo_solo_results.mat');
save(result_mat, 'out', 'cfg', 'map_list', 'stage_weights_map', 'meta_per_map', 'raw_runtime_copy', 'result_tag', '-v7.3');
if strcmp(result_tag, 'eefo_llm_pareto')
    save(fullfile(mat_dir, 'eefo_llm_pareto_results.mat'), 'out', 'cfg', 'map_list', 'stage_weights_map', 'meta_per_map', 'raw_runtime_copy', 'result_tag', 'algo_name', '-v7.3');
end
writetable(out.records, fullfile(res_dir, 'llm_eefo_solo_records.csv'));
if strcmp(result_tag, 'eefo_llm_pareto')
    writetable(out.records, fullfile(res_dir, 'eefo_llm_pareto_records.csv'));
end

log_message(log_file, '=== EEFOLLM solo done ===');
fprintf(1, '\nEEFOLLM solo finished | algo=%s | oaw=%d\nData: %s\nFigures: %s\n', ...
    algo_name, use_oaw_cfg, res_dir, fig_dir);
end
