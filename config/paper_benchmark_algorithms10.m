function [names, order] = paper_benchmark_algorithms10()
%PAPER_BENCHMARK_ALGORITHMS10 Nine recent metaheuristics vs EEFOLLM (10 methods total).
%   Baselines (≈2017+ / 2020+ generation): AOA, EO, GTO, HHO, HO, MPA, SBOA, SMA, SSA.
%   Ours: EEFOLLM.
%
%   order: plot order (baselines first, ours last for emphasis in figures).
%
%   See main_plot_paper_benchmark10.m

names = { ...
    'AOA', 'EO', 'GTO', 'HHO', 'HO', 'MPA', 'SBOA', 'SMA', 'SSA', ...
    'EEFOLLM'};

order = 1:numel(names);
end
