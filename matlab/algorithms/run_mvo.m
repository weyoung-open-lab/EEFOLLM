function [bestSol, bestFit, curve, history] = run_mvo(problem, params)
%RUN_MVO Multi-Verse Optimizer (Mirjalili et al. 2016), simplified.
dim = problem.dim; lb = problem.lb(:)'; ub = problem.ub(:)';
n = params.pop_size; T = params.max_iter;
if isfield(params, 'seed'), set_seed(params.seed); end
WEPmin = 0.2; WEPmax = 1;
X = rand(n, dim) .* (ub - lb) + lb;
fit = inf(n, 1);
for i = 1:n
    fit(i) = metah_eval_fitness(problem, params, X(i, :), 1, T);
end
[bestFit, bidx] = min(fit); bestSol = X(bidx, :);
curve = nan(1, T); history = struct();
for it = 1:T
    WEP = WEPmin + it * ((WEPmax - WEPmin) / T);
    [sfit, ord] = sort(fit); XS = X(ord, :); fit = sfit(:);
    bestSol = XS(1, :);
    for i = 1:n
        r = rand;
        if r < 0.3
            X(i, :) = bestSol + 0.5 * (rand(1, dim) .* (ub - lb));
        elseif r < 0.6
            j = randi(n);
            X(i, :) = XS(i, :) + WEP * (rand(1, dim) .* (bestSol - XS(j, :)));
        else
            X(i, :) = XS(i, :) + 0.5 * (randn(1, dim) .* (bestSol - XS(i, :)));
        end
        X(i, :) = min(max(X(i, :), lb), ub);
        fit(i) = metah_eval_fitness(problem, params, X(i, :), it, T);
    end
    [bestFit, bidx] = min(fit);
    bestSol = X(bidx, :);
    curve(it) = bestFit;
end
end
