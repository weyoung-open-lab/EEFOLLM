function [bestSol, bestFit, curve, history] = run_gwo(problem, params)
%RUN_GWO Grey Wolf Optimizer (paper-inspired standard form).
dim = problem.dim; lb = problem.lb(:)'; ub = problem.ub(:)';
n = params.pop_size; T = params.max_iter; cfg = params.cfg;
if isfield(params, 'seed'), set_seed(params.seed); end
X = rand(n, dim) .* (ub - lb) + lb;
fit = inf(n, 1);
curve = nan(1, T); history = struct();

for it = 1:T
    for i = 1:n
        fit(i) = local_eval(X(i, :), it);
    end
    [sfit, sidx] = sort(fit, 'ascend');
    alpha = X(sidx(1), :); beta = X(sidx(2), :); delta = X(sidx(3), :);
    bestSol = alpha; bestFit = sfit(1);
    a = 2 - 2 * (it / T);
    for i = 1:n
        X1 = local_update(alpha, X(i, :), a);
        X2 = local_update(beta, X(i, :), a);
        X3 = local_update(delta, X(i, :), a);
        X(i, :) = min(max((X1 + X2 + X3) / 3, lb), ub);
    end
    curve(it) = bestFit;
end

    function Xn = local_update(leader, x, a)
        A = 2 * a * rand(1, dim) - a;
        C = 2 * rand(1, dim);
        D = abs(C .* leader - x);
        Xn = leader - A .* D;
    end
    function f = local_eval(x, iter)
        if isfield(params, 'use_stage_weights') && params.use_stage_weights
            wgt = select_stage_weights(params.stage_weights, iter, T, params.cfg);
        else
            wgt = params.weights;
        end
        [f, ~] = problem.fitness_handle(x, problem.map_data, wgt, cfg);
    end
end
