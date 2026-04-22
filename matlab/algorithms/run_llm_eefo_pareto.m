function [bestSol, bestFit, curve, history] = run_llm_eefo_pareto(problem, params)
%RUN_LLM_EEFO_PARETO Registered **EEFOLLM-PARETO** — LLM 阶段权重 + NSGA-II；与 OAW 不混用。
params.use_stage_weights = true;
params.use_online_adaptive_weights = false;
[bestSol, bestFit, curve, history] = run_pareto_nsga2(problem, params);
end
