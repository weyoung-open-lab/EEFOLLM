function main_plot_map_only(map_name, show_start_goal)
%MAIN_PLOT_MAP_ONLY 只导出基准地图栅格（无算法轨迹），默认 Map3。
%
%   底图来自 generate_maps：与 maps/Map*.mat 及配置一致时，每次生成的障碍布局相同。
%   轨迹图若重跑优化会变化；本函数不读取 global_results.mat，与是否重跑实验无关。
%
%   map_name        例如 'Map3'（默认）
%   show_start_goal true 标起点/终点；false 仅障碍栅格（与路径图同款配色）
%
%   输出：results/path_maps/map_only_<MapName>.png|.svg（目录可改，见 plot_paths_all_maps）

if nargin < 1 || isempty(map_name)
    map_name = 'Map3';
end
if nargin < 2 || isempty(show_start_goal)
    show_start_goal = true;
end

opts = struct();
opts.map_only = true;
opts.maps_subset = {char(map_name)};
opts.show_start_goal = logical(show_start_goal);
plot_paths_all_maps(opts);
end
