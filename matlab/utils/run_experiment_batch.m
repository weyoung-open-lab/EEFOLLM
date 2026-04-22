function out = run_experiment_batch(cfg, map_list, algo_list, runs_per_map, opts)
%RUN_EXPERIMENT_BATCH Unified batch runner for fair experiments.
if nargin < 5, opts = struct(); end
if ~isfield(opts, 'k_waypoints'), opts.k_waypoints = cfg.path.default_k; end
if ~isfield(opts, 'max_iter'), opts.max_iter = cfg.exp.iterations; end
if ~isfield(opts, 'pop_size'), opts.pop_size = cfg.exp.population; end
if ~isfield(opts, 'log_file'), opts.log_file = fullfile(cfg.paths.logs, 'run.log'); end
if ~isfield(opts, 'stage_weights_map'), opts.stage_weights_map = struct(); end
if ~isfield(opts, 'static_weight_override'), opts.static_weight_override = []; end
if ~isfield(opts, 'static_weight_map'), opts.static_weight_map = struct(); end
if ~isfield(opts, 'save_history'), opts.save_history = false; end
if ~isfield(opts, 'verbose_console'), opts.verbose_console = false; end
% Optional: seed_algo_offset so batch runs match full-list seeds (global index = offset + ai).
if ~isfield(opts, 'seed_algo_offset'), opts.seed_algo_offset = 0; end
% Optional: seed_global_indices — length numel(algo_list), each entry = zoo30 global index (1..30); overrides seed_algo_offset.
if ~isfield(opts, 'seed_global_indices'), opts.seed_global_indices = []; end
% Optional: force_map_seed_index — scalar; when map_list has one map, seeds match that map index in cfg.maps.names.
% Optional: force_map_seed_indices — vector length numel(map_list); per-map index for seed formula (multi-map partial rerun).
if ~isfield(opts, 'force_map_seed_index'), opts.force_map_seed_index = []; end
if ~isfield(opts, 'force_map_seed_indices'), opts.force_map_seed_indices = []; end

records = [];
curve_store = struct();
best_path_store = struct();

if ~isempty(opts.seed_global_indices) && numel(opts.seed_global_indices) ~= numel(algo_list)
    error('run_experiment_batch:SeedIndices', ...
        'opts.seed_global_indices must have length %d (same as algo_list).', numel(algo_list));
end

for mi = 1:numel(map_list)
    map_data = map_list{mi};
    map_name = map_data.name;
    problem = build_problem(map_data, cfg, opts.k_waypoints);

    for ai = 1:numel(algo_list)
        algo = algo_list{ai};
        algo_func = get_algorithm_handle(algo);
        curve_mat = nan(runs_per_map, opts.max_iter);
        best_fit = inf;
        best_path = [];

        for r = 1:runs_per_map
            if ~isempty(opts.seed_global_indices)
                gidx = opts.seed_global_indices(ai);
            else
                gidx = opts.seed_algo_offset + ai;
            end
            if ~isempty(opts.force_map_seed_indices) && numel(opts.force_map_seed_indices) >= mi
                mi_seed = opts.force_map_seed_indices(mi);
            elseif ~isempty(opts.force_map_seed_index)
                mi_seed = opts.force_map_seed_index;
            else
                mi_seed = mi;
            end
            seed = cfg.base_seed + mi_seed * 1000 + gidx * 100 + r;
            params.pop_size = opts.pop_size;
            params.max_iter = opts.max_iter;
            params.seed = seed;
            params.cfg = cfg;
            params.weights = cfg.weights.default;
            params.save_history = opts.save_history;

            if isfield(opts.static_weight_map, map_name)
                params.weights = opts.static_weight_map.(map_name);
            elseif ~isempty(opts.static_weight_override)
                params.weights = opts.static_weight_override;
            end

            % Only LLM-SFO / EEFOLLM / EEFOLLM-PARETO use LLM (or default) stage weights; others use static params.weights.
            if strcmpi(algo, 'LLM-SFO') || strcmpi(algo, 'EEFOLLM') || strcmpi(algo, 'LLM-EEFO') ...
                    || strcmpi(algo, 'EEFOLLM-PARTIAL') || strcmpi(algo, 'EEFOLLM-NS') ...
                    || strcmpi(algo, 'EEFOLLM-NJ') ...
                    || strcmpi(algo, 'EEFOLLM-PARETO') || strcmpi(algo, 'LLM-EEFO-PARETO')
                if isfield(opts.stage_weights_map, map_name)
                    params.stage_weights = opts.stage_weights_map.(map_name);
                else
                    params.stage_weights = default_stage_weights(cfg);
                end
                params.use_stage_weights = true;
                if strcmpi(algo, 'EEFOLLM') || strcmpi(algo, 'LLM-EEFO') ...
                        || strcmpi(algo, 'EEFOLLM-PARTIAL') || strcmpi(algo, 'EEFOLLM-NS') ...
                        || strcmpi(algo, 'EEFOLLM-NJ')
                    params.use_online_adaptive_weights = isfield(cfg, 'online_adaptive') ...
                        && cfg.online_adaptive.enable;
                else
                    params.use_online_adaptive_weights = false;
                end
            else
                params.use_stage_weights = false;
                params.use_online_adaptive_weights = false;
            end

            log_message(opts.log_file, sprintf('Map=%s Algo=%s Run=%d/%d', map_name, algo, r, runs_per_map));
            if opts.verbose_console
                fprintf(1, '  [Opt] %s | %s | run %d/%d ... ', map_name, algo, r, runs_per_map);
                drawnow;
            end
            out_run = safe_call_algo(algo_func, problem, params);
            if opts.verbose_console
                fprintf(1, 'BestFit=%.4g sec=%.2f ok=%d\n', out_run.bestFit, out_run.runtime, out_run.success);
                drawnow;
            end
            curve_mat(r, :) = out_run.curve;

            rec.Map = string(map_name);
            rec.Algorithm = string(algo);
            rec.Run = r;
            rec.Seed = seed;
            rec.Runtime = out_run.runtime;
            rec.Success = out_run.success;
            rec.BestFit = out_run.bestFit;
            rec.Error = string(out_run.error);

            if out_run.success && ~isempty(out_run.bestSol)
                path_pts = decode_path(out_run.bestSol, map_data);
                m = evaluate_path_metrics(path_pts, map_data, cfg);
                rec.PathLength = m.path_length;
                rec.Smoothness = m.smoothness;
                rec.AvgTurningAngle = m.avg_turning_angle;
                rec.CollisionFree = m.collision_free;
                if out_run.bestFit < best_fit
                    best_fit = out_run.bestFit;
                    best_path = path_pts;
                end
            else
                rec.PathLength = nan;
                rec.Smoothness = nan;
                rec.AvgTurningAngle = nan;
                rec.CollisionFree = false;
            end
            records = [records; rec]; %#ok<AGROW>
        end

        curve_store.(map_name).(matlab.lang.makeValidName(algo)) = curve_mat;
        best_path_store.(map_name).(matlab.lang.makeValidName(algo)) = best_path;
    end
end

out.records = struct2table(records);
out.curves = curve_store;
out.best_paths = best_path_store;
end
