function [bestSol, bestFit, curve, history] = run_llm_sfo(problem, params)
%RUN_LLM_SFO LLM-SFO wrapper: only reward weights differ from vanilla SFO.
params.use_stage_weights = true;
[bestSol, bestFit, curve, history] = run_sfo(problem, params);
end
