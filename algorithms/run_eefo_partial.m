function [bestSol, bestFit, curve, history] = run_eefo_partial(problem, params)
%RUN_EEFO_PARTIAL Registered name **EEFO-PARTIAL** — static weights + ablated EEFO (guide-only).
%   Fair baseline: same minimal search operator as EEFOLLM-PARTIAL but cfg.weights.default only.
params.eefo_variant = 'guide_only';
[bestSol, bestFit, curve, history] = run_eefo(problem, params);
end
