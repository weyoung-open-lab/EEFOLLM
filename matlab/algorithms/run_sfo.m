function [bestSol, bestFit, curve, history] = run_sfo(problem, params)
%RUN_SFO Paper-inspired Sharpbelly Fish Optimization.
%   Includes four behaviors:
%   1) fast swimming
%   2) gathering
%   3) dispersal
%   4) escape

dim = problem.dim;
lb = problem.lb(:)';
ub = problem.ub(:)';
pop_size = params.pop_size;
max_iter = params.max_iter;
cfg = params.cfg;

if isfield(params, 'seed')
    set_seed(params.seed);
end

X = rand(pop_size, dim) .* (ub - lb) + lb;
fit = inf(pop_size, 1);
for i = 1:pop_size
    fit(i) = eval_candidate(X(i, :), 1);
end
[bestFit, best_idx] = min(fit);
bestSol = X(best_idx, :);

curve = nan(1, max_iter);
if isfield(params, 'save_history') && params.save_history
    history.population = cell(1, max_iter);
    history.fitness = cell(1, max_iter);
else
    history = struct();
end

for it = 1:max_iter
    [~, worst_idx] = max(fit);
    worstSol = X(worst_idx, :);
    meanSol = mean(X, 1);

    for i = 1:pop_size
        r = rand;
        xi = X(i, :);
        if r < cfg.sfo.p_fast
            % Fast swimming: rapid global move toward current best.
            v = rand(1, dim) .* (bestSol - xi);
            candidate = xi + 1.2 * v + 0.05 * randn(1, dim) .* (ub - lb);
        elseif r < cfg.sfo.p_fast + cfg.sfo.p_gather
            % Gathering: cluster around group center and leader.
            idx = randperm(pop_size, max(3, floor(pop_size / 5)));
            local_center = mean(X(idx, :), 1);
            candidate = xi + rand(1, dim) .* (local_center - xi) + ...
                0.5 * rand(1, dim) .* (bestSol - xi);
        elseif r < cfg.sfo.p_fast + cfg.sfo.p_gather + cfg.sfo.p_disp
            % Dispersal: random exploratory step to maintain diversity.
            step = (2 * rand(1, dim) - 1) .* 0.25 .* (ub - lb);
            candidate = xi + step + 0.2 * rand(1, dim) .* (xi - meanSol);
        else
            % Escape: move away from bad region (worst individual).
            candidate = xi + rand(1, dim) .* (xi - worstSol) + ...
                0.4 * randn(1, dim) .* (ub - lb) .* (1 - it / max_iter);
            if rand < cfg.sfo.escape_prob
                candidate = rand(1, dim) .* (ub - lb) + lb;
            end
        end

        candidate = min(max(candidate, lb), ub);
        f_new = eval_candidate(candidate, it);
        if f_new < fit(i)
            X(i, :) = candidate;
            fit(i) = f_new;
            if f_new < bestFit
                bestFit = f_new;
                bestSol = candidate;
            end
        end
    end

    curve(it) = bestFit;
    if isfield(history, 'population')
        history.population{it} = X;
        history.fitness{it} = fit;
    end
end

    function f = eval_candidate(x, iter)
        if isfield(params, 'use_stage_weights') && params.use_stage_weights
            w = select_stage_weights(params.stage_weights, iter, max_iter, params.cfg);
        else
            w = params.weights;
        end
        [f, ~] = problem.fitness_handle(x, problem.map_data, w, cfg);
    end
end
