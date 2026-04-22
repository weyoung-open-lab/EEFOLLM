function [bestSol, bestFit, curve, history] = run_llm_eefo_ns(problem, params)
%RUN_LLM_EEFO_NS Registered name **EEFOLLM-NS** — LLM stage weights + EEFO without Gaussian shock (no_shock).
%   Keeps guide toward global best and random re-init (prob 0.25); shock term disabled.
params.use_stage_weights = true;
params.eefo_variant = 'no_shock';
[bestSol, bestFit, curve, history] = run_eefo(problem, params);
end
