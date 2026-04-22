function [bestSol, bestFit, curve, history] = run_sca(problem, params)
%RUN_SCA Sine Cosine Algorithm (Mirjalili 2016).
dim = problem.dim; lb = problem.lb(:)'; ub = problem.ub(:)';
n = params.pop_size; T = params.max_iter;
if isfield(params, 'seed'), set_seed(params.seed); end
X = rand(n, dim) .* (ub - lb) + lb;
fit = inf(n, 1);
for i = 1:n
    fit(i) = metah_eval_fitness(problem, params, X(i, :), 1, T);
end
[bestFit, bidx] = min(fit); bestSol = X(bidx, :);
curve = nan(1, T); history = struct();
for it = 1:T
    a = 2 - it * (2 / T);
    for i = 1:n
        r1 = a * rand(1, dim) - a;
        r2 = 2 * pi * rand(1, dim);
        r3 = 2 * rand(1, dim);
        X(i, :) = X(i, :) + r1 .* sin(r2) .* abs(r3 .* bestSol - X(i, :)) + ...
            r1 .* cos(r2) .* abs(r3 .* bestSol - X(i, :));
        X(i, :) = min(max(X(i, :), lb), ub);
        fit(i) = metah_eval_fitness(problem, params, X(i, :), it, T);
    end
    [bestFit, bidx] = min(fit);
    bestSol = X(bidx, :);
    curve(it) = bestFit;
end
end
