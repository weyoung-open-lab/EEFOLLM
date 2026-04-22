function [bestSol, bestFit, curve, history] = run_tlbo(problem, params)
%RUN_TLBO Teaching-Learning-Based Optimization (Rao et al.).
dim = problem.dim; lb = problem.lb(:)'; ub = problem.ub(:)';
n = params.pop_size; T = params.max_iter;
if isfield(params, 'seed'), set_seed(params.seed); end
X = rand(n, dim) .* (ub - lb) + lb;
fit = inf(n, 1);
for i = 1:n
    fit(i) = metah_eval_fitness(problem, params, X(i, :), 1, T);
end
curve = nan(1, T); history = struct();
for it = 1:T
    [sfit, ord] = sort(fit); X = X(ord, :); fit = sfit(:);
    teacher = X(1, :);
    meanX = mean(X, 1);
    Tf = round(1 + rand);
    for i = 1:n
        Xnew = X(i, :) + rand(1, dim) .* (teacher - Tf * meanX);
        Xnew = min(max(Xnew, lb), ub);
        fnew = metah_eval_fitness(problem, params, Xnew, it, T);
        if fnew < fit(i)
            X(i, :) = Xnew;
            fit(i) = fnew;
        end
    end
    [sfit, ord] = sort(fit); X = X(ord, :); fit = sfit(:);
    for i = 1:n
        j = randi(n); while j == i, j = randi(n); end
        if fit(i) < fit(j)
            Xnew = X(i, :) + rand(1, dim) .* (X(i, :) - X(j, :));
        else
            Xnew = X(i, :) + rand(1, dim) .* (X(j, :) - X(i, :));
        end
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
