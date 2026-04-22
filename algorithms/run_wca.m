function [bestSol, bestFit, curve, history] = run_wca(problem, params)
%RUN_WCA Water Cycle Algorithm (Eskandar et al. 2012), simplified continuous form.
dim = problem.dim; lb = problem.lb(:)'; ub = problem.ub(:)';
n = params.pop_size; T = params.max_iter; nsr = max(2, round(0.1 * n));
if isfield(params, 'seed'), set_seed(params.seed); end
X = rand(n, dim) .* (ub - lb) + lb;
fit = inf(n, 1);
for i = 1:n
    fit(i) = metah_eval_fitness(problem, params, X(i, :), 1, T);
end
curve = nan(1, T); history = struct();
for it = 1:T
    [sfit, ord] = sort(fit); X = X(ord, :); fit = sfit(:);
    bestSol = X(1, :); bestFit = fit(1);
    rain = X(1:nsr, :);
    for i = (nsr + 1):n
        stream = randi(nsr);
        X(i, :) = X(i, :) + rand(1, dim) .* (rain(stream, :) - X(i, :));
        X(i, :) = min(max(X(i, :), lb), ub);
        fit(i) = metah_eval_fitness(problem, params, X(i, :), it, T);
    end
    for i = 1:nsr
        X(i, :) = X(i, :) + 0.5 * randn(1, dim) .* (ub - lb) / T;
        X(i, :) = min(max(X(i, :), lb), ub);
        fit(i) = metah_eval_fitness(problem, params, X(i, :), it, T);
    end
    [bestFit, bidx] = min(fit);
    bestSol = X(bidx, :);
    curve(it) = bestFit;
end
end
