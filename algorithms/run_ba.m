function [bestSol, bestFit, curve, history] = run_ba(problem, params)
%RUN_BA Bat Algorithm (Yang 2010), simplified.
dim = problem.dim; lb = problem.lb(:)'; ub = problem.ub(:)';
n = params.pop_size; T = params.max_iter;
if isfield(params, 'seed'), set_seed(params.seed); end
Qmin = 0; Qmax = 2; r0 = 0.5; A0 = 0.5;
Q = zeros(n, 1); v = zeros(n, dim); X = rand(n, dim) .* (ub - lb) + lb;
fit = inf(n, 1);
for i = 1:n
    fit(i) = metah_eval_fitness(problem, params, X(i, :), 1, T);
end
[bestFit, bidx] = min(fit); bestSol = X(bidx, :);
curve = nan(1, T); history = struct();
for it = 1:T
    loud = A0 * (1 - it / T);
    pulse = r0 * (1 - exp(-it));
    for i = 1:n
        Q(i) = Qmin + (Qmax - Qmin) * rand;
        v(i, :) = v(i, :) + (X(i, :) - bestSol) * Q(i);
        xnew = X(i, :) + v(i, :);
        if rand > pulse
            xnew = bestSol + 0.01 * randn(1, dim) .* (ub - lb);
        end
        xnew = min(max(xnew, lb), ub);
        fnew = metah_eval_fitness(problem, params, xnew, it, T);
        if fnew <= fit(i) || rand < loud
            X(i, :) = xnew;
            fit(i) = fnew;
        end
    end
    [bestFit, bidx] = min(fit);
    bestSol = X(bidx, :);
    curve(it) = bestFit;
end
end
