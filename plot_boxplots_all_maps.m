function plot_boxplots_all_maps(opts)
%PLOT_BOXPLOTS_ALL_MAPS 五张 benchmark 地图各一张箱线图：10 算法 × 20 次独立实验最终 BestFit。
%
%   数据来源与 generate_main_tables 一致：records_merged.csv 或 batch1~3 合并；LLM-EEFO → EEFOLLM。
%   每列原始 20 次 BestFit（不足则为 NaN），不使用均值代替。
%
%   当不同算法最优值跨度很大（如 MPA 与其它方法差多个数量级）时，默认使用对数纵轴以便比较；
%   可用 opts.y_scale='linear' 强制线性坐标（此时个别方法会拉高纵轴，其它箱体被压扁属正常现象）。
%   红色「+」仅为箱线图规则下的离群点；无离群点则不会显示。
%   跨度大时不再依赖 YScale=log（易被 boxplot/导出打回线性刻度），改为对数据取 log10 后在线性 Y 上作图，
%   纵轴为 log10(fitness)，箱体与分位数均在 log10 空间计算。
%
%   输出（每张地图各一份 PNG + SVG）：
%     figures/paper_main/boxplot_fitness_Map1..Map5
%     results/boxplot_maps/boxplot_Map1..Map5_all10
%
%   用法（工程根目录）：
%     plot_boxplots_all_maps
%     plot_boxplots_all_maps(struct('records_csv', 'path/to/records.csv', 'y_scale', 'log'))
%
%   若 MATLAB 导出/坐标异常，推荐改用 Python（matplotlib，对数 Y + 散点叠加）：
%     python plot_boxplots_all_maps.py

if nargin < 1, opts = struct(); end
if ~isfield(opts, 'expected_runs'), opts.expected_runs = 20; end
if ~isfield(opts, 'out_dir'), opts.out_dir = ''; end
if ~isfield(opts, 'records_csv'), opts.records_csv = ''; end
if ~isfield(opts, 'font_name'), opts.font_name = 'Times New Roman'; end
if ~isfield(opts, 'font_size'), opts.font_size = 9; end
if ~isfield(opts, 'y_scale'), opts.y_scale = 'auto'; end %#ok<*STRQUOT>
if ~isfield(opts, 'log_ratio_thresh'), opts.log_ratio_thresh = 50; end
if ~isfield(opts, 'tick_angle'), opts.tick_angle = 40; end
if ~isfield(opts, 'fig_width_px'), opts.fig_width_px = 1280; end
if ~isfield(opts, 'fig_height_px'), opts.fig_height_px = 520; end

root_dir = fileparts(mfilename('fullpath'));
addpath(root_dir);
addpath(fullfile(root_dir, 'config'));
addpath(fullfile(root_dir, 'utils'));
cfg = default_config();
init_paths(cfg.paths.root);

if isempty(opts.out_dir)
    opts.out_dir = fullfile(cfg.paths.figures, 'paper_main');
end
ensure_dir(opts.out_dir);
res_box_dir = fullfile(cfg.paths.results, 'boxplot_maps');
ensure_dir(res_box_dir);

[algos10, ~] = paper_benchmark_algorithms10();
maps = cfg.maps.names(:);
if isstring(maps), maps = cellstr(maps); end

T = load_records_for_boxplot(opts, cfg);
T = normalize_algo_boxplot(T);
T.Algorithm = cellstr(string(T.Algorithm));
T.Map = cellstr(string(T.Map));

exp_maps = maps(:);
exp_algos = algos10(:);
T = T(ismember(string(T.Map), string(exp_maps)) & ismember(string(T.Algorithm), string(exp_algos)), :);

ylab_base = 'Fitness value';
nG = numel(exp_algos);
% 轮廓式箱线图 + 深色线（勿用 BoxStyle=filled：exportgraphics 出 SVG 时常把浅灰填充/描边
% 画成极淡的 line，白底上几乎看不见；PNG 上亦可能类似）
lineRgb = [0.22 0.32 0.45];
boxColors = repmat(lineRgb, nG, 1);

lbls = cellfun(@char, exp_algos, 'UniformOutput', false);

for k = 1:5
    mn = exp_maps{k};
    M = build_bestfit_matrix(T, mn, exp_algos, opts.expected_runs);

    useLog = pick_y_scale(M, opts);
    ylab = ylab_base;
    if useLog
        ylab = [ylab_base, ' (log10 scale; lower is better)'];
    end

    f = figure('Color', 'w', 'Units', 'pixels', ...
        'Position', [80 80 opts.fig_width_px opts.fig_height_px]);
    ax = axes('Parent', f);
    Mplot = M;
    if useLog
        Mplot(Mplot <= 0) = NaN;
        Mplot = log10(Mplot);
    end

    % 使用 'Parent' 兼容旧版；轮廓线宽、略加宽箱体
    h = boxplot(Mplot, 'Parent', ax, 'Labels', lbls, ...
        'Symbol', 'r+', 'OutlierSize', 5, 'Whisker', 1.5, ...
        'Colors', boxColors, 'Widths', 0.55);
    if ~isempty(h)
        try
            set(h, 'LineWidth', 1.05);
        catch
        end
    end
    % 统一加深所有箱线元素（部分版本 Colors 未覆盖全部句柄）
    darken_boxplot_lines(ax, lineRgb);

    grid(ax, 'on');
    box(ax, 'on');
    ylabel(ax, ylab, 'FontName', opts.font_name, 'FontSize', opts.font_size + 1);
    title(ax, sprintf('%s — distribution of final fitness (20 independent runs)', mn), ...
        'FontName', opts.font_name, 'FontSize', opts.font_size + 2, 'FontWeight', 'normal');
    set(ax, 'FontName', opts.font_name, 'FontSize', opts.font_size);
    set(ax, 'TickLabelInterpreter', 'none');
    xtickangle(ax, opts.tick_angle);

    % 为斜置标签留出下边距
    set(ax, 'Position', [0.10 0.20 0.86 0.68]);

    if useLog
        vm = Mplot(isfinite(Mplot));
        if ~isempty(vm)
            ylim(ax, [min(vm(:)) - 0.18, max(vm(:)) + 0.18]);
        end
        set(ax, 'YTickMode', 'auto');
    end
    style_boxplot_medians(ax);

    drawnow;
    baseFig = fullfile(opts.out_dir, sprintf('boxplot_fitness_%s', mn));
    baseRes = fullfile(res_box_dir, sprintf('boxplot_%s_all10', mn));
    export_fig_vector_raster_box(f, baseFig);
    export_fig_vector_raster_box(f, baseRes);
    close(f);

    fprintf(1, 'Saved: %s / %s (PNG+SVG)\n', baseFig, baseRes);
end
end

function useLog = pick_y_scale(M, opts)
useLog = false;
ys = char(string(opts.y_scale));
switch lower(strtrim(ys))
    case 'log'
        useLog = true;
    case 'linear'
        useLog = false;
    case 'auto'
        % isfinite(M) 与 M 同尺寸；勿与 M(:)>0 混用（列向量与矩阵尺寸不兼容）
        v = M(isfinite(M) & M > 0);
        if numel(v) < 2
            return;
        end
        r = max(v) / min(v);
        useLog = isfinite(r) && (r >= opts.log_ratio_thresh);
    otherwise
        useLog = false;
end
end

function darken_boxplot_lines(ax, rgb)
% 将箱线图中的 line 统一为可见深色（避免浅灰线在白纸/矢量导出中消失）
L = findall(ax, 'Type', 'line');
for i = 1:numel(L)
    t = get(L(i), 'Tag');
    if iscell(t), t = t{1}; end
    t = char(string(t));
    % 保留离群点为红色；其余（含无 Tag 的箱线）统一加深；中位数随后再改为黑色加粗
    if strcmpi(strtrim(t), 'Outliers')
        continue;
    end
    try
        set(L(i), 'Color', rgb);
    catch
    end
end
end

function style_boxplot_medians(ax)
hm = findall(ax, 'Tag', 'Median');
if isempty(hm), hm = findall(ax, 'Tag', 'median'); end
if ~isempty(hm)
    set(hm, 'Color', [0.05 0.05 0.05], 'LineWidth', 1.85);
end
end

function M = build_bestfit_matrix(T, map_name, algos, expected_runs)
na = numel(algos);
M = nan(expected_runs, na);
for ai = 1:na
    ix = strcmp(T.Map, map_name) & strcmp(T.Algorithm, algos{ai});
    sub = T(ix, :);
    for r = 1:expected_runs
        j = find(double(sub.Run) == r, 1);
        if ~isempty(j)
            M(r, ai) = sub.BestFit(j);
        end
    end
end
end

function T = load_records_for_boxplot(opts, cfg)
T = table();
if ~isempty(opts.records_csv) && isfile(opts.records_csv)
    T = readtable(opts.records_csv, 'TextType', 'string');
    return;
end
p = fullfile(cfg.paths.results, 'global_experiments_merged', 'tables', 'records_merged.csv');
if isfile(p)
    T = readtable(p, 'TextType', 'string');
    return;
end
try
    T = merge_global_experiment_batches();
catch
    T = merge_batches_mem_box(cfg);
end
end

function T = merge_batches_mem_box(cfg)
parts = {};
for b = 1:3
    f = fullfile(cfg.paths.results, sprintf('global_experiments_batch%d', b), 'tables', 'records.csv');
    if isfile(f)
        parts{end+1} = readtable(f, 'TextType', 'string'); %#ok<AGROW>
    end
end
if isempty(parts), T = table(); return; end
T = vertcat(parts{:});
end

function T = normalize_algo_boxplot(T)
a = string(T.Algorithm);
a(a == "LLM-EEFO") = "EEFOLLM";
T.Algorithm = cellstr(a);
end

function export_fig_vector_raster_box(f, base_path)
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
            warning('plot_boxplots:NoSvg', 'SVG export failed; PNG only saved.');
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
