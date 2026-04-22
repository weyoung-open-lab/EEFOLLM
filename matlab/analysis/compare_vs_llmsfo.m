function cmp_tbl = compare_vs_llmsfo(records, refName)
%COMPARE_VS_LLMSFO Aggregate metrics per algorithm vs reference (default EEFOLLM).
%   Flags:
%     Weaker_MeanBestFitOnly — mean BestFit higher than reference (single metric).
%     Weaker_AllThreeMetrics — strictly worse mean BestFit, success rate, AND
%       collision-free rate than reference (strong condition; often empty).
%
%   Runtime is reported but not used for dominance (speed != solution quality).

if nargin < 2 || isempty(refName)
    refName = 'EEFOLLM';
end

if ischar(records) || isstring(records)
    T = readtable(records);
else
    T = records;
end

T.Algorithm = cellstr(string(T.Algorithm));
algos = unique(T.Algorithm, 'stable');

ref_idx = find(strcmp(algos, refName), 1);
if isempty(ref_idx) && strcmp(refName, 'EEFOLLM')
    ref_idx = find(strcmp(algos, 'LLM-EEFO'), 1);
    if ~isempty(ref_idx)
        refName = 'LLM-EEFO';
    end
end
if isempty(ref_idx)
    error('compare_vs_llmsfo:ReferenceNotFound', 'Reference algorithm "%s" not in records.', refName);
end

ref_rows = T(strcmp(T.Algorithm, refName), :);
ref_bf = mean(ref_rows.BestFit, 'omitnan');
ref_succ = mean(double(ref_rows.Success), 'omitnan');
ref_cf = mean(double(ref_rows.CollisionFree), 'omitnan');
ref_rt = mean(ref_rows.Runtime, 'omitnan');

eps_bf = 1e-9 * max(1, abs(ref_bf));

n = numel(algos);
mean_bf = nan(n, 1);
mean_succ = nan(n, 1);
mean_cf = nan(n, 1);
mean_rt = nan(n, 1);
worse_bf = false(n, 1);
worse_succ = false(n, 1);
worse_cf = false(n, 1);
weaker_three = false(n, 1);
weaker_bf_only = false(n, 1);

for i = 1:n
    sub = T(strcmp(T.Algorithm, algos{i}), :);
    mean_bf(i) = mean(sub.BestFit, 'omitnan');
    mean_succ(i) = mean(double(sub.Success), 'omitnan');
    mean_cf(i) = mean(double(sub.CollisionFree), 'omitnan');
    mean_rt(i) = mean(sub.Runtime, 'omitnan');

    if i == ref_idx
        continue;
    end
    worse_bf(i) = mean_bf(i) > ref_bf + eps_bf;
    worse_succ(i) = mean_succ(i) < ref_succ - 1e-12;
    worse_cf(i) = mean_cf(i) < ref_cf - 1e-12;
    weaker_three(i) = worse_bf(i) && worse_succ(i) && worse_cf(i);
    weaker_bf_only(i) = worse_bf(i);
end

cmp_tbl = table(string(algos), mean_bf, mean_succ, mean_cf, mean_rt, ...
    worse_bf, worse_succ, worse_cf, weaker_three, weaker_bf_only, ...
    'VariableNames', {'Algorithm', 'MeanBestFit', 'MeanSuccessRate', 'MeanCollisionFreeRate', 'MeanRuntime', ...
    'WorseMeanBestFitThanRef', 'WorseSuccessThanRef', 'WorseCollisionFreeThanRef', ...
    'Weaker_AllThreeMetrics', 'Weaker_MeanBestFitOnly'});

end
