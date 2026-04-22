function idx = paper_benchmark_zoo_global_indices()
%PAPER_BENCHMARK_ZOO_GLOBAL_INDICES 论文对比 10 算法在 cfg.exp.algorithms_zoo30 中的全局序号 (1..30)。
%   与 run_experiment_batch 中 seed 公式一致：gidx 即此处返回值。
%
%   参见 paper_benchmark_algorithms10.m

[names, ~] = paper_benchmark_algorithms10();
cfg = default_config();
zo = cfg.exp.algorithms_zoo30;
idx = zeros(numel(names), 1);
for k = 1:numel(names)
    ix = find(strcmpi(zo, names{k}), 1);
    if isempty(ix)
        error('paper_benchmark_zoo_global_indices:Missing', ...
            'Algorithm ''%s'' not found in cfg.exp.algorithms_zoo30.', names{k});
    end
    idx(k) = ix;
end
end
