function [bestSol, bestFit, curve, history] = run_llm_eefo(problem, params)
%RUN_LLM_EEFO Registered name **EEFOLLM** — LLM-weighted EEFO; weights from generate_llm_weights.
%   Optional online adaptive weights: params.use_online_adaptive_weights + cfg.online_adaptive.enable.
%   Stage schedule: get_stage_weights / select_stage_weights (early/mid/late by iteration).
params.use_stage_weights = true;
[bestSol, bestFit, curve, history] = run_eefo(problem, params);
end
