function main_run_main_experiments()
%MAIN_RUN_MAIN_EXPERIMENTS Run 5 maps x 8 algorithms x 20 runs.
root_dir = fileparts(mfilename('fullpath'));
addpath(fullfile(root_dir, 'config'));
addpath(fullfile(root_dir, 'utils'));
cfg = default_config();
init_paths(cfg.paths.root);
ensure_dir(cfg.paths.results); ensure_dir(cfg.paths.figures); ensure_dir(cfg.paths.logs);
map_list = generate_maps(cfg);

result_dir = fullfile(cfg.paths.results, 'main_experiments');
fig_dir = fullfile(cfg.paths.figures, 'main_experiments');
ensure_dir(result_dir); ensure_dir(fig_dir);
result_mat = fullfile(result_dir, 'main_results.mat');

if exist(result_mat, 'file') && ~cfg.rerun_main_experiments
    loaded = load(result_mat, 'out', 'summary_tbl', 'rank_tbl');
    out = loaded.out; summary_tbl = loaded.summary_tbl; rank_tbl = loaded.rank_tbl; %#ok<NASGU>
else
    stage_weights_map = struct();
    feat_rows = [];
    for i = 1:numel(map_list)
        feat = extract_map_features(map_list{i}, fullfile(cfg.paths.results, ...
            ['features_', map_list{i}.name, '.json']));
        feat_rows = [feat_rows; feat]; %#ok<AGROW>
        [sw, meta] = generate_llm_weights(feat, cfg, '');
        stage_weights_map.(map_list{i}.name) = sw;
        save_json(fullfile(cfg.paths.results, ['weights_', map_list{i}.name, '.json']), sw);
        log_message(fullfile(cfg.paths.logs, 'llm_weight_generation.log'), ...
            sprintf('Map=%s fallback=%d msg=%s', map_list{i}.name, meta.used_fallback, meta.message));
        plot_weight_bars(sw, fullfile(fig_dir, ['weights_', map_list{i}.name]), ...
            ['LLM Stage Weights - ', map_list{i}.name], cfg);
    end
    feat_tbl = struct2table(feat_rows);
    writetable(feat_tbl, fullfile(result_dir, 'map_features.csv'));
    plot_feature_comparison(feat_tbl, fullfile(fig_dir, 'map_feature_comparison'), cfg);

    opts = struct();
    opts.stage_weights_map = stage_weights_map;
    opts.log_file = fullfile(cfg.paths.logs, 'main_experiments.log');
    out = run_experiment_batch(cfg, map_list, cfg.exp.algorithms, cfg.exp.runs_per_map, opts);

    summary_tbl = compute_statistics(out.records);
    rank_tbl = friedman_rank(out.records);
    save(result_mat, 'out', 'summary_tbl', 'rank_tbl');
    writetable(out.records, fullfile(result_dir, 'main_records.csv'));
    writetable(summary_tbl, fullfile(result_dir, 'main_summary.csv'));
    writetable(rank_tbl, fullfile(result_dir, 'friedman_rank.csv'));
end

maps = unique(out.records.Map);
for i = 1:numel(maps)
    m = char(maps(i));
    curves = out.curves.(m);
    plot_convergence(curves, fullfile(fig_dir, ['conv_', m]), ...
        ['Convergence - ', m], cfg);
    % Path figure
    mi = find(strcmp(cfg.maps.names, m), 1);
    pths = out.best_paths.(m);
    plot_paths(map_list{mi}, pths, fullfile(fig_dir, ['paths_', m]), ...
        ['Best Paths - ', m], cfg);

    % Twin figure: convergence + paths
    f = figure('Visible', 'off', 'Color', 'w', 'Position', [50 50 1200 500]);
    subplot(1, 2, 1);
    algos = fieldnames(curves);
    hold on;
    for ai = 1:numel(algos)
        mat = curves.(algos{ai});
        plot(mean(mat, 1, 'omitnan'), 'LineWidth', 1.4, 'DisplayName', algos{ai});
    end
    hold off; grid on; title(['Convergence - ', m]); xlabel('Iteration'); ylabel('Best Fitness');
    legend('Location', 'bestoutside');

    subplot(1, 2, 2);
    imagesc(1 - map_list{mi}.grid); axis equal tight; colormap(gray(2)); hold on; set(gca, 'YDir', 'normal');
    plot(map_list{mi}.start(1), map_list{mi}.start(2), 'go', 'MarkerSize', 8, 'LineWidth', 2);
    plot(map_list{mi}.goal(1), map_list{mi}.goal(2), 'ro', 'MarkerSize', 8, 'LineWidth', 2);
    pfields = fieldnames(pths);
    for pi = 1:numel(pfields)
        p = pths.(pfields{pi});
        if ~isempty(p), plot(p(:,1), p(:,2), 'LineWidth', 1.4, 'DisplayName', pfields{pi}); end
    end
    title(['Best Paths - ', m]); xlabel('X'); ylabel('Y'); legend('Location', 'bestoutside'); grid on;
    exportgraphics(f, fullfile(fig_dir, ['twin_', m, '.png']), 'Resolution', cfg.plot.dpi);
    savefig(f, fullfile(fig_dir, ['twin_', m, '.fig']));
    close(f);
end

% Global boxplot for best fitness
algos = unique(out.records.Algorithm);
data = nan(height(out.records), 1);
labels = strings(height(out.records), 1);
for i = 1:height(out.records)
    data(i) = out.records.BestFit(i);
    labels(i) = out.records.Algorithm(i);
end
plot_boxplot(data, cellstr(labels), fullfile(fig_dir, 'global_boxplot_bestfit'), ...
    'Best Fitness Distribution (All Maps)', 'Best Fitness', cfg);

% Ranking bar
f = figure('Visible', 'off', 'Color', 'w');
bar(categorical(rank_tbl.Algorithm), rank_tbl.AvgRank);
ylabel('Average Rank (Lower Better)'); title('Friedman Average Ranking'); grid on;
exportgraphics(f, fullfile(fig_dir, 'friedman_rank_bar.png'), 'Resolution', cfg.plot.dpi);
savefig(f, fullfile(fig_dir, 'friedman_rank_bar.fig'));
close(f);

% Radar from global algorithm summary
g = findgroups(out.records.Algorithm);
Algorithm = splitapply(@(x) x(1), out.records.Algorithm, g);
SR = splitapply(@mean, out.records.Success, g);
BestFitMean = splitapply(@mean, out.records.BestFit, g);
RuntimeMean = splitapply(@mean, out.records.Runtime, g);
PathLenMean = splitapply(@mean, out.records.PathLength, g);
SmoothMean = splitapply(@mean, out.records.Smoothness, g);
radar_tbl = table(Algorithm, ...
    normalize01(SR), normalize01(1./(BestFitMean + eps)), normalize01(1./(RuntimeMean + eps)), ...
    normalize01(1./(PathLenMean + eps)), normalize01(1./(SmoothMean + eps)), ...
    'VariableNames', {'Algorithm','SR','InvBestFit','InvRuntime','InvPathLength','InvSmoothness'});
plot_radar(radar_tbl, fullfile(fig_dir, 'global_radar'), 'Global Metric Radar', cfg);

% Smoothness and turning statistics
g2 = findgroups(out.records.Algorithm);
alg2 = splitapply(@(x) x(1), out.records.Algorithm, g2);
sm = splitapply(@mean, out.records.Smoothness, g2);
ta = splitapply(@mean, out.records.AvgTurningAngle, g2);
f3 = figure('Visible', 'off', 'Color', 'w');
yyaxis left; bar(categorical(alg2), sm); ylabel('Smoothness');
yyaxis right; plot(1:numel(ta), ta, '-o', 'LineWidth', 1.5); ylabel('Avg Turning Angle');
title('Path Smoothness and Turning Statistics'); grid on;
exportgraphics(f3, fullfile(fig_dir, 'path_smoothness_turning_stats.png'), 'Resolution', cfg.plot.dpi);
savefig(f3, fullfile(fig_dir, 'path_smoothness_turning_stats.fig'));
close(f3);

% Diversity and exploration-exploitation curves (SFO vs EEFOLLM)
try
    plot_diversity_ee(cfg, map_list, fig_dir);
catch ME
    log_message(fullfile(cfg.paths.logs, 'main_experiments.log'), ['Diversity/EE plot skipped: ', ME.message]);
end
end

function z = normalize01(x)
x = double(x);
mn = min(x); mx = max(x);
if abs(mx - mn) < eps
    z = ones(size(x));
else
    z = (x - mn) ./ (mx - mn);
end

function plot_diversity_ee(cfg, map_list, fig_dir)
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
exportgraphics(f1, fullfile(fig_dir, 'diversity_curve.png'), 'Resolution', cfg.plot.dpi);
savefig(f1, fullfile(fig_dir, 'diversity_curve.fig')); close(f1);

f2 = figure('Visible', 'off', 'Color', 'w');
plot(ee_sfo.ratio, 'LineWidth', 1.6, 'DisplayName', 'SFO'); hold on;
plot(ee_llm.ratio, 'LineWidth', 1.6, 'DisplayName', 'EEFOLLM'); hold off;
grid on; xlabel('Iteration'); ylabel('Exploration/Exploitation');
title('Exploration-Exploitation Ratio');
legend('Location', 'best');
exportgraphics(f2, fullfile(fig_dir, 'exploration_exploitation_ratio.png'), 'Resolution', cfg.plot.dpi);
savefig(f2, fullfile(fig_dir, 'exploration_exploitation_ratio.fig')); close(f2);
end
end
