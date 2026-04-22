function [bestSol, bestFit, curve, history] = run_gsa(problem, params)
%RUN_GSA Gravitational Search Algorithm (Rashedi et al. 2009), simplified.
dim = problem.dim; lb = problem.lb(:)'; ub = problem.ub(:)';
n = params.pop_size; T = params.max_iter; G0 = 100;
if isfield(params, 'seed'), set_seed(params.seed); end
X = rand(n, dim) .* (ub - lb) + lb;
V = zeros(n, dim);
fit = inf(n, 1);
for i = 1:n
    fit(i) = metah_eval_fitness(problem, params, X(i, :), 1, T);
end
[bestFit, bidx] = min(fit); bestSol = X(bidx, :);
curve = nan(1, T); history = struct();
for it = 1:T
    G = G0 * exp(-20 * it / T);
    worst = max(fit); best = min(fit);
    q = (worst - fit) ./ (worst - best + eps);
    M = q / sum(q + eps);
    for i = 1:n
        F = zeros(1, dim);
        for j = 1:n
            if i ~= j
                R = norm(X(i, :) - X(j, :)) + eps;
                F = F + rand(1, dim) .* G .* M(j) .* (X(j, :) - X(i, :)) ./ R;
            end
        end
        a = F ./ (M(i) + eps);
        V(i, :) = rand(1, dim) .* V(i, :) + a;
        X(i, :) = X(i, :) + V(i, :);
        X(i, :) = min(max(X(i, :), lb), ub);
        fit(i) = metah_eval_fitness(problem, params, X(i, :), it, T);
    end
    [bestFit, bidx] = min(fit);
    bestSol = X(bidx, :);
    curve(it) = bestFit;
end
end
