function main_run_llm_eefo_pareto()
%MAIN_RUN_LLM_EEFO_PARETO EEFOLLM-PARETO (EEFO + LLM stage weights + NSGA-II multi-objective).
%   5 maps x runs_per_map (default 20). OAW off by default.
%
%   Output: results/eefo_llm_pareto/, figures/eefo_llm_pareto/, logs/eefo_llm_pareto.log

root_dir = fileparts(mfilename('fullpath'));
addpath(fullfile(root_dir, 'config'));
addpath(fullfile(root_dir, 'utils'));
cfg = default_config();
cfg.online_adaptive.enable = false;
llm_eefo_solo_run(cfg, 'eefo_llm_pareto', 'EEFOLLM-PARETO');
end
