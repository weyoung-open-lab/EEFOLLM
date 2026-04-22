function [bestSol, bestFit, curve, history] = run_tsa(problem, params)
%RUN_TSA Tree Seed Algorithm (Kiran 2015), simplified.
dim = problem.dim; lb = problem.lb(:)'; ub = problem.ub(:)';
n = params.pop_size; T = params.max_iter; ST = max(3, round(0.2 * n));
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
    trees = X(1:ST, :);
    for i = (ST + 1):n
        parent = randi(ST);
        X(i, :) = trees(parent, :) + 0.5 * randn(1, dim) .* (ub - lb) ./ sqrt(it);
        X(i, :) = min(max(X(i, :), lb), ub);
        fit(i) = metah_eval_fitness(problem, params, X(i, :), it, T);
    end
    for i = 1:ST
        X(i, :) = bestSol + rand(1, dim) .* (trees(i, :) - bestSol);
        X(i, :) = min(max(X(i, :), lb), ub);
        fit(i) = metah_eval_fitness(problem, params, X(i, :), it, T);
    end
    [bestFit, bidx] = min(fit);
    bestSol = X(bidx, :);
    curve(it) = bestFit;
end
end
