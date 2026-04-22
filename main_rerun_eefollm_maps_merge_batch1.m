function main_rerun_eefollm_maps_merge_batch1(map_names, regen_figures)
%MAIN_RERUN_EEFOLLM_MAPS_MERGE_BATCH1  EEFOLLM on selected maps only, batch1 weights JSON, merge into batch1 results.
%
%   map_names: cellstr, e.g. {'Map2'} or {'Map1','Map2'} (order follows generate_maps / cfg.maps.names).
%   Uses cfg.exp.runs_per_map and batch-1 opts.seed_algo_offset=0.
%   When exactly one map is rerun, opts.force_map_seed_index is set so seeds match the full 5-map run.
%
%   Examples:
%     main_rerun_eefollm_maps_merge_batch1({'Map2'})           % only Map2, corrected weights
%     main_rerun_eefollm_maps_merge_batch1({'Map1','Map2'})  % same as main_rerun_eefollm_map12_merge_batch1
%
%   See also: main_rerun_eefollm_map12_merge_batch1

if nargin < 1 || isempty(map_names)
    map_names = {'Map1', 'Map2'};
end
if nargin < 2 || isempty(regen_figures)
    regen_figures = true;
end

root_dir = fileparts(mfilename('fullpath'));
addpath(fullfile(root_dir, 'config'));
addpath(fullfile(root_dir, 'utils'));

cfg = default_config();
init_paths(cfg.paths.root);
ensure_dir(cfg.paths.results);
ensure_dir(cfg.paths.logs);

suffix = 'batch1';
base_res = fullfile(cfg.paths.results, ['global_experiments_', suffix]);
base_fig = fullfile(cfg.paths.figures, ['global_experiments_', suffix]);
mat_dir = fullfile(base_res, 'mat');
tbl_dir = fullfile(base_res, 'tables');
wgt_dir = fullfile(base_res, 'weights');
result_mat = fullfile(mat_dir, 'global_results.mat');
safe = matlab.lang.makeValidName(strjoin(cellfun(@char, map_names, 'UniformOutput', false), '_'));
log_file = fullfile(cfg.paths.logs, ['rerun_eefollm_', safe, '_batch1.log']);

if ~isfile(result_mat)
    error('Missing %s — run main_run_global_experiments_batch(1) once before merging.', result_mat);
end

map_list_full = generate_maps(cfg);
maps_subset = {};
for i = 1:numel(map_list_full)
    if any(strcmp(map_names, map_list_full{i}.name))
        maps_subset{end+1} = map_list_full{i}; %#ok<AGROW>
    end
end
if numel(maps_subset) ~= numel(map_names)
    error('Could not resolve all requested map names (got %d maps).', numel(maps_subset));
end

stage_weights_map = struct();
for i = 1:numel(maps_subset)
    mname = maps_subset{i}.name;
    fjson = fullfile(wgt_dir, ['weights_', mname, '.json']);
    if ~isfile(fjson)
        error('Missing %s', fjson);
    end
    raw = load_json(fjson);
    [okw, sw, msg] = validate_weights_struct(raw, cfg);
    if ~okw
        error('Invalid weights for %s: %s', mname, msg);
    end
    stage_weights_map.(mname) = sw;
end

fprintf(1, '=== Rerun EEFOLLM %s | runs_per_map=%d | merge -> %s ===\n', ...
    strjoin(map_names, ', '), cfg.exp.runs_per_map, base_res);
log_message(log_file, sprintf('Start EEFOLLM rerun maps=%s runs_per_map=%d', strjoin(map_names, ', '), cfg.exp.runs_per_map));

opts = struct();
opts.stage_weights_map = stage_weights_map;
opts.log_file = log_file;
opts.verbose_console = true;
opts.seed_algo_offset = 0;
opts.force_map_seed_indices = [];
opts.force_map_seed_index = [];
if numel(maps_subset) == 1
    opts.force_map_seed_index = find(strcmp(cfg.maps.names, maps_subset{1}.name), 1);
    if isempty(opts.force_map_seed_index)
        error('Map name not in cfg.maps.names: %s', maps_subset{1}.name);
    end
else
    opts.force_map_seed_indices = zeros(1, numel(maps_subset));
    for ii = 1:numel(maps_subset)
        ix = find(strcmp(cfg.maps.names, maps_subset{ii}.name), 1);
        if isempty(ix)
            error('Map name not in cfg.maps.names: %s', maps_subset{ii}.name);
        end
        opts.force_map_seed_indices(ii) = ix;
    end
end

out_new = run_experiment_batch(cfg, maps_subset, {'EEFOLLM'}, cfg.exp.runs_per_map, opts);

S = load(result_mat);
if ~isfield(S, 'out')
    error('global_results.mat has no variable out.');
end
out_old = S.out;
rt = out_old.records;
mn = string(rt.Map);
al = string(rt.Algorithm);
targets = string(map_names(:))';
rm = (al == "EEFOLLM") & ismember(mn, targets);
out = out_old;
out.records = [rt(~rm, :); out_new.records];
out.records = sortrows(out.records, {'Map', 'Algorithm', 'Run'});

nm = 'EEFOLLM';
vn = matlab.lang.makeValidName(nm);
for i = 1:numel(maps_subset)
    mname = maps_subset{i}.name;
    out.curves.(mname).(vn) = out_new.curves.(mname).(vn);
    out.best_paths.(mname).(vn) = out_new.best_paths.(mname).(vn);
end

summary_tbl = compute_statistics(out.records);
rank_tbl = friedman_rank(out.records);

if isfield(S, 'cfg')
    cfg = S.cfg;
end
if isfield(S, 'algo_list')
    algo_list = S.algo_list;
else
    algo_list = cfg.exp.algorithms_zoo30(1:10);
end
if isfield(S, 'map_list')
    map_list = S.map_list;
else
    map_list = generate_maps(cfg);
end
if isfield(S, 'batch_idx')
    batch_idx = S.batch_idx;
else
    batch_idx = 1;
end
if isfield(S, 'seed_offset')
    seed_offset = S.seed_offset;
else
    seed_offset = 0;
end

save(result_mat, 'out', 'summary_tbl', 'rank_tbl', 'cfg', 'algo_list', 'map_list', 'batch_idx', 'seed_offset', '-v7.3');

writetable(out.records, fullfile(tbl_dir, 'records.csv'));
writetable(summary_tbl, fullfile(tbl_dir, 'summary.csv'));
writetable(rank_tbl, fullfile(tbl_dir, 'friedman_rank.csv'));

g = findgroups(out.records.Algorithm);
Algorithm = splitapply(@(x) x(1), out.records.Algorithm, g);
SR = splitapply(@mean, out.records.Success, g);
BestFitMean = splitapply(@mean, out.records.BestFit, g);
RuntimeMean = splitapply(@mean, out.records.Runtime, g);
PathLenMean = splitapply(@mean, out.records.PathLength, g);
SmoothMean = splitapply(@mean, out.records.Smoothness, g);
radar_tbl = table(Algorithm, ...
    local_norm01(SR), local_norm01(1 ./ (BestFitMean + eps)), local_norm01(1 ./ (RuntimeMean + eps)), ...
    local_norm01(1 ./ (PathLenMean + eps)), local_norm01(1 ./ (SmoothMean + eps)), ...
    'VariableNames', {'Algorithm', 'SR', 'InvBestFit', 'InvRuntime', 'InvPathLength', 'InvSmoothness'});
writetable(radar_tbl, fullfile(tbl_dir, 'radar_metrics.csv'));

try
    cmp_tbl = compare_vs_llmsfo(out.records, 'EEFOLLM');
    writetable(cmp_tbl, fullfile(tbl_dir, 'comparison_vs_llm_eefo.csv'));
catch ME
    fprintf(2, 'comparison_vs_llm_eefo skipped: %s\n', ME.message);
end

log_message(log_file, 'Rerun merge done.');
fprintf(1, 'Merged. Updated: %s and tables/*.csv\n', result_mat);

if ~regen_figures
    return;
end

fig_conv = fullfile(base_fig, 'convergence');
fig_paths = fullfile(base_fig, 'paths');
ensure_dir(fig_conv);
ensure_dir(fig_paths);
map_list_all = generate_maps(cfg);
map_names_all = cellfun(@(x) x.name, map_list_all, 'UniformOutput', false);
for k = 1:numel(maps_subset)
    m = maps_subset{k}.name;
    mi = find(strcmp(map_names_all, m), 1);
    if isempty(mi)
        mi = find(strcmp(cfg.maps.names, m), 1);
    end
    curves = out.curves.(m);
    plot_convergence(curves, fullfile(fig_conv, ['conv_', m]), ...
        sprintf('Convergence - %s (%s)', m, suffix), cfg);
    pths = out.best_paths.(m);
    plot_paths(map_list_all{mi}, pths, fullfile(fig_paths, ['paths_', m]), ...
        sprintf('Best Paths - %s (%s)', m, suffix), cfg);
end
fprintf(1, 'Figures updated for: %s\n', strjoin(map_names, ', '));
end

function z = local_norm01(x)
x = double(x);
mn = min(x); mx = max(x);
if abs(mx - mn) < eps
    z = ones(size(x));
else
    z = (x - mn) ./ (mx - mn);
end
end
