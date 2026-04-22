function [bestSol, bestFit, curve, history] = run_aoa(problem, params)
%RUN_AOA Arithmetic Optimization Algorithm (Abualigah et al. 2021), simplified.
dim = problem.dim; lb = problem.lb(:)'; ub = problem.ub(:)';
n = params.pop_size; T = params.max_iter; MOPmax = 1; MOPmin = 0.2;
if isfield(params, 'seed'), set_seed(params.seed); end
X = rand(n, dim) .* (ub - lb) + lb;
fit = inf(n, 1);
for i = 1:n
    fit(i) = metah_eval_fitness(problem, params, X(i, :), 1, T);
end
[bestFit, bidx] = min(fit); bestSol = X(bidx, :);
curve = nan(1, T); history = struct();
for it = 1:T
    MOP = 1 - ((it / T) ^ (1 / 2));
    MOA = MOPmin + it * ((MOPmax - MOPmin) / T);
    for i = 1:n
        for j = 1:dim
            if rand < MOA
                if rand < 0.5
                    X(i, j) = bestSol(j) / (MOP + eps) * ((ub(j) - lb(j)) * MOA + lb(j));
                else
                    X(i, j) = bestSol(j) * MOP * ((ub(j) - lb(j)) * rand + lb(j));
                end
            else
                if rand < 0.5
                    X(i, j) = bestSol(j) - MOP * ((ub(j) - lb(j)) * rand + lb(j));
                else
                    X(i, j) = bestSol(j) + MOP * ((ub(j) - lb(j)) * rand + lb(j));
                end
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
