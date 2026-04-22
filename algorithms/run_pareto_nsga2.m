function [bestSol, bestFit, curve, history] = run_pareto_nsga2(problem, params)
%RUN_PARETO_NSGA2 NSGA-II multi-objective path planning: minimize (L, C, S, T) simultaneously.
%   Scalar reporting uses LLM stage weights (late-iteration blend) for bestSol selection (knee by min weighted sum on rank-1).
%
%   Params: pop_size, max_iter, cfg, stage_weights, use_stage_weights (true), seed.

dim = problem.dim; lb = problem.lb(:)'; ub = problem.ub(:)';
n = params.pop_size; T = params.max_iter; cfg = params.cfg;
if isfield(params, 'seed'), set_seed(params.seed); end

if ~isfield(params, 'use_stage_weights') || ~params.use_stage_weights
    error('run_pareto_nsga2:StageWeights', 'NSGA-II path mode requires use_stage_weights=true.');
end

if isfield(cfg, 'pareto') && isstruct(cfg.pareto)
    eta_c = getfield_with_default(cfg.pareto, 'eta_c', 15);
    eta_m = getfield_with_default(cfg.pareto, 'eta_m', 20);
    p_mut = getfield_with_default(cfg.pareto, 'p_mut', min(0.2, 1 / max(dim, 1)));
else
    eta_c = 15;
    eta_m = 20;
    p_mut = min(0.2, 1 / max(dim, 1));
end

w_dummy = struct('wL', 0.25, 'wC', 0.25, 'wS', 0.25, 'wT', 0.25);

X = rand(n, dim) .* (ub - lb) + lb;
curve = nan(1, T);
history = struct();
history.pareto_rank1_count = nan(1, T);

for it = 1:T
    Obj = eval_objectives(problem, X, cfg, w_dummy);
    curve(it) = min_weighted_scalar(problem, X, Obj, params, it, T, cfg);
    [rnk, crowd] = rank_and_crowding(Obj);
    history.pareto_rank1_count(it) = sum(rnk == 1);

    if it >= T
        break;
    end

    Q = zeros(n, dim);
    for j = 1:2:floor(n / 2) * 2
        p1 = tournament_select(rnk, crowd);
        p2 = tournament_select(rnk, crowd);
        [c1, c2] = sbx_crossover(X(p1, :), X(p2, :), lb, ub, eta_c);
        Q(j, :) = poly_mutate(c1, lb, ub, eta_m, p_mut);
        Q(j + 1, :) = poly_mutate(c2, lb, ub, eta_m, p_mut);
    end
    if mod(n, 2) == 1
        Q(n, :) = poly_mutate(X(tournament_select(rnk, crowd), :), lb, ub, eta_m, p_mut);
    end

    ObjQ = eval_objectives(problem, Q, cfg, w_dummy);
    Rpop = [X; Q];
    Robj = [Obj; ObjQ];
    X = select_nsga2(Rpop, Robj, n);
end

[bestSol, bestFit] = pick_best_scalar(problem, X, params, T, cfg);

    function Obj = eval_objectives(prob, Pop, cfg_, wgt)
        np = size(Pop, 1);
        Obj = zeros(np, 4);
        for ii = 1:np
            [~, parts] = prob.fitness_handle(Pop(ii, :), prob.map_data, wgt, cfg_);
            Obj(ii, :) = [parts.L, parts.C, parts.S, parts.T];
        end
    end

    function m = min_weighted_scalar(prob, Pop, Obj, params_, it_, T_, cfg_)
        m = inf;
        np = size(Pop, 1);
        for ii = 1:np
            wgt = select_stage_weights(params_.stage_weights, it_, T_, cfg_);
            m = min(m, scalarize(Obj(ii, :), wgt));
        end
    end

    function s = scalarize(v, wgt)
        s = wgt.wL * v(1) + wgt.wC * v(2) + wgt.wS * v(3) + wgt.wT * v(4);
    end

    function [bsol, bfit] = pick_best_scalar(prob, Pop, params_, T_, cfg_)
        Obj = eval_objectives(prob, Pop, cfg_, w_dummy);
        rnk = fast_non_dominated_sort(Obj);
        ix1 = find(rnk == 1);
        if isempty(ix1)
            ix1 = 1:size(Pop, 1);
        end
        it_ref = max(1, floor(0.85 * T_));
        wgt = select_stage_weights(params_.stage_weights, it_ref, T_, cfg_);
        best_i = ix1(1);
        best_s = inf;
        for ii = ix1(:)'
            s = scalarize(Obj(ii, :), wgt);
            if s < best_s
                best_s = s;
                best_i = ii;
            end
        end
        bsol = Pop(best_i, :);
        [bfit, ~] = prob.fitness_handle(bsol, prob.map_data, wgt, cfg_);
    end
end

function v = getfield_with_default(s, name, default)
if isfield(s, name), v = s.(name); else, v = default; end
end

function tf = dominates(a, b)
tf = all(a(:) <= b(:)) && any(a(:) < b(:));
end

function rank = fast_non_dominated_sort(obj)
n = size(obj, 1);
rank = zeros(n, 1);
unassigned = true(n, 1);
r = 1;
while any(unassigned)
    idx = find(unassigned);
    P = obj(idx, :);
    nidx = numel(idx);
    is_dom = false(nidx, 1);
    for i = 1:nidx
        for j = 1:nidx
            if i == j, continue; end
            if dominates(P(j, :), P(i, :))
                is_dom(i) = true;
                break;
            end
        end
    end
    front = idx(~is_dom);
    if isempty(front)
        rank(unassigned) = r;
        break;
    end
    rank(front) = r;
    unassigned(front) = false;
    r = r + 1;
end
end

function cd = crowding_distance(obj_f)
[nf, M] = size(obj_f);
cd = zeros(nf, 1);
if nf <= 2
    cd(:) = inf;
    return;
end
for m = 1:M
    [vals, order] = sort(obj_f(:, m));
    rge = max(vals) - min(vals);
    if rge < eps
        rge = 1;
    end
    cd(order(1)) = inf;
    cd(order(nf)) = inf;
    for k = 2:nf - 1
        cd(order(k)) = cd(order(k)) + (vals(k + 1) - vals(k - 1)) / rge;
    end
end
end

function [rnk, crowd] = rank_and_crowding(Robj)
rnk = fast_non_dominated_sort(Robj);
n = size(Robj, 1);
crowd = zeros(n, 1);
max_r = max(rnk);
for rr = 1:max_r
    ix = find(rnk == rr);
    crowd(ix) = crowding_distance(Robj(ix, :));
end
end

function P = select_nsga2(Rpop, Robj, n_sel)
[rnk, crowd] = rank_and_crowding(Robj);
keys = [rnk, -crowd];
[~, order] = sortrows(keys);
P = Rpop(order(1:n_sel), :);
end

function idx = tournament_select(rnk, crowd)
n = numel(rnk);
a = randi(n);
b = randi(n);
if rnk(a) < rnk(b)
    idx = a;
elseif rnk(b) < rnk(a)
    idx = b;
elseif crowd(a) > crowd(b)
    idx = a;
elseif crowd(b) > crowd(a)
    idx = b;
else
    idx = a;
end
end

function [c1, c2] = sbx_crossover(p1, p2, lb, ub, eta)
c1 = zeros(size(p1));
c2 = zeros(size(p2));
for j = 1:numel(p1)
    if rand > 0.5
        c1(j) = p1(j);
        c2(j) = p2(j);
        continue;
    end
    u = rand;
    if u <= 0.5
        beta = (2 * u) ^ (1 / (eta + 1));
    else
        beta = (1 / (2 * (1 - u))) ^ (1 / (eta + 1));
    end
    c1(j) = 0.5 * ((1 + beta) * p1(j) + (1 - beta) * p2(j));
    c2(j) = 0.5 * ((1 - beta) * p1(j) + (1 + beta) * p2(j));
    c1(j) = min(max(c1(j), lb(j)), ub(j));
    c2(j) = min(max(c2(j), lb(j)), ub(j));
end
end

function y = poly_mutate(x, lb, ub, eta_m, p)
y = x;
for j = 1:numel(x)
    if rand > p
        continue;
    end
    r = rand;
    yl = lb(j);
    yu = ub(j);
    delta1 = (x(j) - yl) / (yu - yl);
    delta2 = (yu - x(j)) / (yu - yl);
    mut_pow = 1 / (eta_m + 1);
    if r < 0.5
        xy = 1 - delta1;
        val = 2 * r + (1 - 2 * r) * xy ^ (eta_m + 1);
        deltaq = val ^ mut_pow - 1;
    else
        xy = 1 - delta2;
        val = 2 * (1 - r) + 2 * (r - 0.5) * xy ^ (eta_m + 1);
        deltaq = 1 - val ^ mut_pow;
    end
    y(j) = min(max(x(j) + deltaq * (yu - yl), yl), yu);
end
end
