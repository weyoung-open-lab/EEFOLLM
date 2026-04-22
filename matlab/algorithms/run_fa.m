function [bestSol, bestFit, curve, history] = run_fa(problem, params)
%RUN_FA Firefly Algorithm (Yang 2009), simplified.
dim = problem.dim; lb = problem.lb(:)'; ub = problem.ub(:)';
n = params.pop_size; T = params.max_iter;
if isfield(params, 'seed'), set_seed(params.seed); end
alpha = 0.2; beta0 = 1; gamma = 1;
X = rand(n, dim) .* (ub - lb) + lb;
fit = inf(n, 1);
for i = 1:n
    fit(i) = metah_eval_fitness(problem, params, X(i, :), 1, T);
end
[bestFit, bidx] = min(fit); bestSol = X(bidx, :);
curve = nan(1, T); history = struct();
for it = 1:T
    alpha = alpha * 0.98;
    for i = 1:n
        for j = 1:n
            if fit(j) < fit(i)
                rij = norm(X(i, :) - X(j, :));
                beta = beta0 * exp(-gamma * rij^2);
                X(i, :) = X(i, :) + beta * (X(j, :) - X(i, :)) + alpha * (rand(1, dim) - 0.5);
            end
        end
        X(i, :) = min(max(X(i, :), lb), ub);
        fit(i) = metah_eval_fitness(problem, params, X(i, :), it, T);
    end
    [bestFit, bidx] = min(fit);
    bestSol = X(bidx, :);
    curve(it) = bestFit;
end
end
