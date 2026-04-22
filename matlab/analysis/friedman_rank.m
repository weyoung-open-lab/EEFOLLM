function rank_tbl = friedman_rank(records_tbl)
%FRIEDMAN_RANK Compute average rank by map across algorithms.
maps = unique(records_tbl.Map);
algos = unique(records_tbl.Algorithm);
R = nan(numel(maps), numel(algos));
for i = 1:numel(maps)
    sub = records_tbl(strcmp(records_tbl.Map, maps{i}), :);
    mean_fit = nan(1, numel(algos));
    for j = 1:numel(algos)
        idx = strcmp(sub.Algorithm, algos{j});
        mean_fit(j) = mean(sub.BestFit(idx), 'omitnan');
    end
    [~, order] = sort(mean_fit, 'ascend');
    ranks = 1:numel(algos);
    rline = nan(1, numel(algos));
    rline(order) = ranks;
    R(i, :) = rline;
end
avg_rank = mean(R, 1, 'omitnan')';
rank_tbl = table(algos, avg_rank, 'VariableNames', {'Algorithm', 'AvgRank'});
rank_tbl = sortrows(rank_tbl, 'AvgRank', 'ascend');
end
