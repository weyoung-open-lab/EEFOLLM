function [algos, tbl] = pick_smallest_mean_fitness_algorithms(records_path, n_keep)
%PICK_SMALLEST_MEAN_FITNESS_ALGORITHMS Rank algorithms by mean BestFit (all runs, all maps); keep n_keep smallest.
%   "最小" = 平均 BestFit 最小（越小越好）。

if nargin < 2 || isempty(n_keep)
    n_keep = 20;
end
if ischar(records_path) || isstring(records_path)
    T = readtable(records_path);
else
    T = records_path;
end
algs = unique(cellstr(string(T.Algorithm)), 'stable');
nA = numel(algs);
mean_fit = nan(nA, 1);
std_fit = nan(nA, 1);
nruns = nan(nA, 1);
for i = 1:nA
    idx = strcmp(cellstr(string(T.Algorithm)), algs{i});
    bf = T.BestFit(idx);
    mean_fit(i) = mean(bf, 'omitnan');
    std_fit(i) = std(bf, 0, 'omitnan');
    nruns(i) = numel(bf);
end
tbl = table(string(algs), mean_fit, std_fit, nruns, ...
    'VariableNames', {'Algorithm', 'MeanBestFit', 'StdBestFit', 'NumRows'});
tbl = sortrows(tbl, 'MeanBestFit', 'ascend');
n_keep = min(n_keep, height(tbl));
algos = cellstr(tbl.Algorithm(1:n_keep));
tbl = tbl(1:n_keep, :);
end
