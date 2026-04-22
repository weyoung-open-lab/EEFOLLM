function [bestSol, bestFit, curve, history] = run_pso(problem, params)
%RUN_PSO Standard PSO for continuous waypoint optimization.
dim = problem.dim; lb = problem.lb(:)'; ub = problem.ub(:)';
n = params.pop_size; T = params.max_iter; cfg = params.cfg;
if isfield(params, 'seed'), set_seed(params.seed); end

X = rand(n, dim) .* (ub - lb) + lb;
V = zeros(n, dim);
pbest = X;
fit = inf(n, 1);
for i = 1:n
    fit(i) = local_eval(X(i, :), 1);
end
pfit = fit;
[bestFit, idx] = min(fit); bestSol = X(idx, :);
curve = nan(1, T); history = struct();
wmax = 0.9; wmin = 0.4; c1 = 1.8; c2 = 1.8;

for it = 1:T
    w = wmax - (wmax - wmin) * (it / T);
    for i = 1:n
        V(i, :) = w * V(i, :) + c1 * rand(1, dim) .* (pbest(i, :) - X(i, :)) + ...
            c2 * rand(1, dim) .* (bestSol - X(i, :));
        X(i, :) = min(max(X(i, :) + V(i, :), lb), ub);
        f = local_eval(X(i, :), it);
        if f < pfit(i), pfit(i) = f; pbest(i, :) = X(i, :); end
        if f < bestFit, bestFit = f; bestSol = X(i, :); end
    end
    curve(it) = bestFit;
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
