function plot_convergence_all_maps(opts)
%PLOT_CONVERGENCE_ALL_MAPS 论文主图：5 地图 × 10 算法平均收敛曲线。
%
%   布局：2×3 中仅使用 5 个子图（无第 6 幅）；图例统一放在整张图底部（横向），每根线对应算法名。
%   每张地图另存单独图 + PNG/SVG 到 results/convergence_maps/。
%
%   输出：
%     figures/paper_main/convergence_all_maps_all10.png|.svg
%     results/convergence_maps/convergence_<MapName>_all10.png|.svg
%
%   用法（工程根目录）：
%     plot_convergence_all_maps
%     plot_convergence_all_maps(struct('do_inset', false, 'result_mat', '...'))

if nargin < 1, opts = struct(); end
if ~isfield(opts, 'use_cummin'), opts.use_cummin = true; end
if ~isfield(opts, 'do_inset'), opts.do_inset = true; end
if ~isfield(opts, 'inset_iter_range'), opts.inset_iter_range = [80 100]; end
if ~isfield(opts, 'our_algo'), opts.our_algo = 'EEFOLLM'; end
if ~isfield(opts, 'out_dir'), opts.out_dir = ''; end
if ~isfield(opts, 'result_mat'), opts.result_mat = ''; end
if ~isfield(opts, 'font_name'), opts.font_name = 'Times New Roman'; end
if ~isfield(opts, 'font_size'), opts.font_size = 10; end
if ~isfield(opts, 'results_per_map_dir'), opts.results_per_map_dir = ''; end

root_dir = fileparts(mfilename('fullpath'));
addpath(root_dir);
addpath(fullfile(root_dir, 'config'));
addpath(fullfile(root_dir, 'utils'));
addpath(fullfile(root_dir, 'plotting'));
cfg = default_config();
init_paths(cfg.paths.root);

if isempty(opts.out_dir)
    opts.out_dir = fullfile(cfg.paths.figures, 'paper_main');
end
ensure_dir(opts.out_dir);

if isempty(opts.results_per_map_dir)
    opts.results_per_map_dir = fullfile(cfg.paths.results, 'convergence_maps');
end
ensure_dir(opts.results_per_map_dir);

[algos10, ~] = paper_benchmark_algorithms10();
curves_all = load_merged_curves(cfg, algos10, opts.result_mat);
style = build_line_styles(algos10, opts.our_algo);

map_names = cfg.maps.names(:);
if isstring(map_names), map_names = cellstr(map_names); end

ylab = 'Fitness value';

% ========== 组合图：10 算法 ==========
% 使用 subplot(2,3,1:5)，避免 tiledlayout 在部分版本/参数下网格不是 2×3 导致 nexttile 越界
f = figure('Color', 'w', 'Units', 'normalized', 'Position', [0.04 0.06 0.78 0.88]);

for k = 1:5
    mn = map_names{k};
    ax = subplot(2, 3, k);
    plot_map_curves_on_axes(ax, mn, curves_all, algos10, style, opts, cfg, ylab, true);
end

if exist('sgtitle', 'file')
    sgtitle(f, 'Convergence curves of the algorithms', 'FontName', opts.font_name, 'FontWeight', 'normal', ...
        'FontSize', opts.font_size + 2);
end

add_bottom_legend(f, algos10, style, opts);
export_fig_vector_raster(f, fullfile(opts.out_dir, 'convergence_all_maps_all10'));
close(f);

% ========== 每张地图单独保存（10 算法）==========
for k = 1:5
    mn = map_names{k};
    if ~isfield(curves_all, mn), continue; end
    f1 = figure('Color', 'w', 'Units', 'normalized', 'Position', [0.1 0.1 0.55 0.72]);
    ax1 = axes(f1, 'Position', [0.12 0.20 0.82 0.65]);
    plot_map_curves_on_axes(ax1, mn, curves_all, algos10, style, opts, cfg, ylab, true);
    title(ax1, mn, 'FontName', opts.font_name, 'FontSize', opts.font_size + 1);
    add_bottom_legend(f1, algos10, style, opts);
    base = fullfile(opts.results_per_map_dir, ['convergence_', mn, '_all10']);
    export_fig_vector_raster(f1, base);
    close(f1);
end

fprintf(1, 'Combined: %s\n', fullfile(opts.out_dir, 'convergence_all_maps_all10.png'));
fprintf(1, 'Per-map dir: %s\n', opts.results_per_map_dir);
end

function plot_map_curves_on_axes(ax, mn, curves_all, algos10, style, opts, cfg, ylab, do_inset)
if ~isfield(curves_all, mn)
    text(ax, 0.5, 0.5, sprintf('No data for %s', mn), 'HorizontalAlignment', 'center');
    title(ax, mn, 'FontName', opts.font_name, 'FontSize', opts.font_size + 1);
    grid(ax, 'on');
    return;
end
cmap = curves_all.(mn);
hold(ax, 'on');
for ai = 1:numel(algos10)
    algo = algos10{ai};
    fn = matlab.lang.makeValidName(algo);
    if ~isfield(cmap, fn), continue; end
    M = cmap.(fn);
    y = aggregate_curve_for_plot(M, opts.use_cummin);
    it = 1:numel(y);
    st = style.(fn);
    is_ours = strcmpi(algo, opts.our_algo);
    lw = st.line_width;
    if is_ours, lw = max(lw, 2.4); end
    p = plot(ax, it, y, 'LineStyle', st.line_style, 'Color', st.color, ...
        'LineWidth', lw, 'Marker', st.marker, 'MarkerIndices', 1:10:numel(y), ...
        'MarkerSize', st.marker_size, 'MarkerFaceColor', st.color, ...
        'DisplayName', algo);
    if is_ours
        set(p, 'LineWidth', 2.6);
    end
end
hold(ax, 'off');
grid(ax, 'on');
box(ax, 'on');
xlabel(ax, 'Iteration', 'FontName', opts.font_name, 'FontSize', opts.font_size);
ylabel(ax, ylab, 'FontName', opts.font_name, 'FontSize', opts.font_size);
title(ax, mn, 'FontName', opts.font_name, 'FontSize', opts.font_size + 1);
set(ax, 'FontName', opts.font_name, 'FontSize', opts.font_size);
xlim(ax, [1 cfg.exp.iterations]);
if do_inset && opts.do_inset
    add_convergence_inset(ax, cmap, algos10, style, opts);
end
end

function add_bottom_legend(fig, algos, style, opts)
% 图窗底部横向图例，明确每根线对应的算法（颜色/线型/标记与主图一致）
n = numel(algos);
h = gobjects(n, 1);
axd = axes(fig, 'Position', [0.08 0.02 0.84 0.10], 'Visible', 'off', 'HitTest', 'off');
hold(axd, 'on');
for ai = 1:n
    algo = algos{ai};
    fn = matlab.lang.makeValidName(algo);
    st = style.(fn);
    is_ours = strcmpi(algo, opts.our_algo);
    lw = st.line_width;
    if is_ours, lw = max(lw, 2.4); end
    h(ai) = plot(axd, nan, nan, 'LineStyle', st.line_style, 'Color', st.color, ...
        'LineWidth', lw, 'Marker', st.marker, 'MarkerSize', st.marker_size + 2, ...
        'MarkerFaceColor', st.color, 'DisplayName', algo);
    if is_ours
        set(h(ai), 'LineWidth', 2.6);
    end
end
hold(axd, 'off');
xlim(axd, [0 1]);
ylim(axd, [0 1]);
leg = legend(axd, h, algos, 'Orientation', 'horizontal', 'Location', 'north', ...
    'FontName', opts.font_name, 'FontSize', max(7, opts.font_size - 1), 'Box', 'on');
try
    ncol = min(5, n);
    leg.NumColumns = ncol;
catch
end
try
    leg.ItemTokenSize = [22, 11];
catch
end
set(axd, 'XColor', 'none', 'YColor', 'none', 'XTick', [], 'YTick', [], 'Color', 'none', 'Box', 'off');
end

function curves = load_merged_curves(cfg, algos, result_mat_path)
if nargin >= 3 && ~isempty(result_mat_path) && isfile(result_mat_path)
    S = load(result_mat_path, 'out');
    if ~isfield(S, 'out') || ~isfield(S.out, 'curves')
        error('plot_convergence:BadMat', '%s must contain variable out with field curves.', result_mat_path);
    end
    curves = ensure_curve_fields_for_algos(S.out.curves, algos, cfg.maps.names(:));
    return;
end

zoo = cfg.exp.algorithms_zoo30;
maps = cfg.maps.names(:);
if isstring(maps), maps = cellstr(maps); end
curves = struct();
for mi = 1:numel(maps)
    curves.(maps{mi}) = struct();
end

cache = struct();
for ai = 1:numel(algos)
    algo = algos{ai};
    zi = find(strcmpi(string(zoo), string(algo)), 1);
    if isempty(zi)
        error('plot_convergence:AlgoNotInZoo', 'Algorithm %s not found in cfg.exp.algorithms_zoo30.', algo);
    end
    b = ceil(zi / 10);
    ck = sprintf('b%d', b);
    if ~isfield(cache, ck)
        p = fullfile(cfg.paths.results, sprintf('global_experiments_batch%d', b), 'mat', 'global_results.mat');
        if ~isfile(p)
            error('plot_convergence:MissingMat', ...
                'Missing %s. Run main_run_global_experiments_batch(%d) or set opts.result_mat.', p, b);
        end
        tmp = load(p, 'out');
        cache.(ck) = tmp.out;
    end
    o = cache.(ck);
    fn_std = matlab.lang.makeValidName(algo);
    for mi = 1:numel(maps)
        mn = maps{mi};
        if ~isfield(o.curves, mn)
            warning('plot_convergence:MissingMap', 'No curve block for map %s in batch.', mn);
            continue;
        end
        cmap = o.curves.(mn);
        src = resolve_curve_fieldname(cmap, algo);
        if isempty(src)
            warning('plot_convergence:MissingCurve', ...
                'No curve for map %s / algorithm %s (batch %d). Check records vs mat field names (e.g. LLM-EEFO vs EEFOLLM).', ...
                mn, algo, b);
            continue;
        end
        % 统一到 paper 使用的字段名 fn_std，便于后续 style / plot
        curves.(mn).(fn_std) = cmap.(src);
    end
end
curves = ensure_curve_fields_for_algos(curves, algos, maps);
end

function curves = ensure_curve_fields_for_algos(curves, algos, maps)
% 将 LLM-EEFO / xLLMEEFO 等别名拷贝到 makeValidName(当前论文名) 下，供绘图统一访问。
if isstring(maps), maps = cellstr(maps); end
maps = maps(:);
for mi = 1:numel(maps)
    mn = maps{mi};
    if ~isfield(curves, mn), continue; end
    cmap = curves.(mn);
    for ai = 1:numel(algos)
        algo = algos{ai};
        fn_std = matlab.lang.makeValidName(algo);
        if isfield(cmap, fn_std), continue; end
        src = resolve_curve_fieldname(cmap, algo);
        if ~isempty(src)
            cmap.(fn_std) = cmap.(src);
        end
    end
    curves.(mn) = cmap;
end
end

function src = resolve_curve_fieldname(cmap, algo)
% run_experiment_batch 用 makeValidName(algo) 存字段；旧实验可能为 LLM-EEFO -> xLLMEEFO 等。
if isempty(cmap) || ~isstruct(cmap)
    src = '';
    return;
end
fn_std = matlab.lang.makeValidName(algo);
if isfield(cmap, fn_std)
    src = fn_std;
    return;
end
% 常见别名（与 generate_main_tables / records 一致）
aliases = { algo, 'LLM-EEFO', 'LLMEEFO', 'LLM_EEFO' };
if strcmpi(algo, 'EEFOLLM')
    aliases = [aliases, {'LLM-EEFO', 'LLM_EEFO', 'EEFO_LLM'}];
end
for ai = 1:numel(aliases)
    fn = matlab.lang.makeValidName(aliases{ai});
    if isfield(cmap, fn)
        src = fn;
        return;
    end
end
% 不区分大小写匹配已有字段
fns = fieldnames(cmap);
for i = 1:numel(fns)
    if strcmpi(fns{i}, algo) || strcmpi(strrep(fns{i}, '_', ''), strrep(algo, '_', ''))
        src = fns{i};
        return;
    end
end
% EEFOLLM：mat 中可能仅存 LLM-EEFO 对应的合法字段名
if strcmpi(algo, 'EEFOLLM')
    hit = {};
    for i = 1:numel(fns)
        low = lower(fns{i});
        if (contains(low, 'llm') && contains(low, 'eefo')) || strcmpi(fns{i}, 'EEFOLLM')
            hit{end+1} = fns{i}; %#ok<AGROW>
        end
    end
    if numel(hit) == 1
        src = hit{1};
        return;
    end
end
src = '';
end

function y = aggregate_curve_for_plot(M, use_cummin)
if isempty(M), y = []; return; end
[n, T] = size(M);
if ~use_cummin
    y = mean(M, 1, 'omitnan');
    return;
end
Mc = nan(n, T);
for r = 1:n
    Mc(r, :) = best_so_far_series(M(r, :));
end
y = mean(Mc, 1, 'omitnan');
end

function v = best_so_far_series(vin)
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

function style = build_line_styles(algos, our_algo)
colors = [
    0.00 0.45 0.74; 0.85 0.33 0.10; 0.93 0.69 0.13; 0.49 0.18 0.56; 0.47 0.67 0.19;
    0.30 0.75 0.93; 0.64 0.08 0.18; 0.00 0.60 0.50; 0.75 0.75 0.00; 0.45 0.45 0.45
    ];
markers = {'o', 's', '^', 'd', 'v', '>', '<', 'p', 'h', 'x'};
lines = {'-', '-', '--', '--', '-.', '-', ':', '-', '--', '-.'};
for i = 1:numel(algos)
    fn = matlab.lang.makeValidName(algos{i});
    style.(fn) = struct();
    if strcmpi(algos{i}, our_algo)
        style.(fn).color = [0.85 0.10 0.15];
        style.(fn).line_width = 2.4;
    else
        style.(fn).color = colors(mod(i-1, size(colors,1)) + 1, :);
        style.(fn).line_width = 1.15;
    end
    style.(fn).line_style = lines{mod(i-1, numel(lines)) + 1};
    style.(fn).marker = markers{mod(i-1, numel(markers)) + 1};
    style.(fn).marker_size = 4;
end
end

function add_convergence_inset(ax_parent, cmap, algos_order, style, opts)
try
    fig = ancestor(ax_parent, 'figure');
    set(fig, 'Units', 'normalized');
    pos = get(ax_parent, 'Position');
    w = pos(3) * 0.40;
    h = pos(4) * 0.32;
    x0 = pos(1) + pos(3) * 0.55;
    y0 = pos(2) + pos(4) * 0.58;
    ax_in = axes('Parent', fig, 'Position', [x0 y0 w h], 'Box', 'on');
    hold(ax_in, 'on');
    for ai = 1:numel(algos_order)
        algo = algos_order{ai};
        fn = matlab.lang.makeValidName(algo);
        if ~isfield(cmap, fn), continue; end
        M = cmap.(fn);
        y = aggregate_curve_for_plot(M, opts.use_cummin);
        it = 1:numel(y);
        st = style.(fn);
        is_ours = strcmpi(algo, opts.our_algo);
        lw = st.line_width;
        if is_ours, lw = 2.2; end
        plot(ax_in, it, y, 'LineStyle', st.line_style, 'Color', st.color, ...
            'LineWidth', lw, 'Marker', 'none');
    end
    hold(ax_in, 'off');
    xlim(ax_in, opts.inset_iter_range);
    ylim(ax_in, 'auto');
    grid(ax_in, 'on');
    set(ax_in, 'FontSize', max(6, opts.font_size - 3), 'FontName', opts.font_name);
    set(ax_in, 'XTick', opts.inset_iter_range(1):40:opts.inset_iter_range(2));
catch
end
end

function export_fig_vector_raster(f, base_path)
png = [base_path, '.png'];
svg = [base_path, '.svg'];
if exist('exportgraphics', 'file')
    exportgraphics(f, png, 'Resolution', 300);
    try
        exportgraphics(f, svg, 'ContentType', 'vector');
    catch
        try
            saveas(f, svg);
        catch
            warning('plot_convergence:NoSvg', 'SVG export failed; PNG only saved.');
        end
    end
else
    print(f, png, '-dpng', '-r300');
    try
        print(f, svg, '-dsvg');
    catch
    end
end
end
