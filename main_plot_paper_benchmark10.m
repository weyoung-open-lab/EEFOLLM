function main_plot_paper_benchmark10()
%MAIN_PLOT_PAPER_BENCHMARK10 出图：9 个近年对比算法 + **EEFOLLM**（共 10 个），数据来自汇总表。
%
%   算法列表见 config/paper_benchmark_algorithms10.m
%   输入: results/tables/per_map_all_algorithms_long.csv
%   输出: figures/paper_benchmark_10/*.png, *.fig
%
%   在工程根目录执行: main_plot_paper_benchmark10

root_dir = fileparts(mfilename('fullpath'));
addpath(fullfile(root_dir, 'config'));
addpath(fullfile(root_dir, 'utils'));
addpath(fullfile(root_dir, 'plotting'));
init_paths(root_dir);

cfg = default_config();
csv_path = fullfile(cfg.paths.results, 'tables', 'per_map_all_algorithms_long.csv');
if ~isfile(csv_path)
    error('Missing %s — run global experiments or place per-map table first.', csv_path);
end

tbl = readtable(csv_path, 'TextType', 'string');

[bench10, ~] = paper_benchmark_algorithms10();
missing = setdiff(bench10, unique(tbl.Algorithm));
if ~isempty(missing)
    warning('Algorithms missing from CSV: %s', strjoin(missing, ', '));
end

out_dir = fullfile(cfg.paths.figures, 'paper_benchmark_10');
plot_paper_benchmark10(cfg, tbl, out_dir);

% Save filtered long CSV for this paper slice
sl = tbl(ismember(tbl.Algorithm, bench10), :);
out_csv = fullfile(cfg.paths.results, 'tables', 'paper_benchmark_10_per_map_long.csv');
writetable(sl, out_csv);
fprintf(1, 'Slice table: %s\n', out_csv);
end
