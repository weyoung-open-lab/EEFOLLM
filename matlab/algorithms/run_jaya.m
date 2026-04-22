function [bestSol, bestFit, curve, history] = run_jaya(problem, params)
%RUN_JAYA Jaya algorithm (Rao 2016).
dim = problem.dim; lb = problem.lb(:)'; ub = problem.ub(:)';
n = params.pop_size; T = params.max_iter;
if isfield(params, 'seed'), set_seed(params.seed); end
X = rand(n, dim) .* (ub - lb) + lb;
fit = inf(n, 1);
for i = 1:n
    fit(i) = metah_eval_fitness(problem, params, X(i, :), 1, T);
end
[bestFit, bidx] = min(fit); bestSol = X(bidx, :);
curve = nan(1, T); history = struct();
for it = 1:T
    worst_idx = find(fit == max(fit), 1);
    for i = 1:n
        r1 = randi(n); r2 = randi(n);
        Xnew = X(i, :) + rand(1, dim) .* (bestSol - abs(X(i, :))) - ...
            rand(1, dim) .* (X(worst_idx, :) - abs(X(i, :)));
        Xnew = min(max(Xnew, lb), ub);
        fnew = metah_eval_fitness(problem, params, Xnew, it, T);
        if fnew < fit(i)
            X(i, :) = Xnew;
            fit(i) = fnew;
        end
    end
    [bestFit, bidx] = min(fit);
    bestSol = X(bidx, :);
    curve(it) = bestFit;
end
end
