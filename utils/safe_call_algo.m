function out = safe_call_algo(algo_func, problem, params)
%SAFE_CALL_ALGO Safely execute optimizer without breaking whole batch.
out.success = false;
out.error = '';
out.bestSol = [];
out.bestFit = inf;
out.curve = nan(1, params.max_iter);
out.history = [];
out.runtime = nan;
t0 = tic;
try
    [out.bestSol, out.bestFit, out.curve, out.history] = algo_func(problem, params);
    out.success = true;
catch ME
    out.error = ME.message;
end
out.runtime = toc(t0);
end
