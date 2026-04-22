function main_run_eefollm_benchmark()
%MAIN_RUN_EEFOLLM_BENCHMARK EEFOLLM full benchmark: 5 maps x runs_per_map (default 20).
%
%   Output: results/eefollm_benchmark/, figures/eefollm_benchmark/, logs/eefollm_benchmark.log

root_dir = fileparts(mfilename('fullpath'));
addpath(fullfile(root_dir, 'config'));
addpath(fullfile(root_dir, 'utils'));
cfg = default_config();
init_paths(cfg.paths.root);
llm_eefo_solo_run(cfg, 'eefollm_benchmark');
end
