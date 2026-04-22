function varargout = generate_map_setting_table(opts)
%GENERATE_MAP_SETTING_TABLE 从固定 5 张 benchmark 地图生成「地图设定表」（论文主文 Table 1 用）。
%
%   自动读取 generate_maps(cfg) 加载的 map_data.grid，并调用 extract_map_features 提取走廊宽度与杂乱度。
%   Start / Goal 为网格下标，格式 [row,col]（与 mapscripts/generate_maps.m、路径规划代码一致）。
%
%   列: Map | Grid Size | Start | Goal | Obstacle Blocks | Obstacle Density | Complexity Level
%        | Avg Corridor Width | Clutter Score
%
%   Complexity Level 根据 cfg 中地图角色（尺寸 + 目标密度）标注为 low / medium / high / very high。
%
%   输出目录: results/tables/paper_main/（可用 opts.out_subdir 修改）
%     - table1_map_settings.csv
%     - table1_map_settings.tex       （booktabs，无竖线）
%     - table1_map_settings_word.txt （制表符分隔，便于粘贴到 Word）
%     - map_setting_tables.mat       （变量 T）
%
%   用法: generate_map_setting_table

if nargin < 1, opts = struct(); end
if ~isfield(opts, 'out_subdir'), opts.out_subdir = 'paper_main'; end

root_dir = fileparts(mfilename('fullpath'));
addpath(root_dir);
addpath(fullfile(root_dir, 'config'));
addpath(fullfile(root_dir, 'utils'));
addpath(fullfile(root_dir, 'mapscripts'));
init_paths(root_dir);

cfg = default_config();
map_list = generate_maps(cfg);

n = numel(map_list);
Map = cell(n, 1);
GridSize = cell(n, 1);
Start = cell(n, 1);
Goal = cell(n, 1);
ObstacleBlocks = zeros(n, 1);
ObstacleDensity = zeros(n, 1);
ComplexityLevel = cell(n, 1);
AvgCorridorWidth = zeros(n, 1);
ClutterScore = zeros(n, 1);

for i = 1:n
    md = map_list{i};
    feat = extract_map_features(md, '');
    Map{i, 1} = char(string(md.name));
    GridSize{i, 1} = sprintf('%dx%d', md.size(1), md.size(2));
    Start{i, 1} = sprintf('[%d,%d]', md.start(1), md.start(2));
    Goal{i, 1} = sprintf('[%d,%d]', md.goal(1), md.goal(2));
    ObstacleBlocks(i, 1) = feat.num_obstacle_blocks;
    ObstacleDensity(i, 1) = feat.obstacle_density;
    ComplexityLevel{i, 1} = label_complexity_level(i);
    AvgCorridorWidth(i, 1) = feat.avg_corridor_width_est;
    ClutterScore(i, 1) = feat.clutter_score;
end

T = table(Map, GridSize, Start, Goal, ObstacleBlocks, ObstacleDensity, ComplexityLevel, ...
    AvgCorridorWidth, ClutterScore, ...
    'VariableNames', {'Map', 'GridSize', 'Start', 'Goal', 'ObstacleBlocks', 'ObstacleDensity', ...
    'ComplexityLevel', 'AvgCorridorWidth', 'ClutterScore'});

out_dir = fullfile(cfg.paths.results, 'tables', opts.out_subdir);
ensure_dir(out_dir);
writetable(T, fullfile(out_dir, 'table1_map_settings.csv'));
write_text(fullfile(out_dir, 'table1_map_settings.tex'), latex_map_settings_table(T));
write_text(fullfile(out_dir, 'table1_map_settings_word.txt'), word_tabdelimited_table(T));
save(fullfile(out_dir, 'map_setting_tables.mat'), 'T', 'cfg', '-v7');

fprintf(1, 'Map setting table written to %s\n', out_dir);

if nargout > 0
    varargout{1} = T;
end
end

function s = label_complexity_level(idx)
% 与 default_config 中五张图的设计角色一致（尺寸 + 目标障碍物覆盖率）。
switch idx
    case 1
        s = 'low';
    case 2
        s = 'medium';
    case 3
        s = 'very high';
    case 4
        s = 'medium';
    case 5
        s = 'high';
    otherwise
        s = 'medium';
end
end

function tex = latex_map_settings_table(T)
hdr = {'Map', 'Grid Size', 'Start', 'Goal', 'Obs. Blocks', 'Obs. Density', 'Compl.', 'Avg Corr. Width', 'Clutter'};
na = height(T);
parts = cell(1, na + 7);
parts{1} = '% Requires: \usepackage{booktabs}';
parts{2} = '\begin{tabular}{@{}lcccccccc@{}}';
parts{3} = '\toprule';
parts{4} = [strjoin(hdr, ' & '), ' \\\\'];
parts{5} = '\midrule';
pi = 5;
for i = 1:na
    gs = latex_grid_size_cell(T.GridSize{i});
    cl = strrep(T.ComplexityLevel{i}, ' ', '~');
    pi = pi + 1;
    parts{pi} = sprintf('%s & %s & %s & %s & %d & %s & %s & %s & %s \\\\', ...
        escape_tex_basic(T.Map{i}), gs, escape_tex_basic(T.Start{i}), escape_tex_basic(T.Goal{i}), ...
        T.ObstacleBlocks(i), fmt_tex_fixed(T.ObstacleDensity(i), 4), ...
        escape_tex_basic(cl), ...
        fmt_tex_fixed(T.AvgCorridorWidth(i), 3), fmt_tex_fixed(T.ClutterScore(i), 3));
end
parts{pi + 1} = '\bottomrule';
parts{pi + 2} = '\end{tabular}';
tex = sprintf('%s\n', parts{1:pi + 2});
end

function s = latex_grid_size_cell(gs)
% "40x70" -> $40\times70$
tok = regexp(char(gs), '^(\d+)x(\d+)$', 'tokens', 'once');
if ~isempty(tok)
    s = sprintf('$%s\\times%s$', tok{1}, tok{2});
else
    s = escape_tex_basic(gs);
end
end

function s = word_tabdelimited_table(T)
hdr = T.Properties.VariableNames;
lines = strjoin(hdr, sprintf('\t'));
for i = 1:height(T)
    row = {fmt_row_cell(T.Map{i}), fmt_row_cell(T.GridSize{i}), fmt_row_cell(T.Start{i}), ...
        fmt_row_cell(T.Goal{i}), sprintf('%d', T.ObstacleBlocks(i)), sprintf('%.4f', T.ObstacleDensity(i)), ...
        T.ComplexityLevel{i}, sprintf('%.3f', T.AvgCorridorWidth(i)), sprintf('%.3f', T.ClutterScore(i))};
    lines = sprintf('%s\n%s', lines, strjoin(row, sprintf('\t')));
end
s = [lines, sprintf('\n')];
end

function s = fmt_row_cell(c)
s = strrep(char(string(c)), sprintf('\n'), ' ');
end

function s = fmt_tex_fixed(x, nd)
s = sprintf(['%.' int2str(nd) 'f'], x);
end

function s = escape_tex_basic(str)
s = strrep(str, '_', '\_');
s = strrep(s, '%', '\%');
s = strrep(s, '&', '\&');
end

function write_text(path_str, txt)
fid = fopen(path_str, 'w');
if fid < 0, error('Cannot write %s', path_str); end
try
    fwrite(fid, txt, 'char');
finally
    fclose(fid);
end
end
