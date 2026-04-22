function main_run_global_experiments_batch(batch_idx, force_rerun)
%MAIN_RUN_GLOBAL_EXPERIMENTS_BATCH Formal experiments in three chunks: 10 algorithms each (zoo30 order).
% Only EEFOLLM uses LLM-derived stage weights; all other algorithms use static cfg.weights.default.
% Python/LLM runs only in batch(es) where EEFOLLM appears (batch 1 with default zoo order).
%
%   main_run_global_experiments_batch(1)   % algos 1–10 (includes EEFOLLM: generate weights once per map)
%   main_run_global_experiments_batch(2)   % algos 11–20 — baselines only, no LLM calls
%   main_run_global_experiments_batch(3)   % algos 21–30 — baselines only, no LLM calls
%
% Outputs:
%   results/global_experiments_batch{N}/...
%   figures/global_experiments_batch{N}/...
%
% Seeds match a full 30-algorithm run: opts.seed_algo_offset = (batch_idx-1)*10.
%
% Rerun: delete results/global_experiments_batch{N}/mat/global_results.mat or pass true as second arg.

if nargin < 1 || isempty(batch_idx)
    batch_idx = 1;
end
if nargin < 2
    force_rerun = false;
end
if batch_idx < 1 || batch_idx > 3
    error('batch_idx must be 1, 2, or 3 (maps to 10 algorithms each).');
end

root_dir = fileparts(mfilename('fullpath'));
addpath(fullfile(root_dir, 'config'));
addpath(fullfile(root_dir, 'utils'));
cfg = default_config();
init_paths(cfg.paths.root);
ensure_dir(cfg.paths.results);
ensure_dir(cfg.paths.figures);
ensure_dir(cfg.paths.logs);

zo = cfg.exp.algorithms_zoo30;
if numel(zo) ~= 30
    error('Expected cfg.exp.algorithms_zoo30 to have 30 entries; got %d.', numel(zo));
end
i0 = (batch_idx - 1) * 10 + 1;
i1 = batch_idx * 10;
algo_list = zo(i0:i1);
seed_offset = i0 - 1; % 0, 10, 20

suffix = sprintf('batch%d', batch_idx);
base_res = fullfile(cfg.paths.results, ['global_experiments_', suffix]);
base_fig = fullfile(cfg.paths.figures, ['global_experiments_', suffix]);
mat_dir = fullfile(base_res, 'mat');
tbl_dir = fullfile(base_res, 'tables');
feat_dir = fullfile(base_res, 'features');
wgt_dir = fullfile(base_res, 'weights');

fig_conv = fullfile(base_fig, 'convergence');
fig_paths = fullfile(base_fig, 'paths');
fig_twin = fullfile(base_fig, 'twin_maps');
fig_llm_w = fullfile(base_fig, 'llm_stage_weights');
fig_feat = fullfile(base_fig, 'feature_analysis');
fig_stat = fullfile(base_fig, 'statistics');
fig_div = fullfile(base_fig, 'diversity');

cellfun(@ensure_dir, {base_res, mat_dir, tbl_dir, feat_dir, wgt_dir, base_fig, ...
    fig_conv, fig_paths, fig_twin, fig_llm_w, fig_feat, fig_stat, fig_div}, 'UniformOutput', false);

result_mat = fullfile(mat_dir, 'global_results.mat');
log_file = fullfile(cfg.paths.logs, sprintf('global_experiments_%s.log', suffix));

if exist(result_mat, 'file') && ~force_rerun && ~cfg.rerun_global_experiments
    fprintf(2, ['\n*** CACHED RESULTS ***\n' ...
        'Loaded: %s\n' ...
        'No new optimization was run. To re-run all algorithms from scratch, use ONE of:\n' ...
        '  main_run_global_experiments_batch(%d, true)\n' ...
        '  delete(''%s'')\n' ...
        '  Set cfg.rerun_global_experiments = true in config/default_config.m\n\n'], ...
        result_mat, batch_idx, result_mat);
    loaded = load(result_mat, 'out', 'summary_tbl', 'rank_tbl');
    out = loaded.out;
    summary_tbl = loaded.summary_tbl;
    rank_tbl = loaded.rank_tbl;
else
    map_list = generate_maps(cfg);
    stage_weights_map = build_stage_weights_for_batch(cfg, map_list, batch_idx, wgt_dir, log_file, base_fig, algo_list);

    feat_rows = [];
    for i = 1:numel(map_list)
        feat_path = fullfile(feat_dir, ['features_', map_list{i}.name, '.json']);
        feat = extract_map_features(map_list{i}, feat_path);
        feat_rows = [feat_rows; feat]; %#ok<AGROW>
    end
    feat_tbl = struct2table(feat_rows);
    writetable(feat_tbl, fullfile(tbl_dir, 'map_features.csv'));
    plot_feature_comparison(feat_tbl, fullfile(fig_feat, 'map_feature_comparison'), cfg);

    opts = struct();
    opts.stage_weights_map = stage_weights_map;
    opts.log_file = log_file;
    opts.verbose_console = true;
    opts.seed_algo_offset = seed_offset;
    out = run_experiment_batch(cfg, map_list, algo_list, cfg.exp.runs_per_map, opts);

    summary_tbl = compute_statistics(out.records);
    rank_tbl = friedman_rank(out.records);
    save(result_mat, 'out', 'summary_tbl', 'rank_tbl', 'cfg', 'algo_list', 'map_list', 'batch_idx', 'seed_offset');
    writetable(out.records, fullfile(tbl_dir, 'records.csv'));
    writetable(summary_tbl, fullfile(tbl_dir, 'summary.csv'));
    writetable(rank_tbl, fullfile(tbl_dir, 'friedman_rank.csv'));
    export_seed_log_batch(cfg, algo_list, tbl_dir, seed_offset);
end

maps = unique(out.records.Map);
map_list = generate_maps(cfg);
for i = 1:numel(maps)
    m = char(maps(i));
    curves = out.curves.(m);
    plot_convergence(curves, fullfile(fig_conv, ['conv_', m]), ...
        sprintf('Convergence - %s (%s)', m, suffix), cfg);
    mi = find(strcmp(cfg.maps.names, m), 1);
    pths = out.best_paths.(m);
    plot_paths(map_list{mi}, pths, fullfile(fig_paths, ['paths_', m]), ...
        sprintf('Best Paths - %s (%s)', m, suffix), cfg);

    f = figure('Visible', 'off', 'Color', 'w', 'Position', [50 50 1200 500]);
    subplot(1, 2, 1);
    algos = fieldnames(curves);
    hold on;
    for ai = 1:numel(algos)
        mat = curves.(algos{ai});
        plot(mean(mat, 1, 'omitnan'), 'LineWidth', 1.2, 'DisplayName', algos{ai});
    end
    hold off; grid on; title(sprintf('Convergence - %s', m)); xlabel('Iteration'); ylabel('Best Fitness');
    legend('Location', 'bestoutside', 'FontSize', 7);

    subplot(1, 2, 2);
    imagesc(1 - map_list{mi}.grid); axis equal tight; colormap(gray(2)); hold on; set(gca, 'YDir', 'normal');
    plot(map_list{mi}.start(1), map_list{mi}.start(2), 'go', 'MarkerSize', 8, 'LineWidth', 2);
    plot(map_list{mi}.goal(1), map_list{mi}.goal(2), 'ro', 'MarkerSize', 8, 'LineWidth', 2);
    pfields = fieldnames(pths);
    for pi = 1:numel(pfields)
        p = pths.(pfields{pi});
        if ~isempty(p), plot(p(:, 1), p(:, 2), 'LineWidth', 1.1, 'DisplayName', pfields{pi}); end
    end
    title(sprintf('Best Paths - %s', m)); xlabel('X'); ylabel('Y'); legend('Location', 'bestoutside', 'FontSize', 6); grid on;
    exportgraphics(f, fullfile(fig_twin, ['twin_', m, '.png']), 'Resolution', cfg.plot.dpi);
    savefig(f, fullfile(fig_twin, ['twin_', m, '.fig']));
    close(f);
end

data = out.records.BestFit;
labels = cellstr(out.records.Algorithm);
plot_boxplot(data, labels, fullfile(fig_stat, 'global_boxplot_bestfit'), ...
    sprintf('Best Fitness (%s)', suffix), 'Best Fitness', cfg);

f = figure('Visible', 'off', 'Color', 'w');
bar(categorical(rank_tbl.Algorithm), rank_tbl.AvgRank);
ylabel('Average Rank (Lower Better)'); title(sprintf('Friedman Average Ranking (%s)', suffix)); grid on;
exportgraphics(f, fullfile(fig_stat, 'friedman_rank_bar.png'), 'Resolution', cfg.plot.dpi);
savefig(f, fullfile(fig_stat, 'friedman_rank_bar.fig'));
close(f);

g = findgroups(out.records.Algorithm);
Algorithm = splitapply(@(x) x(1), out.records.Algorithm, g);
SR = splitapply(@mean, out.records.Success, g);
BestFitMean = splitapply(@mean, out.records.BestFit, g);
RuntimeMean = splitapply(@mean, out.records.Runtime, g);
PathLenMean = splitapply(@mean, out.records.PathLength, g);
SmoothMean = splitapply(@mean, out.records.Smoothness, g);
radar_tbl = table(Algorithm, ...
    normalize01(SR), normalize01(1 ./ (BestFitMean + eps)), normalize01(1 ./ (RuntimeMean + eps)), ...
    normalize01(1 ./ (PathLenMean + eps)), normalize01(1 ./ (SmoothMean + eps)), ...
    'VariableNames', {'Algorithm', 'SR', 'InvBestFit', 'InvRuntime', 'InvPathLength', 'InvSmoothness'});
writetable(radar_tbl, fullfile(tbl_dir, 'radar_metrics.csv'));
plot_radar(radar_tbl, fullfile(fig_stat, 'global_radar'), sprintf('Global Metric Radar (%s)', suffix), cfg);

g2 = findgroups(out.records.Algorithm);
alg2 = splitapply(@(x) x(1), out.records.Algorithm, g2);
sm = splitapply(@mean, out.records.Smoothness, g2);
ta = splitapply(@mean, out.records.AvgTurningAngle, g2);
f3 = figure('Visible', 'off', 'Color', 'w');
yyaxis left; bar(categorical(alg2), sm); ylabel('Smoothness');
yyaxis right; plot(1:numel(ta), ta, '-o', 'LineWidth', 1.5); ylabel('Avg Turning Angle');
title(sprintf('Path Smoothness and Turning (%s)', suffix)); grid on;
exportgraphics(f3, fullfile(fig_stat, 'path_smoothness_turning_stats.png'), 'Resolution', cfg.plot.dpi);
savefig(f3, fullfile(fig_stat, 'path_smoothness_turning_stats.fig'));
close(f3);

has_llm_eefo = any(strcmpi(cellstr(out.records.Algorithm), 'EEFOLLM') | strcmpi(cellstr(out.records.Algorithm), 'LLM-EEFO'));
if has_llm_eefo
    try
        map_end = map_list{end}.name;
        wjson = fullfile(wgt_dir, ['weights_', map_end, '.json']);
        plot_diversity_ee_batch(cfg, map_list, fig_div, wjson);
    catch ME
        log_message(log_file, ['Diversity/EE plot skipped: ', ME.message]);
    end
else
    log_message(log_file, 'Diversity/EE skipped: no EEFOLLM in this batch.');
end

if has_llm_eefo
    cmp_tbl = compare_vs_llmsfo(out.records, 'EEFOLLM');
    writetable(cmp_tbl, fullfile(tbl_dir, 'comparison_vs_llm_eefo.csv'));
end

fprintf(1, '=== global_experiments_%s done ===\n', suffix);
fprintf(1, 'Algorithms: %s\n', strjoin(algo_list, ', '));
fprintf(1, 'Data: %s\n Figures: %s\n', base_res, base_fig);
end

function stage_weights_map = build_stage_weights_for_batch(cfg, map_list, batch_idx, wgt_dir, log_file, base_fig, algo_list)
% Only EEFOLLM consumes these weights; other algorithms ignore stage_weights_map (static weights).
needs_llm = any(strcmpi(algo_list, 'EEFOLLM') | strcmpi(algo_list, 'LLM-EEFO') ...
    | strcmpi(algo_list, 'EEFOLLM-PARTIAL') | strcmpi(algo_list, 'EEFOLLM-NS') ...
    | strcmpi(algo_list, 'EEFOLLM-NJ'));
stage_weights_map = struct();
if ~needs_llm
    log_message(log_file, 'LLM: skipped — no EEFOLLM in this batch; all runs use static default weights.');
    return;
end

fig_llm_w = fullfile(base_fig, 'llm_stage_weights');
ensure_dir(fig_llm_w);
cache_root = fullfile(cfg.paths.results, 'global_experiments_batch1', 'weights');
use_cache = batch_idx > 1;

if use_cache
    for i = 1:numel(map_list)
        mname = map_list{i}.name;
        fjson = fullfile(cache_root, ['weights_', mname, '.json']);
        if ~isfile(fjson)
            error('Missing %s — run batch 1 first so EEFOLLM weights exist.', fjson);
        end
    end
    for i = 1:numel(map_list)
        mname = map_list{i}.name;
        raw = load_json(fullfile(cache_root, ['weights_', mname, '.json']));
        [okw, sw, msg] = validate_weights_struct(raw, cfg);
        if ~okw
            error('Invalid cached weights for %s: %s', mname, msg);
        end
        stage_weights_map.(mname) = sw;
        save_json(fullfile(wgt_dir, ['weights_', mname, '.json']), sw);
        log_message(log_file, sprintf('Map=%s weights copied from batch1 cache (EEFOLLM only)', mname));
    end
    return;
end

% batch with EEFOLLM and batch_idx==1: run Python/LLM once per map
for i = 1:numel(map_list)
    map_name = map_list{i}.name;
    [sw, meta] = generate_llm_weights(extract_map_features(map_list{i}, ''), cfg, '');
    stage_weights_map.(map_name) = sw;
    save_json(fullfile(wgt_dir, ['weights_', map_name, '.json']), sw);
    log_message(log_file, sprintf('Map=%s LLM weights (EEFOLLM only) fallback=%d msg=%s', map_name, meta.used_fallback, meta.message));
    plot_weight_bars(sw, fullfile(fig_llm_w, ['weights_', map_name]), ...
        ['LLM Stage Weights - ', map_name], cfg);
end
end

function export_seed_log_batch(cfg, algo_list, tbl_dir, seed_offset)
maps = cfg.maps.names;
rows = [];
for mi = 1:numel(maps)
    for ai = 1:numel(algo_list)
        gidx = seed_offset + ai;
        for r = 1:cfg.exp.runs_per_map
            x.Map = string(maps{mi});
            x.Algorithm = string(algo_list{ai});
            x.Run = r;
            x.GlobalAlgoIndex = gidx;
            x.Seed = cfg.base_seed + mi * 1000 + gidx * 100 + r;
            rows = [rows; x]; %#ok<AGROW>
        end
    end
end
writetable(struct2table(rows), fullfile(tbl_dir, 'seeds_used.csv'));
end

function z = normalize01(x)
x = double(x);
mn = min(x); mx = max(x);
if abs(mx - mn) < eps
    z = ones(size(x));
else
    z = (x - mn) ./ (mx - mn);
end
end

function plot_diversity_ee_batch(cfg, map_list, fig_div, weights_json_path)
% If weights_json_path points to batch-saved LLM weights, no extra generate_llm_weights call.
map_data = map_list{end};
if nargin >= 4 && ~isempty(weights_json_path) && isfile(weights_json_path)
    raw = load_json(weights_json_path);
    [ok, sw, msg] = validate_weights_struct(raw, cfg);
    if ~ok
        error('Invalid weights JSON: %s', msg);
    end
else
    feat = extract_map_features(map_data, '');
    [sw, ~] = generate_llm_weights(feat, cfg, '');
end
problem = build_problem(map_data, cfg, cfg.path.default_k);
base_params.pop_size = cfg.exp.population;
base_params.max_iter = cfg.exp.iterations;
base_params.seed = cfg.base_seed + 999;
base_params.cfg = cfg;
base_params.weights = cfg.weights.default;
base_params.save_history = true;
p1 = base_params;
sfo = safe_call_algo(@run_sfo, problem, p1);
p2 = base_params;
p2.stage_weights = sw;
p2.use_stage_weights = true;
llm = safe_call_algo(@run_llm_eefo, problem, p2);
div_sfo = diversity_analysis(sfo.history);
div_llm = diversity_analysis(llm.history);
ee_sfo = exploration_exploitation_analysis(sfo.curve);
ee_llm = exploration_exploitation_analysis(llm.curve);
f1 = figure('Visible', 'off', 'Color', 'w');
plot(div_sfo, 'LineWidth', 1.6, 'DisplayName', 'SFO'); hold on;
plot(div_llm, 'LineWidth', 1.6, 'DisplayName', 'EEFOLLM'); hold off;
grid on; xlabel('Iteration'); ylabel('Diversity');
title('Population Diversity Curve');
legend('Location', 'best');
exportgraphics(f1, fullfile(fig_div, 'diversity_curve.png'), 'Resolution', cfg.plot.dpi);
savefig(f1, fullfile(fig_div, 'diversity_curve.fig')); close(f1);
f2 = figure('Visible', 'off', 'Color', 'w');
plot(ee_sfo.ratio, 'LineWidth', 1.6, 'DisplayName', 'SFO'); hold on;
plot(ee_llm.ratio, 'LineWidth', 1.6, 'DisplayName', 'EEFOLLM'); hold off;
grid on; xlabel('Iteration'); ylabel('Exploration/Exploitation');
title('Exploration-Exploitation Ratio');
legend('Location', 'best');
exportgraphics(f2, fullfile(fig_div, 'exploration_exploitation_ratio.png'), 'Resolution', cfg.plot.dpi);
savefig(f2, fullfile(fig_div, 'exploration_exploitation_ratio.fig')); close(f2);
end
