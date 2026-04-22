function [bestSol, bestFit, curve, history] = run_llm_eefo_nj(problem, params)
%RUN_LLM_EEFO_NJ Registered name **EEFOLLM-NJ** — LLM stage weights + EEFO without random re-init (no_jump).
%   Keeps shock and guide; probability of full-domain random restart set to 0.
params.use_stage_weights = true;
params.eefo_variant = 'no_jump';
[bestSol, bestFit, curve, history] = run_eefo(problem, params);
end
