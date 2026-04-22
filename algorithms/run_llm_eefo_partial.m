function [bestSol, bestFit, curve, history] = run_llm_eefo_partial(problem, params)
%RUN_LLM_EEFO_PARTIAL Registered name **EEFOLLM-PARTIAL** — LLM stage weights + ablated EEFO (guide-only).
%   Same LLM weight pipeline as EEFOLLM, but EEFO search uses eefo_variant='guide_only'
%   (no Gaussian shock, no random re-init) to isolate the effect of LLM reward shaping
%   when the base optimizer is minimal.
params.use_stage_weights = true;
params.eefo_variant = 'guide_only';
[bestSol, bestFit, curve, history] = run_eefo(problem, params);
end
