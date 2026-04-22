function main_plot_ablation_convergence()
%MAIN_PLOT_ABLATION_CONVERGENCE 消融五算法收敛图：EEFO / EEFOLLM（来自 batch1 mat）+ 三种残缺 EEFOLLM（来自 ablation mat）。
%
%   输出: results/ablation_result/figures/convergence/convergence_<MapName>_abl5.png|.svg
%
%   依赖:
%     results/global_experiments_batch1/mat/global_results.mat  （含 out.curves）
%     results/ablation_eefollm_ablated_only/mat/ablation_eefollm_ablated_only.mat
%
%   表与箱线图请运行: python scripts/export_ablation_result.py

root_dir = fileparts(mfilename('fullpath'));
addpath(root_dir);
addpath(fullfile(root_dir, 'config'));
addpath(fullfile(root_dir, 'utils'));
addpath(fullfile(root_dir, 'plotting'));
cfg = default_config();
init_paths(cfg.paths.root);

batch_mat = fullfile(cfg.paths.results, 'global_experiments_batch1', 'mat', 'global_results.mat');
abl_mat = fullfile(cfg.paths.results, 'ablation_eefollm_ablated_only', 'mat', 'ablation_eefollm_ablated_only.mat');

out_dir = fullfile(cfg.paths.results, 'ablation_result', 'figures', 'convergence');
ensure_dir(out_dir);

if ~isfile(batch_mat)
    warning('main_plot_ablation_convergence:MissingBatch', ...
        'Missing %s — cannot plot EEFO/EEFOLLM curves. Run main_run_global_experiments_batch(1) or copy mat.', batch_mat);
    return;
end
if ~isfile(abl_mat)
    warning('main_plot_ablation_convergence:MissingAblation', ...
        'Missing %s — cannot plot ablated EEFOLLM curves. Run main_run_ablation_eefollm_ablated_only.', abl_mat);
    return;
end

S1 = load(batch_mat, 'out');
S2 = load(abl_mat, 'out');
if ~isfield(S1.out, 'curves') || ~isfield(S2.out, 'curves')
    error('Both MAT files must contain out.curves');
end

algos = {'EEFO', 'EEFOLLM', 'EEFOLLM-NJ', 'EEFOLLM-NS', 'EEFOLLM-PARTIAL'};
maps = cfg.maps.names(:);
if isstring(maps), maps = cellstr(maps); end

font_name = 'Times New Roman';
font_size = 10;
colors = [
    0.00 0.45 0.74; 0.85 0.33 0.10; 0.93 0.69 0.13; 0.49 0.18 0.56; 0.85 0.10 0.15
    ];
lines = {'-', '-', '--', '-.', '-'};
markers = {'none', 'none', 'none', 'none', 'none'};
lw_base = 1.4;
lw_ours = 2.4;

% ---------- 组合图 2×3，仅占前 5 格 ----------
f_all = figure('Color', 'w', 'Units', 'normalized', 'Position', [0.04 0.06 0.78 0.88]);
for k = 1:numel(maps)
    mn = maps{k};
    if ~isfield(S1.out.curves, mn) || ~isfield(S2.out.curves, mn)
        axk = subplot(2, 3, k);
        text(axk, 0.5, 0.5, sprintf('No data: %s', mn), 'HorizontalAlignment', 'center');
        continue;
    end
    axk = subplot(2, 3, k);
    plot_ablation_map_axes(axk, mn, S1.out.curves, S2.out.curves, algos, colors, lines, lw_base, lw_ours, font_name, font_size, cfg);
end
try
    sgtitle(f_all, 'Convergence (ablation: 5 algorithms)', 'FontName', font_name, 'FontWeight', 'normal', ...
        'FontSize', font_size + 2);
catch %#ok<CTCH>
end
export_fig_vector_raster_local(f_all, fullfile(out_dir, 'convergence_all_maps_abl5'));
close(f_all);
fprintf(1, 'Saved %s\n', fullfile(out_dir, 'convergence_all_maps_abl5.png'));

for mi = 1:numel(maps)
    mn = maps{mi};
    if ~isfield(S1.out.curves, mn) || ~isfield(S2.out.curves, mn)
        warning('No curves for map %s', mn);
        continue;
    end
    f = figure('Color', 'w', 'Units', 'normalized', 'Position', [0.1 0.1 0.55 0.72]);
    ax = axes(f, 'Position', [0.12 0.18 0.82 0.68]);
    plot_ablation_map_axes(ax, mn, S1.out.curves, S2.out.curves, algos, colors, lines, lw_base, lw_ours, font_name, font_size, cfg);

    base = fullfile(out_dir, ['convergence_', mn, '_abl5']);
    export_fig_vector_raster_local(f, base);
    close(f);
    fprintf(1, 'Saved %s.png/.svg\n', base);
end
end

function plot_ablation_map_axes(ax, mn, curves1, curves2, algos, colors, lines, lw_base, lw_ours, font_name, font_size, cfg)
c1 = curves1.(mn);
c2 = curves2.(mn);
hold(ax, 'on');
leg = {};
for ai = 1:numel(algos)
    algo = algos{ai};
    M = get_curve_matrix(c1, c2, algo);
    if isempty(M)
        continue;
    end
    y = aggregate_curve_mean_cummin(M);
    it = 1:numel(y);
    col = colors(ai, :);
    lw = lw_base;
    if strcmpi(algo, 'EEFOLLM'), lw = lw_ours; end
    plot(ax, it, y, 'Color', col, 'LineStyle', lines{ai}, 'LineWidth', lw, 'DisplayName', algo);
    leg{end+1} = algo; %#ok<AGROW>
end
hold(ax, 'off');
grid(ax, 'on');
box(ax, 'on');
xlabel(ax, 'Iteration', 'FontName', font_name, 'FontSize', font_size);
ylabel(ax, 'Fitness (mean best-so-far)', 'FontName', font_name, 'FontSize', font_size);
title(ax, mn, 'FontName', font_name, 'FontSize', font_size + 1);
set(ax, 'FontName', font_name, 'FontSize', font_size);
xlim(ax, [1 cfg.exp.iterations]);
if ~isempty(leg)
    legend(ax, leg, 'Location', 'best', 'FontSize', max(6, font_size - 2));
end
end

function M = get_curve_matrix(c1, c2, algo)
if strcmpi(algo, 'EEFO') || strcmpi(algo, 'EEFOLLM')
    cmap = c1;
else
    cmap = c2;
end
fn = matlab.lang.makeValidName(algo);
if isfield(cmap, fn)
    M = cmap.(fn);
    return;
end
aliases = {algo};
if strcmpi(algo, 'EEFOLLM')
    aliases = [aliases, {'LLM-EEFO', 'LLM_EEFO'}];
end
for k = 1:numel(aliases)
    fn2 = matlab.lang.makeValidName(aliases{k});
    if isfield(cmap, fn2)
        M = cmap.(fn2);
        return;
    end
end
M = [];
end

function y = aggregate_curve_mean_cummin(M)
if isempty(M)
    y = [];
    return;
end
[n, T] = size(M);
Mc = nan(n, T);
for r = 1:n
    Mc(r, :) = best_so_far_row(M(r, :));
end
y = mean(Mc, 1, 'omitnan');
end

function v = best_so_far_row(vin)
T = numel(vin);
v = nan(1, T);
best = inf;
for t = 1:T
    if isfinite(vin(t))
        best = min(best, vin(t));
    end
    if isfinite(best)
        v(t) = best;
    end
end
end

function export_fig_vector_raster_local(f, base_path)
png = [base_path, '.png'];
svg = [base_path, '.svg'];
if exist('exportgraphics', 'file')
    exportgraphics(f, png, 'Resolution', 300);
    try
        exportgraphics(f, svg, 'ContentType', 'vector');
    catch %#ok<CTCH>
        try
            saveas(f, svg);
        catch %#ok<CTCH>
        end
    end
else
    print(f, png, '-dpng', '-r300');
end
end
