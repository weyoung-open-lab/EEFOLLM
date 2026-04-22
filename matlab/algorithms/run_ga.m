function [bestSol, bestFit, curve, history] = run_ga(problem, params)
%RUN_GA Real-coded GA (tournament + blend crossover + mutation).
dim = problem.dim; lb = problem.lb(:)'; ub = problem.ub(:)';
n = params.pop_size; T = params.max_iter; pc = 0.9; pm = 0.1;
if isfield(params, 'seed'), set_seed(params.seed); end
X = rand(n, dim) .* (ub - lb) + lb;
fit = inf(n, 1);
for i = 1:n
    fit(i) = metah_eval_fitness(problem, params, X(i, :), 1, T);
end
[bestFit, bidx] = min(fit); bestSol = X(bidx, :);
curve = nan(1, T); history = struct();
for it = 1:T
    newX = zeros(n, dim);
    for k = 1:2:n
        p1 = tournament(X, fit); p2 = tournament(X, fit);
        if rand < pc
            alpha = rand;
            c1 = alpha * p1 + (1 - alpha) * p2;
            c2 = alpha * p2 + (1 - alpha) * p1;
        else
            c1 = p1; c2 = p2;
        end
        for j = 1:dim
            if rand < pm
                c1(j) = lb(j) + rand * (ub(j) - lb(j));
            end
            if rand < pm
                c2(j) = lb(j) + rand * (ub(j) - lb(j));
            end
        end
        newX(k, :) = min(max(c1, lb), ub);
        if k + 1 <= n
            newX(k + 1, :) = min(max(c2, lb), ub);
        end
    end
    X = newX;
    for i = 1:n
        fit(i) = metah_eval_fitness(problem, params, X(i, :), it, T);
    end
    [bestFit, bidx] = min(fit);
    bestSol = X(bidx, :);
    curve(it) = bestFit;
end
end

function x = tournament(X, fit)
n = size(X, 1);
a = randi(n); b = randi(n);
if fit(a) < fit(b), x = X(a, :); else, x = X(b, :); end
end
