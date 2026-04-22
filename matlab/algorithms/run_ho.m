function [bestSol, bestFit, curve, history] = run_ho(problem, params)
%RUN_HO Hippopotamus-inspired optimizer (paper-inspired simplified).
dim = problem.dim; lb = problem.lb(:)'; ub = problem.ub(:)';
n = params.pop_size; T = params.max_iter; cfg = params.cfg;
if isfield(params, 'seed'), set_seed(params.seed); end
X = rand(n, dim) .* (ub - lb) + lb;
fit = inf(n, 1);
curve = nan(1, T); history = struct();

for it = 1:T
    for i = 1:n, fit(i) = local_eval(X(i, :), it); end
    [bestFit, bi] = min(fit); bestSol = X(bi, :);
    meanX = mean(X, 1);
    for i = 1:n
        if rand < 0.5
            % River drifting/exploration.
            candidate = X(i, :) + randn(1, dim) .* (ub - lb) * 0.1;
        else
            % Defensive grouping/exploitation.
            candidate = X(i, :) + rand(1, dim) .* (bestSol - X(i, :)) + ...
                0.3 * rand(1, dim) .* (meanX - X(i, :));
        end
        candidate = min(max(candidate, lb), ub);
        f = local_eval(candidate, it);
        if f < fit(i), X(i, :) = candidate; fit(i) = f; end
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
