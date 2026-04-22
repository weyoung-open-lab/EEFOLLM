function [bestSol, bestFit, curve, history] = run_hho(problem, params)
%RUN_HHO Harris Hawks Optimization (Heidari et al. 2019), simplified.
dim = problem.dim; lb = problem.lb(:)'; ub = problem.ub(:)';
n = params.pop_size; T = params.max_iter;
if isfield(params, 'seed'), set_seed(params.seed); end
X = rand(n, dim) .* (ub - lb) + lb;
fit = inf(n, 1);
for i = 1:n
    fit(i) = metah_eval_fitness(problem, params, X(i, :), 1, T);
end
[bestFit, bidx] = min(fit); bestSol = X(bidx, :); rabbit = bestSol;
curve = nan(1, T); history = struct();
for it = 1:T
    E0 = 2 * rand - 1; E = 2 * E0 * (1 - it / T);
    for i = 1:n
        q = rand;
        if abs(E) >= 1
            rand_idx = randi(n);
            X(i, :) = rabbit - rand(1, dim) .* abs(rabbit - 2 * rand * X(rand_idx, :));
        elseif q >= 0.5
            LF = 0.01 * (ub - lb) .* (rand(1, dim) - 0.5);
            X(i, :) = rabbit - E .* abs(rabbit - X(i, :)) + LF .* randn(1, dim);
        else
            J = 2 * (1 - rand);
            X(i, :) = rabbit - E .* abs(J * rabbit - X(i, :));
        end
        X(i, :) = min(max(X(i, :), lb), ub);
        fit(i) = metah_eval_fitness(problem, params, X(i, :), it, T);
    end
    [bestFit, bidx] = min(fit);
    bestSol = X(bidx, :); rabbit = bestSol;
    curve(it) = bestFit;
end
end
