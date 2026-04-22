function [bestSol, bestFit, curve, history] = run_cs(problem, params)
%RUN_CS Cuckoo Search (Yang & Deb 2009), simplified with Levy flights.
dim = problem.dim; lb = problem.lb(:)'; ub = problem.ub(:)';
n = params.pop_size; T = params.max_iter; pa = 0.25;
if isfield(params, 'seed'), set_seed(params.seed); end
X = rand(n, dim) .* (ub - lb) + lb;
fit = inf(n, 1);
for i = 1:n
    fit(i) = metah_eval_fitness(problem, params, X(i, :), 1, T);
end
[bestFit, bidx] = min(fit); bestSol = X(bidx, :);
curve = nan(1, T); history = struct();
beta = 1.5;
sigma = (gamma(1 + beta) * sin(pi * beta / 2) / (gamma((1 + beta) / 2) * beta * 2^((beta - 1) / 2)))^(1 / beta);
for it = 1:T
    for i = 1:n
        u = randn(1, dim) * sigma;
        v = randn(1, dim);
        step = u ./ abs(v).^(1 / beta);
        xnew = X(i, :) + 0.01 * step .* (ub - lb);
        xnew = min(max(xnew, lb), ub);
        fnew = metah_eval_fitness(problem, params, xnew, it, T);
        if fnew < fit(i)
            X(i, :) = xnew;
            fit(i) = fnew;
        end
    end
    n_abandon = round(pa * n);
    [~, worst_idx] = sort(fit, 'descend');
    for k = 1:n_abandon
        j = worst_idx(k);
        X(j, :) = rand(1, dim) .* (ub - lb);
        fit(j) = metah_eval_fitness(problem, params, X(j, :), it, T);
    end
    [bestFit, bidx] = min(fit);
    bestSol = X(bidx, :);
    curve(it) = bestFit;
end
end
