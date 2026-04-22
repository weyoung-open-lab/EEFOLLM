function [bestSol, bestFit, curve, history] = run_eo(problem, params)
%RUN_EO Equilibrium Optimizer (Faramarzi et al. 2020), simplified pool update.
dim = problem.dim; lb = problem.lb(:)'; ub = problem.ub(:)';
n = params.pop_size; T = params.max_iter;
if isfield(params, 'seed'), set_seed(params.seed); end
Ceq = zeros(4, dim); % pool of 4
for k = 1:4
    Ceq(k, :) = lb + rand(1, dim) .* (ub - lb);
end
X = rand(n, dim) .* (ub - lb) + lb;
fit = inf(n, 1);
for i = 1:n
    fit(i) = metah_eval_fitness(problem, params, X(i, :), 1, T);
end
[bestFit, bidx] = min(fit); bestSol = X(bidx, :);
Ceq(1, :) = bestSol;
curve = nan(1, T); history = struct();
for it = 1:T
    T_iter = exp(-it / T);
    for i = 1:n
        lambda = rand(1, dim); F = rand(1, dim);
        r1 = randi(4); r2 = randi(4);
        C = Ceq(r1, :) + (Ceq(r1, :) - Ceq(r2, :)) .* lambda;
        CP = 0.5 * rand * (C - X(i, :));
        G = CP .* (F .* bestSol - X(i, :)) + T_iter * randn(1, dim) .* (ub - lb) / T;
        X(i, :) = C + G;
        X(i, :) = min(max(X(i, :), lb), ub);
        fit(i) = metah_eval_fitness(problem, params, X(i, :), it, T);
    end
    [sfit, ord] = sort(fit); X = X(ord, :); fit = sfit(:);
    bestSol = X(1, :); bestFit = fit(1);
    Ceq(1, :) = bestSol;
    curve(it) = bestFit;
end
end
