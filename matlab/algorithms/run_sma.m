function [bestSol, bestFit, curve, history] = run_sma(problem, params)
%RUN_SMA Slime Mould Algorithm (Li et al. 2020), simplified.
dim = problem.dim; lb = problem.lb(:)'; ub = problem.ub(:)';
n = params.pop_size; T = params.max_iter; z = 0.03;
if isfield(params, 'seed'), set_seed(params.seed); end
X = rand(n, dim) .* (ub - lb) + lb;
W = ones(n, 1);
fit = inf(n, 1);
for i = 1:n
    fit(i) = metah_eval_fitness(problem, params, X(i, :), 1, T);
end
[bestFit, bidx] = min(fit); bestSol = X(bidx, :);
curve = nan(1, T); history = struct();
for it = 1:T
    [sfit, ord] = sort(fit); worst = sfit(end);
    W = log10((worst - sfit + 1) / (worst - sfit(1) + 1) + 1);
    for i = 1:n
        vb = rand(1, dim); vc = rand(1, dim);
        A = randi(n); B = randi(n);
        if rand < 0.5
            X(i, :) = bestSol + vb .* (W(i) .* X(A, :) - X(B, :));
        else
            r = rand;
            X(i, :) = vc .* X(i, :) + (ub - lb) .* r .* (rand(1, dim) - 0.5);
        end
        X(i, :) = min(max(X(i, :), lb), ub);
        fit(i) = metah_eval_fitness(problem, params, X(i, :), it, T);
    end
    [bestFit, bidx] = min(fit);
    bestSol = X(bidx, :);
    curve(it) = bestFit;
end
end
