function [bestSol, bestFit, curve, history] = run_woa(problem, params)
%RUN_WOA Whale Optimization Algorithm (Mirjalili & Lewis 2016).
dim = problem.dim; lb = problem.lb(:)'; ub = problem.ub(:)';
n = params.pop_size; T = params.max_iter;
if isfield(params, 'seed'), set_seed(params.seed); end
X = rand(n, dim) .* (ub - lb) + lb;
fit = inf(n, 1);
for i = 1:n
    fit(i) = metah_eval_fitness(problem, params, X(i, :), 1, T);
end
[bestFit, leader] = min(fit); bestSol = X(leader, :);
curve = nan(1, T); history = struct();
for it = 1:T
    a = 2 - it * (2 / T);
    a2 = -1 + it * (-1 / T);
    for i = 1:n
        A = 2 * a * rand - a;
        C = 2 * rand;
        b = 1;
        l = (a2 - 1) * rand + 1;
        p = rand;
        if p < 0.5
            if abs(A) < 1
                D = abs(C * bestSol - X(i, :));
                X(i, :) = bestSol - A * D;
            else
                rand_idx = randi(n);
                D = abs(C * X(rand_idx, :) - X(i, :));
                X(i, :) = X(rand_idx, :) - A * D;
            end
        else
            D = abs(bestSol - X(i, :));
            X(i, :) = D .* exp(b * l) .* cos(2 * pi * l) + bestSol;
        end
        X(i, :) = min(max(X(i, :), lb), ub);
        fit(i) = metah_eval_fitness(problem, params, X(i, :), it, T);
    end
    [bestFit, leader] = min(fit);
    bestSol = X(leader, :);
    curve(it) = bestFit;
end
end
