function [bestSol, bestFit, curve, history] = run_gto(problem, params)
%RUN_GTO Gaining-Sharing Knowledge (Mohamed et al. 2020), simplified continuous.
dim = problem.dim; lb = problem.lb(:)'; ub = problem.ub(:)';
n = params.pop_size; T = params.max_iter; k = 0.5;
if isfield(params, 'seed'), set_seed(params.seed); end
X = rand(n, dim) .* (ub - lb) + lb;
fit = inf(n, 1);
for i = 1:n
    fit(i) = metah_eval_fitness(problem, params, X(i, :), 1, T);
end
[bestFit, bidx] = min(fit); bestSol = X(bidx, :);
curve = nan(1, T); history = struct();
for it = 1:T
    [sfit, ord] = sort(fit); X = X(ord, :); fit = sfit(:);
    bestSol = X(1, :);
    for i = 1:n
        j = randi(n); m = randi(n);
        if rand < k
            X(i, :) = X(i, :) + rand(1, dim) .* (bestSol - X(j, :));
        else
            X(i, :) = X(i, :) - rand(1, dim) .* (X(m, :) - X(j, :));
        end
        X(i, :) = min(max(X(i, :), lb), ub);
        fit(i) = metah_eval_fitness(problem, params, X(i, :), it, T);
    end
    [bestFit, bidx] = min(fit);
    bestSol = X(bidx, :);
    curve(it) = bestFit;
end
end
