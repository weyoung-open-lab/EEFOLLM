function [bestSol, bestFit, curve, history] = run_abc(problem, params)
%RUN_ABC Artificial Bee Colony (Karaboga).
dim = problem.dim; lb = problem.lb(:)'; ub = problem.ub(:)';
n = params.pop_size; T = params.max_iter;
if isfield(params, 'seed'), set_seed(params.seed); end
limit = round(n * dim * 0.6);
trial = zeros(n, 1);
X = rand(n, dim) .* (ub - lb) + lb;
fit = inf(n, 1);
for i = 1:n
    fit(i) = metah_eval_fitness(problem, params, X(i, :), 1, T);
end
[bestFit, bidx] = min(fit); bestSol = X(bidx, :);
curve = nan(1, T); history = struct();
it = 0;
while it < T
    % employed
    for i = 1:n
        k = randi(n); while k == i, k = randi(n); end
        phi = 2 * rand(1, dim) - 1;
        v = X(i, :) + phi .* (X(i, :) - X(k, :));
        v = min(max(v, lb), ub);
        fv = metah_eval_fitness(problem, params, v, it + 1, T);
        if fv < fit(i)
            X(i, :) = v; fit(i) = fv; trial(i) = 0;
        else
            trial(i) = trial(i) + 1;
        end
    end
    invf = 1 ./ (1 + abs(fit));
    p = invf.' / sum(invf);
    % onlooker
    for j = 1:n
        i = roulette(p);
        k = randi(n); while k == i, k = randi(n); end
        phi = 2 * rand(1, dim) - 1;
        v = X(i, :) + phi .* (X(i, :) - X(k, :));
        v = min(max(v, lb), ub);
        fv = metah_eval_fitness(problem, params, v, it + 1, T);
        if fv < fit(i)
            X(i, :) = v; fit(i) = fv; trial(i) = 0;
        else
            trial(i) = trial(i) + 1;
        end
    end
    % scout
    [mx, worst] = max(trial);
    if mx > limit
        X(worst, :) = rand(1, dim) .* (ub - lb) + lb;
        fit(worst) = metah_eval_fitness(problem, params, X(worst, :), it + 1, T);
        trial(worst) = 0;
    end
    it = it + 1;
    [bestFit, bidx] = min(fit);
    bestSol = X(bidx, :);
    curve(it) = bestFit;
end
end

function idx = roulette(p)
r = rand; c = cumsum(p); idx = find(r <= c, 1);
end
