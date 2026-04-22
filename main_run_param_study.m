function main_run_param_study()
%MAIN_RUN_PARAM_STUDY Parameter analysis experiments.
root_dir = fileparts(mfilename('fullpath'));
addpath(fullfile(root_dir, 'config'));
addpath(fullfile(root_dir, 'utils'));
cfg = default_config();
init_paths(cfg.paths.root);
result_dir = fullfile(cfg.paths.results, 'param_study');
fig_dir = fullfile(cfg.paths.figures, 'param_study');
ensure_dir(result_dir); ensure_dir(fig_dir);
result_mat = fullfile(result_dir, 'param_study.mat');

if exist(result_mat, 'file') && ~cfg.rerun_param_study
    loaded = load(result_mat);
    pop_tbl = loaded.pop_tbl; iter_tbl = loaded.iter_tbl; k_tbl = loaded.k_tbl; w_tbl = loaded.w_tbl; weights_tbl = loaded.weights_tbl; %#ok<NASGU>
else
    maps = generate_maps(cfg);
    map_data = maps{3}; % medium-high complexity map for parameter study.
    pop_tbl = sweep_population(cfg, map_data);
    iter_tbl = sweep_iterations(cfg, map_data);
    k_tbl = sweep_waypoints(cfg, map_data);
    w_tbl = sweep_weights(cfg, map_data);
    weights_tbl = collect_llm_weight_variation(cfg, maps);
    save(result_mat, 'pop_tbl', 'iter_tbl', 'k_tbl', 'w_tbl', 'weights_tbl');
    writetable(pop_tbl, fullfile(result_dir, 'pop_sweep.csv'));
    writetable(iter_tbl, fullfile(result_dir, 'iter_sweep.csv'));
    writetable(k_tbl, fullfile(result_dir, 'k_sweep.csv'));
    writetable(w_tbl, fullfile(result_dir, 'weight_sweep.csv'));
    writetable(weights_tbl, fullfile(result_dir, 'llm_weights_by_map.csv'));
end

plot_param_curve(pop_tbl.ParamValue, pop_tbl.MeanBestFit, 'Population Size', ...
    fullfile(fig_dir, 'param_pop'), cfg);
plot_param_curve(iter_tbl.ParamValue, iter_tbl.MeanBestFit, 'Iteration Number', ...
    fullfile(fig_dir, 'param_iter'), cfg);
plot_param_curve(k_tbl.ParamValue, k_tbl.MeanBestFit, 'Waypoint Count K', ...
    fullfile(fig_dir, 'param_k'), cfg);
plot_param_curve(w_tbl.ParamValue, w_tbl.MeanBestFit, 'Default Weight Setting Index', ...
    fullfile(fig_dir, 'param_weight_index'), cfg);

% LLM weight variation plot
f = figure('Visible', 'off', 'Color', 'w');
subplot(2,2,1); bar(categorical(weights_tbl.Map), weights_tbl.wL_mid); title('wL(mid)');
subplot(2,2,2); bar(categorical(weights_tbl.Map), weights_tbl.wC_mid); title('wC(mid)');
subplot(2,2,3); bar(categorical(weights_tbl.Map), weights_tbl.wS_mid); title('wS(mid)');
subplot(2,2,4); bar(categorical(weights_tbl.Map), weights_tbl.wT_mid); title('wT(mid)');
sgtitle('LLM Mid-stage Weights Across Maps');
exportgraphics(f, fullfile(fig_dir, 'llm_weight_variation.png'), 'Resolution', cfg.plot.dpi);
savefig(f, fullfile(fig_dir, 'llm_weight_variation.fig'));
close(f);
end

function tbl = sweep_population(cfg, map_data)
vals = cfg.param.pop_sizes;
tbl = run_single_param_sweep(cfg, map_data, vals, 'pop');
end

function tbl = sweep_iterations(cfg, map_data)
vals = cfg.param.iter_counts;
tbl = run_single_param_sweep(cfg, map_data, vals, 'iter');
end

function tbl = sweep_waypoints(cfg, map_data)
vals = cfg.param.k_values;
tbl = run_single_param_sweep(cfg, map_data, vals, 'k');
end

function tbl = sweep_weights(cfg, map_data)
vals = 1:size(cfg.param.weight_grid, 1);
mean_fit = nan(numel(vals), 1);
for i = 1:numel(vals)
    wv = cfg.param.weight_grid(i, :);
    opts = struct();
    opts.static_weight_override = normalize_weights(struct('wL', wv(1), 'wC', wv(2), 'wS', wv(3), 'wT', wv(4)));
    opts.log_file = fullfile(cfg.paths.logs, 'param_weight.log');
    out = run_experiment_batch(cfg, {map_data}, {'SFO'}, cfg.exp.smoke_runs, opts);
    mean_fit(i) = mean(out.records.BestFit, 'omitnan');
end
tbl = table(vals(:), mean_fit, 'VariableNames', {'ParamValue', 'MeanBestFit'});
end

function tbl = run_single_param_sweep(cfg, map_data, vals, mode)
mean_fit = nan(numel(vals), 1);
for i = 1:numel(vals)
    opts = struct();
    opts.log_file = fullfile(cfg.paths.logs, ['param_', mode, '.log']);
    if strcmp(mode, 'pop')
        opts.pop_size = vals(i);
        opts.max_iter = cfg.exp.iterations;
        opts.k_waypoints = cfg.path.default_k;
    elseif strcmp(mode, 'iter')
        opts.pop_size = cfg.exp.population;
        opts.max_iter = vals(i);
        opts.k_waypoints = cfg.path.default_k;
    else
        opts.pop_size = cfg.exp.population;
        opts.max_iter = cfg.exp.iterations;
        opts.k_waypoints = vals(i);
    end
    out = run_experiment_batch(cfg, {map_data}, {'SFO'}, cfg.exp.smoke_runs, opts);
    mean_fit(i) = mean(out.records.BestFit, 'omitnan');
end
tbl = table(vals(:), mean_fit, 'VariableNames', {'ParamValue', 'MeanBestFit'});
end

function tbl = collect_llm_weight_variation(cfg, map_list)
rows = [];
for i = 1:numel(map_list)
    feat = extract_map_features(map_list{i}, '');
    [sw, ~] = generate_llm_weights(feat, cfg, '');
    r.Map = string(map_list{i}.name);
    r.wL_mid = sw.mid.wL; r.wC_mid = sw.mid.wC;
    r.wS_mid = sw.mid.wS; r.wT_mid = sw.mid.wT;
    rows = [rows; r]; %#ok<AGROW>
end
tbl = struct2table(rows);
end

function plot_param_curve(x, y, xlab, save_base, cfg)
f = figure('Visible', 'off', 'Color', 'w');
plot(x, y, '-o', 'LineWidth', cfg.plot.line_width);
xlabel(xlab); ylabel('Mean Best Fitness'); grid on;
title(['Parameter Study: ', xlab]);
exportgraphics(f, [save_base, '.png'], 'Resolution', cfg.plot.dpi);
savefig(f, [save_base, '.fig']);
close(f);
end
