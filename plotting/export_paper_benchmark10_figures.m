function export_paper_benchmark10_figures()
%EXPORT_PAPER_BENCHMARK10_FIGURES  Bar/heatmap figures: 9 baselines + EEFOLLM (see paper_benchmark_algorithms10).
%
%   Input:  results/tables/per_map_all_algorithms_long.csv
%   Output: figures/paper_benchmark_10/*.png, *.fig, and a sliced long CSV
%
%   From project root with path initialized: init_paths(pwd); export_paper_benchmark10_figures

root_dir = fileparts(fileparts(mfilename('fullpath')));
init_paths(root_dir);

cfg = default_config();
csv_path = fullfile(cfg.paths.results, 'tables', 'per_map_all_algorithms_long.csv');
if ~isfile(csv_path)
    error('Missing %s — run main_run_global_experiments_batch(1) or build the per-map table first.', csv_path);
end

tbl = readtable(csv_path, 'TextType', 'string');

[bench10, ~] = paper_benchmark_algorithms10();
missing = setdiff(bench10, unique(tbl.Algorithm));
if ~isempty(missing)
    warning('Algorithms missing from CSV: %s', strjoin(missing, ', '));
end

out_dir = fullfile(cfg.paths.figures, 'paper_benchmark_10');
plot_paper_benchmark10(cfg, tbl, out_dir);

sl = tbl(ismember(tbl.Algorithm, bench10), :);
out_csv = fullfile(cfg.paths.results, 'tables', 'paper_benchmark_10_per_map_long.csv');
writetable(sl, out_csv);
fprintf(1, 'Slice table: %s\n', out_csv);
end
