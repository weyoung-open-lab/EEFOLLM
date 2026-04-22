function plot_paths_all_maps(opts)
%PLOT_PATHS_ALL_MAPS 论文主图 Figure 3：五张 benchmark 地图上 10 算法最优路径对比。
%
%   从 global_experiments_batch1/2/3 的 mat/global_results.mat 合并 out.best_paths，
%   或 opts.result_mat 指向含 out.best_paths 的单个 mat。
%
%   输出：
%     figures/paper_main/path_planning_benchmark_maps.png|.svg   （五合一）
%     results/path_maps/path_planning_<MapName>.png|.svg           （每图单独）
%
%   仅地图、不要轨迹（不读 mat 结果）：
%     plot_paths_all_maps(struct('map_only', true, 'maps_subset', {{'Map3'}}))
%     main_plot_map_only   % 默认 Map3；第二参数 false 可隐藏起终点
%
%   用法（工程根目录）：
%     plot_paths_all_maps
%     plot_paths_all_maps(struct('result_mat', 'path/to/global_results.mat', 'per_map_dir', '...'))

if nargin < 1, opts = struct(); end
if ~isfield(opts, 'our_algo'), opts.our_algo = 'EEFOLLM'; end
if ~isfield(opts, 'out_dir'), opts.out_dir = ''; end
if ~isfield(opts, 'per_map_dir'), opts.per_map_dir = ''; end
if ~isfield(opts, 'result_mat'), opts.result_mat = ''; end
if ~isfield(opts, 'font_name'), opts.font_name = 'Times New Roman'; end
if ~isfield(opts, 'font_size'), opts.font_size = 9; end
if ~isfield(opts, 'show_axes'), opts.show_axes = true; end
% map_only=true：只画栅格（及可选起终点），不画各算法轨迹，且不读取 best_paths mat
if ~isfield(opts, 'map_only'), opts.map_only = false; end
% show_start_goal=true：在地图上标出起点/终点；false 则纯障碍栅格（仍用与路径图相同的配色）
if ~isfield(opts, 'show_start_goal'), opts.show_start_goal = true; end
% maps_subset：例如 {'Map3'} 只导出指定图；空 cell 则五张全导出
if ~isfield(opts, 'maps_subset'), opts.maps_subset = {}; end

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

if isempty(opts.per_map_dir)
    opts.per_map_dir = fullfile(cfg.paths.results, 'path_maps');
end
ensure_dir(opts.per_map_dir);

[algos10, ~] = paper_benchmark_algorithms10();
if opts.map_only
    paths_all = struct();
    pstyle = struct();
else
    paths_all = load_merged_best_paths(cfg, algos10, opts.result_mat);
    pstyle = build_path_styles(algos10, opts.our_algo);
end

map_list = generate_maps(cfg);
map_names = cfg.maps.names(:);
if isstring(map_names), map_names = cellstr(map_names); end
if ~isempty(opts.maps_subset)
    map_names = cellstr(opts.maps_subset(:));
end
nmaps = numel(map_names);

if nmaps > 1
    f = figure('Color', 'w', 'Units', 'normalized', 'Position', [0.03 0.05 0.82 0.88]);
    for k = 1:nmaps
        mn = map_names{k};
        ax = subplot(2, 3, k);
        map_data = local_find_map_data(map_list, mn);
        plot_paths_on_axes(ax, map_data, paths_all, mn, algos10, pstyle, opts);
        title(ax, mn, 'FontName', opts.font_name, 'FontSize', opts.font_size + 1, 'FontWeight', 'normal');
    end
    if exist('sgtitle', 'file')
        if opts.map_only
            sgtxt = 'Benchmark maps (obstacle layout)';
        else
            sgtxt = 'Figure 3. Path planning results of selected algorithms on five benchmark maps.';
        end
        sgtitle(f, sgtxt, 'FontName', opts.font_name, 'FontWeight', 'normal', 'FontSize', opts.font_size + 2);
    end
    base = fullfile(opts.out_dir, 'path_planning_benchmark_maps');
    export_fig_vector_raster(f, base);
    close(f);
    fprintf(1, 'Saved (combined): %s\n', [base, '.png']);
end

% --- 每张地图单独保存 ---
for k = 1:nmaps
    mn = map_names{k};
    map_data = local_find_map_data(map_list, mn);
    f1 = figure('Color', 'w', 'Units', 'normalized', 'Position', [0.08 0.08 0.62 0.82]);
    ax1 = axes(f1, 'Position', [0.10 0.10 0.82 0.82]);
    plot_paths_on_axes(ax1, map_data, paths_all, mn, algos10, pstyle, opts);
    title(ax1, mn, 'FontName', opts.font_name, 'FontSize', opts.font_size + 2, 'FontWeight', 'normal');
    if opts.map_only
        fname = ['map_only_', mn];
    else
        fname = ['path_planning_', mn];
    end
    base1 = fullfile(opts.per_map_dir, fname);
    export_fig_vector_raster(f1, base1);
    close(f1);
    fprintf(1, 'Saved: %s\n', [base1, '.png']);
end

fprintf(1, 'Per-map directory: %s\n', opts.per_map_dir);
end

function map_data = local_find_map_data(map_list, mn)
map_data = [];
for i = 1:numel(map_list)
    if strcmp(map_list{i}.name, mn)
        map_data = map_list{i};
        return;
    end
end
if isempty(map_data)
    error('plot_paths:MapNotFound', 'Map %s not found in generate_maps output.', mn);
end
end

function plot_paths_on_axes(ax, map_data, paths_all, mn, algos, pstyle, opts)
G = map_data.grid;
hold(ax, 'on');
imagesc(ax, G);
colormap(ax, [1 1 1; 0.78 0.66 0.88]);
axis(ax, 'equal');
axis(ax, 'tight');
set(ax, 'YDir', 'normal');
if ~opts.show_axes
    axis(ax, 'off');
else
    xlabel(ax, 'X', 'FontName', opts.font_name, 'FontSize', opts.font_size);
    ylabel(ax, 'Y', 'FontName', opts.font_name, 'FontSize', opts.font_size);
end
set(ax, 'FontName', opts.font_name, 'FontSize', opts.font_size);
if opts.show_axes
    grid(ax, 'on');
    box(ax, 'on');
else
    grid(ax, 'off');
end

if isfield(opts, 'show_start_goal') && opts.show_start_goal
    sx = map_data.start(1); sy = map_data.start(2);
    gx = map_data.goal(1); gy = map_data.goal(2);
    plot(ax, sx, sy, 'o', 'MarkerSize', 11, 'LineWidth', 2.2, ...
        'MarkerEdgeColor', [0.75 0 0.1], 'MarkerFaceColor', [1 0.25 0.2]);
    plot(ax, gx, gy, 's', 'MarkerSize', 11, 'LineWidth', 2.2, ...
        'MarkerEdgeColor', [0.65 0 0.15], 'MarkerFaceColor', [1 0.85 0.2]);
end

if isfield(opts, 'map_only') && opts.map_only
    hold(ax, 'off');
    return;
end

if ~isfield(paths_all, mn)
    hold(ax, 'off');
    return;
end
pmap = paths_all.(mn);

% 先画基线，最后画 EEFOLLM（最上层）
order = 1:numel(algos);
idx_ours = find(strcmpi(algos, opts.our_algo), 1);
if ~isempty(idx_ours)
    order = [order(order ~= idx_ours), idx_ours];
end

h = gobjects(0);
leg_lbl = {};
for ii = 1:numel(order)
    ai = order(ii);
    algo = algos{ai};
    fn = matlab.lang.makeValidName(algo);
    if ~isfield(pmap, fn), continue; end
    pts = pmap.(fn);
    if isempty(pts) || size(pts, 1) < 2, continue; end
    st = pstyle.(fn);
    is_ours = strcmpi(algo, opts.our_algo);
    lw = st.line_width;
    if is_ours, lw = max(lw, 3.2); end
    p = plot(ax, pts(:, 1), pts(:, 2), 'LineStyle', st.line_style, 'Color', st.color, ...
        'LineWidth', lw, 'DisplayName', algo);
    h(end+1) = p; %#ok<AGROW>
    leg_lbl{end+1} = algo; %#ok<AGROW>
end

hold(ax, 'off');
if ~isempty(h)
    leg = legend(ax, h, leg_lbl, 'Location', 'northwest', 'FontName', opts.font_name, ...
        'FontSize', max(6, opts.font_size - 1), 'Box', 'on');
    try
        leg.NumColumns = 2;
    catch
    end
end
end

function pstyle = build_path_styles(algos, our_algo)
colors = [
    0.00 0.35 0.65; 0.85 0.30 0.08; 0.75 0.55 0.00; 0.35 0.15 0.45; 0.20 0.55 0.20;
    0.25 0.65 0.85; 0.55 0.10 0.15; 0.00 0.50 0.45; 0.85 0.75 0.00; 0.45 0.45 0.45
    ];
lines = {'--', ':', '--', '-.', '--', ':', '--', '-.', '--'};
for i = 1:numel(algos)
    fn = matlab.lang.makeValidName(algos{i});
    pstyle.(fn) = struct();
    if strcmpi(algos{i}, our_algo)
        pstyle.(fn).color = [0.90 0.05 0.12];
        pstyle.(fn).line_width = 3.0;
        pstyle.(fn).line_style = '-';
    else
        pstyle.(fn).color = colors(mod(i-1, size(colors,1)) + 1, :);
        pstyle.(fn).line_width = 1.15;
        pstyle.(fn).line_style = lines{mod(i-1, numel(lines)) + 1};
    end
end
end

function paths_all = load_merged_best_paths(cfg, algos, result_mat_path)
if nargin >= 3 && ~isempty(result_mat_path) && isfile(result_mat_path)
    S = load(result_mat_path, 'out');
    if ~isfield(S, 'out') || ~isfield(S.out, 'best_paths')
        error('plot_paths:BadMat', '%s must contain out.best_paths.', result_mat_path);
    end
    paths_all = ensure_path_fields_for_algos(S.out.best_paths, algos, cfg.maps.names(:));
    return;
end

zoo = cfg.exp.algorithms_zoo30;
maps = cfg.maps.names(:);
if isstring(maps), maps = cellstr(maps); end
paths_all = struct();
for mi = 1:numel(maps)
    paths_all.(maps{mi}) = struct();
end

cache = struct();
for ai = 1:numel(algos)
    algo = algos{ai};
    zi = find(strcmpi(string(zoo), string(algo)), 1);
    if isempty(zi)
        error('plot_paths:AlgoNotInZoo', 'Algorithm %s not in algorithms_zoo30.', algo);
    end
    b = ceil(zi / 10);
    ck = sprintf('b%d', b);
    if ~isfield(cache, ck)
        p = fullfile(cfg.paths.results, sprintf('global_experiments_batch%d', b), 'mat', 'global_results.mat');
        if ~isfile(p)
            error('plot_paths:MissingMat', 'Missing %s. Run main_run_global_experiments_batch(%d) or set opts.result_mat.', p, b);
        end
        tmp = load(p, 'out');
        cache.(ck) = tmp.out;
    end
    o = cache.(ck);
    fn_std = matlab.lang.makeValidName(algo);
    for mi = 1:numel(maps)
        mn = maps{mi};
        if ~isfield(o.best_paths, mn)
            warning('plot_paths:MissingMap', 'No best_paths for map %s.', mn);
            continue;
        end
        pmap = o.best_paths.(mn);
        src = resolve_algo_struct_field(pmap, algo);
        if isempty(src)
            warning('plot_paths:MissingPath', 'No path for map %s / %s (batch %d).', mn, algo, b);
            continue;
        end
        paths_all.(mn).(fn_std) = pmap.(src);
    end
end
paths_all = ensure_path_fields_for_algos(paths_all, algos, maps);
end

function paths_all = ensure_path_fields_for_algos(paths_all, algos, maps)
if isstring(maps), maps = cellstr(maps); end
maps = maps(:);
for mi = 1:numel(maps)
    mn = maps{mi};
    if ~isfield(paths_all, mn), continue; end
    pmap = paths_all.(mn);
    for ai = 1:numel(algos)
        algo = algos{ai};
        fn_std = matlab.lang.makeValidName(algo);
        if isfield(pmap, fn_std), continue; end
        src = resolve_algo_struct_field(pmap, algo);
        if ~isempty(src)
            pmap.(fn_std) = pmap.(src);
        end
    end
    paths_all.(mn) = pmap;
end
end

function src = resolve_algo_struct_field(pmap, algo)
if isempty(pmap) || ~isstruct(pmap)
    src = '';
    return;
end
fn_std = matlab.lang.makeValidName(algo);
if isfield(pmap, fn_std)
    src = fn_std;
    return;
end
aliases = { algo, 'LLM-EEFO', 'LLMEEFO', 'LLM_EEFO' };
if strcmpi(algo, 'EEFOLLM')
    aliases = [aliases, {'LLM-EEFO', 'LLM_EEFO', 'EEFO_LLM'}];
end
for ai = 1:numel(aliases)
    fn = matlab.lang.makeValidName(aliases{ai});
    if isfield(pmap, fn)
        src = fn;
        return;
    end
end
fns = fieldnames(pmap);
for i = 1:numel(fns)
    if strcmpi(fns{i}, algo) || strcmpi(strrep(fns{i}, '_', ''), strrep(algo, '_', ''))
        src = fns{i};
        return;
    end
end
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
            warning('plot_paths:NoSvg', 'SVG export failed; PNG only saved.');
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
