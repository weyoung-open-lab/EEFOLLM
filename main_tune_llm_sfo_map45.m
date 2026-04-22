function main_tune_llm_sfo_map45()
%MAIN_TUNE_LLM_SFO_MAP45 Grid-search budgets so LLM-SFO can find feasible paths on Map4 & Map5.
%
% Step 1 of your pipeline: sweep population, iterations, waypoint count, and
% optional collision penalty scale; report settings where both maps achieve
% collision-free runs.
%
% Outputs: results/tune_map45_llmsfo_pass1.csv or tune_map45_llmsfo_pass2.csv, logs/tune_map45_llmsfo.log
% Interrupted before writetable? From project root: parse_tune_log_to_csv -> results/tune_map45_recovered_from_log.csv
%
% After you pick a row, copy pop/iter/k/penalty_scale into default_config.m
% (or set cfg manually) for unified experiments.

root_dir = fileparts(mfilename('fullpath'));
addpath(fullfile(root_dir, 'config'));
addpath(fullfile(root_dir, 'utils'));
cfg = default_config();
init_paths(cfg.paths.root);
ensure_dir(cfg.paths.results);
ensure_dir(cfg.paths.logs);

log_file = fullfile(cfg.paths.logs, 'tune_map45_llmsfo.log');
map_list_full = generate_maps(cfg);
target = {'Map4', 'Map5'};
map_list = {};
for i = 1:numel(map_list_full)
    if any(strcmp(target, map_list_full{i}.name))
        map_list{end+1} = map_list_full{i}; %#ok<AGROW>
    end
end
if numel(map_list) ~= 2
    error('Expected Map4 and Map5 in cfg.maps.names; found %d matching maps.', numel(map_list));
end

stage_weights_map = struct();
for i = 1:numel(map_list_full)
    mn = map_list_full{i}.name;
    feat = extract_map_features(map_list_full{i}, '');
    [sw, meta] = generate_llm_weights(feat, cfg, '');
    stage_weights_map.(mn) = sw;
    log_message(log_file, sprintf('LLM weights %s fallback=%d', mn, meta.used_fallback));
end

% --- search grids (edit here; each cell = runs_per_cell * 2 maps LLM-SFO runs on Map4+5) ---
% Pass 1 (coarse, 16 cells): pop [50,100] x iter [200,400] x k [7,9] x pen [1,2]
% Pass 2 (expanded budgets after no Map5 feasible in pass 1): larger pop, iter, K
use_pass1_grid = false;
if use_pass1_grid
    pop_grid = [50, 100];
    iter_grid = [200, 400];
    k_grid = [7, 9];
    penalty_scale_grid = [1, 2];
else
    pop_grid = [80, 120, 160];
    iter_grid = [600, 1000, 1400];
    k_grid = [11, 13];
    penalty_scale_grid = [1, 2];  % multiplies cfg.penalty.collision_hard only
end
% 3*3*2*2 = 36 cells (pass 2). ~216 LLM-SFO runs; expect roughly 1.5–3+ hours depending on CPU.
runs_per_cell = 3;  % increase to 5 for more stable feasible-rate estimates (much slower)

rows = [];
row_id = 0;
for pi = 1:numel(pop_grid)
    for ti = 1:numel(iter_grid)
        for ki = 1:numel(k_grid)
            for psi = 1:numel(penalty_scale_grid)
                row_id = row_id + 1;
                pop = pop_grid(pi);
                mx = iter_grid(ti);
                kw = k_grid(ki);
                ps = penalty_scale_grid(psi);

                cfg_t = cfg;
                cfg_t.penalty.collision_hard = cfg.penalty.collision_hard * ps;

                opts = struct();
                opts.pop_size = pop;
                opts.max_iter = mx;
                opts.k_waypoints = kw;
                opts.stage_weights_map = stage_weights_map;
                opts.log_file = log_file;
                opts.verbose_console = false;

                fprintf(1, '[tune %d] pop=%d iter=%d k=%d penalty_x=%.2f ...\n', row_id, pop, mx, kw, ps);
                drawnow;

                out = run_experiment_batch(cfg_t, map_list, {'LLM-SFO'}, runs_per_cell, opts);

                tbl = out.records;
                ok_map4 = all(tbl.CollisionFree(strcmp(tbl.Map, 'Map4')));
                ok_map5 = all(tbl.CollisionFree(strcmp(tbl.Map, 'Map5')));
                rate4 = mean(tbl.CollisionFree(strcmp(tbl.Map, 'Map4')));
                rate5 = mean(tbl.CollisionFree(strcmp(tbl.Map, 'Map5')));
                m4 = mean(tbl.BestFit(strcmp(tbl.Map, 'Map4')), 'omitnan');
                m5 = mean(tbl.BestFit(strcmp(tbl.Map, 'Map5')), 'omitnan');

                r = struct();
                r.id = row_id;
                r.pop = pop;
                r.iter = mx;
                r.k_waypoints = kw;
                r.penalty_scale = ps;
                r.map4_feasible_rate = rate4;
                r.map5_feasible_rate = rate5;
                r.both_maps_all_runs_ok = ok_map4 && ok_map5;
                r.mean_bestfit_map4 = m4;
                r.mean_bestfit_map5 = m5;
                rows = [rows; r]; %#ok<AGROW>

                log_message(log_file, sprintf( ...
                    'id=%d pop=%d iter=%d k=%d pen_x=%.2f rate4=%.2f rate5=%.2f strict_ok=%d', ...
                    row_id, pop, mx, kw, ps, rate4, rate5, r.both_maps_all_runs_ok));
            end
        end
    end
end

T = struct2table(rows);
if use_pass1_grid
    out_csv = 'tune_map45_llmsfo_pass1.csv';
else
    out_csv = 'tune_map45_llmsfo_pass2.csv';
end
writetable(T, fullfile(cfg.paths.results, out_csv));
fprintf(1, '=== Done. See results/%s (%d rows) ===\n', out_csv, height(T));
fprintf(1, 'Filter rows where both_maps_all_runs_ok==1 (or relax to high feasible rates).\n');
end
