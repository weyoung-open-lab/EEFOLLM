function [bestSol, bestFit, curve, history] = run_eefo(problem, params)
%RUN_EEFO Electric eel foraging optimizer (paper-inspired simplified).
%   Optional params.eefo_variant (default 'full'):
%     'full'       — shock + guide + random re-init (prob 0.25), see below
%     'no_shock'   — disable Gaussian shock (keep guide + re-init)
%     'no_jump'    — disable random re-init (keep shock + guide)
%     'guide_only' — only guide toward global best (ablated / minimal EEFO)
dim = problem.dim; lb = problem.lb(:)'; ub = problem.ub(:)';
n = params.pop_size; T = params.max_iter; cfg = params.cfg;
if isfield(params, 'seed'), set_seed(params.seed); end
if isfield(params, 'eefo_variant') && ~isempty(params.eefo_variant)
    variant = lower(strtrim(params.eefo_variant));
else
    variant = 'full';
end
switch variant
    case 'full'
        use_shock = true; jump_prob = 0.25;
    case 'no_shock'
        use_shock = false; jump_prob = 0.25;
    case 'no_jump'
        use_shock = true; jump_prob = 0;
    case 'guide_only'
        use_shock = false; jump_prob = 0;
    otherwise
        warning('run_eefo:UnknownVariant', 'Unknown eefo_variant ''%s'', using full.', variant);
        use_shock = true; jump_prob = 0.25;
end

X = rand(n, dim) .* (ub - lb) + lb;
fit = inf(n, 1);
curve = nan(1, T); history = struct();

use_oaw = isfield(params, 'use_online_adaptive_weights') && params.use_online_adaptive_weights ...
    && isfield(params, 'use_stage_weights') && params.use_stage_weights ...
    && isfield(cfg, 'online_adaptive') && cfg.online_adaptive.enable;

for it = 1:T
    Cpop = zeros(n, 1);
    for i = 1:n
        if use_oaw
            [fit(i), parts] = local_eval(X(i, :), it);
            Cpop(i) = parts.C;
        else
            fit(i) = local_eval(X(i, :), it);
        end
    end
    if use_oaw && mod(it, cfg.online_adaptive.every) == 0
        params = adapt_stage_weights_online(params, Cpop, cfg);
    end
    [bestFit, bi] = min(fit); bestSol = X(bi, :);
    temp = 1 - it / T;
    shock_scale = 0.08;
    for i = 1:n
        if use_shock
            shock = randn(1, dim) .* temp .* (ub - lb) * shock_scale;
        else
            shock = zeros(1, dim);
        end
        guide = rand(1, dim) .* (bestSol - X(i, :));
        candidate = X(i, :) + guide + shock;
        if rand < jump_prob
            candidate = rand(1, dim) .* (ub - lb) + lb;
        end
        candidate = min(max(candidate, lb), ub);
        f = local_eval(candidate, it);
        if f < fit(i), X(i, :) = candidate; fit(i) = f; end
    end
    curve(it) = bestFit;
end

    function varargout = local_eval(x, iter)
        if isfield(params, 'use_stage_weights') && params.use_stage_weights
            wgt = select_stage_weights(params.stage_weights, iter, T, params.cfg);
        else
            wgt = params.weights;
        end
        if nargout >= 2
            [f, parts] = problem.fitness_handle(x, problem.map_data, wgt, cfg);
            varargout{1} = f;
            varargout{2} = parts;
        else
            [f, ~] = problem.fitness_handle(x, problem.map_data, wgt, cfg);
            varargout{1} = f;
        end
    end
end
