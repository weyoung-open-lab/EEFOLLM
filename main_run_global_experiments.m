function main_run_global_experiments()
%MAIN_RUN_GLOBAL_EXPERIMENTS 5 maps x 30 algorithms x runs_per_map (no ablation).
%   Saves data and figures under categorized subfolders for paper plotting.
%
% results/global_experiments/
%   mat/global_results.mat
%   tables/*.csv (records, summary, friedman, map_features, radar_metrics, seeds_used, comparison_vs_llm_eefo)
%   features/features_Map*.json
%   weights/weights_Map*.json
%
% figures/global_experiments/
%   convergence/, paths/, twin_maps/, llm_stage_weights/, feature_analysis/
%   statistics/, diversity/
%
% Rerun: set cfg.rerun_global_experiments = true in config/default_config.m

root_dir = fileparts(mfilename('fullpath'));
addpath(fullfile(root_dir, 'config'));
addpath(fullfile(root_dir, 'utils'));
cfg = default_config();
init_paths(cfg.paths.root);
ensure_dir(cfg.paths.results);
ensure_dir(cfg.paths.figures);
ensure_dir(cfg.paths.logs);

base_res = fullfile(cfg.paths.results, 'global_experiments');
base_fig = fullfile(cfg.paths.figures, 'global_experiments');
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
log_file = fullfile(cfg.paths.logs, 'global_experiments.log');
algo_list = cfg.exp.algorithms_zoo30;

if exist(result_mat, 'file') && ~cfg.rerun_global_experiments
    loaded = load(result_mat, 'out', 'summary_tbl', 'rank_tbl');
    out = loaded.out;
    summary_tbl = loaded.summary_tbl;
    rank_tbl = loaded.rank_tbl;
else
    map_list = generate_maps(cfg);
    stage_weights_map = struct();
    feat_rows = [];
    for i = 1:numel(map_list)
        feat_path = fullfile(feat_dir, ['features_', map_list{i}.name, '.json']);
        feat = extract_map_features(map_list{i}, feat_path);
        feat_rows = [feat_rows; feat]; %#ok<AGROW>
        [sw, meta] = generate_llm_weights(feat, cfg, '');
        stage_weights_map.(map_list{i}.name) = sw;
        save_json(fullfile(wgt_dir, ['weights_', map_list{i}.name, '.json']), sw);
        log_message(log_file, sprintf('Map=%s fallback=%d msg=%s', map_list{i}.name, meta.used_fallback, meta.message));
        plot_weight_bars(sw, fullfile(fig_llm_w, ['weights_', map_list{i}.name]), ...
            ['LLM Stage Weights - ', map_list{i}.name], cfg);
    end
    feat_tbl = struct2table(feat_rows);
    writetable(feat_tbl, fullfile(tbl_dir, 'map_features.csv'));
    plot_feature_comparison(feat_tbl, fullfile(fig_feat, 'map_feature_comparison'), cfg);

    opts = struct();
    opts.stage_weights_map = stage_weights_map;
    opts.log_file = log_file;
    opts.verbose_console = true;
    out = run_experiment_batch(cfg, map_list, algo_list, cfg.exp.runs_per_map, opts);

    summary_tbl = compute_statistics(out.records);
    rank_tbl = friedman_rank(out.records);
    save(result_mat, 'out', 'summary_tbl', 'rank_tbl', 'cfg', 'algo_list', 'map_list');
    writetable(out.records, fullfile(tbl_dir, 'records.csv'));
    writetable(summary_tbl, fullfile(tbl_dir, 'summary.csv'));
    writetable(rank_tbl, fullfile(tbl_dir, 'friedman_rank.csv'));
    export_seed_log_global(cfg, algo_list, tbl_dir);
end

maps = unique(out.records.Map);
map_list = generate_maps(cfg);
for i = 1:numel(maps)
    m = char(maps(i));
    curves = out.curves.(m);
    plot_convergence(curves, fullfile(fig_conv, ['conv_', m]), ...
        ['Convergence - ', m], cfg);
    mi = find(strcmp(cfg.maps.names, m), 1);
    pths = out.best_paths.(m);
    plot_paths(map_list{mi}, pths, fullfile(fig_paths, ['paths_', m]), ...
        ['Best Paths - ', m], cfg);

    f = figure('Visible', 'off', 'Color', 'w', 'Position', [50 50 1200 500]);
    subplot(1, 2, 1);
    algos = fieldnames(curves);
    hold on;
    for ai = 1:numel(algos)
        mat = curves.(algos{ai});
        plot(mean(mat, 1, 'omitnan'), 'LineWidth', 1.2, 'DisplayName', algos{ai});
    end
    hold off; grid on; title(['Convergence - ', m]); xlabel('Iteration'); ylabel('Best Fitness');
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
    title(['Best Paths - ', m]); xlabel('X'); ylabel('Y'); legend('Location', 'bestoutside', 'FontSize', 6); grid on;
    exportgraphics(f, fullfile(fig_twin, ['twin_', m, '.png']), 'Resolution', cfg.plot.dpi);
    savefig(f, fullfile(fig_twin, ['twin_', m, '.fig']));
    close(f);
end

data = out.records.BestFit;
labels = cellstr(out.records.Algorithm);
plot_boxplot(data, labels, fullfile(fig_stat, 'global_boxplot_bestfit'), ...
    'Best Fitness Distribution (All Maps)', 'Best Fitness', cfg);

f = figure('Visible', 'off', 'Color', 'w');
bar(categorical(rank_tbl.Algorithm), rank_tbl.AvgRank);
ylabel('Average Rank (Lower Better)'); title('Friedman Average Ranking'); grid on;
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
plot_radar(radar_tbl, fullfile(fig_stat, 'global_radar'), 'Global Metric Radar', cfg);

g2 = findgroups(out.records.Algorithm);
alg2 = splitapply(@(x) x(1), out.records.Algorithm, g2);
sm = splitapply(@mean, out.records.Smoothness, g2);
ta = splitapply(@mean, out.records.AvgTurningAngle, g2);
f3 = figure('Visible', 'off', 'Color', 'w');
yyaxis left; bar(categorical(alg2), sm); ylabel('Smoothness');
yyaxis right; plot(1:numel(ta), ta, '-o', 'LineWidth', 1.5); ylabel('Avg Turning Angle');
title('Path Smoothness and Turning Statistics'); grid on;
exportgraphics(f3, fullfile(fig_stat, 'path_smoothness_turning_stats.png'), 'Resolution', cfg.plot.dpi);
savefig(f3, fullfile(fig_stat, 'path_smoothness_turning_stats.fig'));
close(f3);

try
    plot_diversity_ee(cfg, map_list, fig_div);
catch ME
    log_message(log_file, ['Diversity/EE plot skipped: ', ME.message]);
end

cmp_tbl = compare_vs_llmsfo(out.records, 'EEFOLLM');
writetable(cmp_tbl, fullfile(tbl_dir, 'comparison_vs_llm_eefo.csv'));
n_bf = sum(cmp_tbl.Weaker_MeanBestFitOnly);
n_3 = sum(cmp_tbl.Weaker_AllThreeMetrics);
fprintf(1, 'vs EEFOLLM: %d algorithms with worse mean BestFit; %d worse on BestFit+Success+CollisionFree (see comparison_vs_llm_eefo.csv).\n', n_bf, n_3);

fprintf(1, '=== Global experiments done ===\n');
fprintf(1, 'Data: %s\n', base_res);
fprintf(1, 'Figures: %s\n', base_fig);
end

function export_seed_log_global(cfg, algo_list, tbl_dir)
maps = cfg.maps.names;
rows = [];
for mi = 1:numel(maps)
    for ai = 1:numel(algo_list)
        for r = 1:cfg.exp.runs_per_map
            x.Map = string(maps{mi});
            x.Algorithm = string(algo_list{ai});
            x.Run = r;
            x.Seed = cfg.base_seed + mi * 1000 + ai * 100 + r;
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

function plot_diversity_ee(cfg, map_list, fig_div)
map_data = map_list{end};
feat = extract_map_features(map_data, '');
[sw, ~] = generate_llm_weights(feat, cfg, '');
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
