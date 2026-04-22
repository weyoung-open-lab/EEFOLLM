function [bestSol, bestFit, curve, history] = run_mpa(problem, params)
%RUN_MPA Marine Predators Algorithm (Faramarzi et al. 2020), simplified.
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
    RB = (ub - lb) .* rand(1, dim) + lb;
    stepsize = 0.05 * exp(-(2 * it / T)^2);
    for i = 1:n
        if it < T / 3
            X(i, :) = RB + 0.5 * (rand(1, dim) .* (bestSol - RB));
        elseif it < 2 * T / 3
            j = randi(n);
            X(i, :) = bestSol + stepsize * (X(j, :) - X(i, :)) .* randn(1, dim);
        else
            X(i, :) = bestSol + stepsize * (rand(1, dim) .* (ub - lb));
        end
        X(i, :) = min(max(X(i, :), lb), ub);
        fit(i) = metah_eval_fitness(problem, params, X(i, :), it, T);
    end
    [bestFit, bidx] = min(fit);
    bestSol = X(bidx, :);
    curve(it) = bestFit;
end
end
