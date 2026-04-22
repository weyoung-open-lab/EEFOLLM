function [bestSol, bestFit, curve, history] = run_ssa(problem, params)
%RUN_SSA Sparrow Search Algorithm (Xue et al. 2020), compact form.
dim = problem.dim; lb = problem.lb(:)'; ub = problem.ub(:)';
n = params.pop_size; T = params.max_iter;
if isfield(params, 'seed'), set_seed(params.seed); end
PD = 0.2; ST = 0.8; SD = 0.2;
X = rand(n, dim) .* (ub - lb) + lb;
fit = inf(n, 1);
for i = 1:n
    fit(i) = metah_eval_fitness(problem, params, X(i, :), 1, T);
end
[sfit, ord] = sort(fit);
X = X(ord, :); fit = sfit(:);
bestSol = X(1, :); bestFit = fit(1);
curve = nan(1, T); history = struct();
Ns = max(2, floor(0.2 * n));
for it = 1:T
    [sfit, ord] = sort(fit); X = X(ord, :); fit = sfit(:);
    bestSol = X(1, :); bestFit = fit(1);
    worst = X(end, :); fw = fit(end);
    for i = 1:Ns
        if rand > ST
            X(i, :) = X(i, :) .* exp(-(i) ./ (rand * T));
        else
            X(i, :) = bestSol + abs(randn(1, dim)) .* X(i, :);
        end
        X(i, :) = min(max(X(i, :), lb), ub);
        fit(i) = metah_eval_fitness(problem, params, X(i, :), it, T);
    end
    for i = (Ns + 1):n
        if i > n / 2
            X(i, :) = randn(1, dim) .* exp((worst - X(i, :)) ./ (i^2));
        else
            A = ones(1, dim); Ap = randi([0 1], 1, dim) * 2 - 1;
            L = ones(1, dim);
            X(i, :) = bestSol + abs(mean(X(Ns + 1:n, :)) - worst) .* Ap .* L;
        end
        X(i, :) = min(max(X(i, :), lb), ub);
        fit(i) = metah_eval_fitness(problem, params, X(i, :), it, T);
    end
    ridx = randi([1, Ns]);
    if rand < PD
        K = abs(fit(ridx) - fw) + eps;
        X(ridx, :) = bestSol + randn(1, dim) .* sqrt(abs(X(ridx, :) - worst)) ./ K;
        X(ridx, :) = min(max(X(ridx, :), lb), ub);
        fit(ridx) = metah_eval_fitness(problem, params, X(ridx, :), it, T);
    end
    [bestFit, bi] = min(fit);
    bestSol = X(bi, :);
    curve(it) = bestFit;
end
end
