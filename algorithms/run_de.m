function [bestSol, bestFit, curve, history] = run_de(problem, params)
%RUN_DE Differential Evolution (DE/rand/1/bin).
dim = problem.dim; lb = problem.lb(:)'; ub = problem.ub(:)';
n = params.pop_size; T = params.max_iter;
if isfield(params, 'seed'), set_seed(params.seed); end
F = 0.5; CR = 0.9;
X = rand(n, dim) .* (ub - lb) + lb;
fit = inf(n, 1);
for i = 1:n
    fit(i) = metah_eval_fitness(problem, params, X(i, :), 1, T);
end
[bestFit, bidx] = min(fit); bestSol = X(bidx, :);
curve = nan(1, T); history = struct();
for it = 1:T
    for i = 1:n
        idx = randperm(n);
        idx(idx == i) = [];
        r = idx(1:3);
        v = X(r(1), :) + F * (X(r(2), :) - X(r(3), :));
        jrand = randi(dim);
        for j = 1:dim
            if rand >= CR && j ~= jrand
                v(j) = X(i, j);
            end
        end
        v = min(max(v, lb), ub);
        fv = metah_eval_fitness(problem, params, v, it, T);
        if fv < fit(i)
            X(i, :) = v;
            fit(i) = fv;
        end
    end
    [bestFit, bidx] = min(fit);
    bestSol = X(bidx, :);
    curve(it) = bestFit;
end
end
