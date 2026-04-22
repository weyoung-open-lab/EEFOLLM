function [bestSol, bestFit, curve, history] = run_mfo(problem, params)
%RUN_MFO Moth-Flame Optimization (Mirjalili 2015), spiral update toward sorted flames.
dim = problem.dim; lb = problem.lb(:)'; ub = problem.ub(:)';
n = params.pop_size; T = params.max_iter;
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
    flame_no = max(2, round(n - it * ((n - 1) / T)));
    b = -1 + it * (-1 / T);
    for i = 1:n
        flame_idx = min(flame_no, max(1, round(i * flame_no / n)));
        for j = 1:dim
            D = abs(X(flame_idx, j) - X(i, j));
            t = (b - 1) * rand + 1;
            X(i, j) = D * exp(b * t) * cos(2 * pi * t) + X(flame_idx, j);
        end
        X(i, :) = min(max(X(i, :), lb), ub);
        fit(i) = metah_eval_fitness(problem, params, X(i, :), it, T);
    end
    [bestFit, bidx] = min(fit);
    bestSol = X(bidx, :);
    curve(it) = bestFit;
end
end
