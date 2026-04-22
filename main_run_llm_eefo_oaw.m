function main_run_llm_eefo_oaw()
%MAIN_RUN_LLM_EEFO_OAW EEFOLLM + online adaptive weights (OAW): 5 maps x runs_per_map (default 20).
%
%   Output: results/eefollm_oaw/, figures/eefollm_oaw/, logs/eefollm_oaw.log

root_dir = fileparts(mfilename('fullpath'));
addpath(fullfile(root_dir, 'config'));
addpath(fullfile(root_dir, 'utils'));
cfg = default_config();
cfg.online_adaptive.enable = true;
llm_eefo_solo_run(cfg, 'eefollm_oaw');
end
