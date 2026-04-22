function main_run_paper_benchmark10_full(force_rerun)
%MAIN_RUN_PAPER_BENCHMARK10_FULL 单次跑完论文主表对比的 10 个算法（5 图 × 每图 runs_per_map）。
%
%   种子与 cfg.exp.algorithms_zoo30 中的全局序号一致（见 paper_benchmark_zoo_global_indices），
%   EEFOLLM 阶段权重：每图一次 Python+Qwen + MATLAB 校验（与 default_config / generate_llm_weights 一致）。
%
%   输出:
%     results/global_experiments_paper10/{mat,tables,weights}/...
%     results/tables/paper_main/table3_fitness_long.csv 等（由 generate_main_tables 写入）
%
%   用法:
%     main_run_paper_benchmark10_full          % 若已有缓存 mat 则跳过优化
%     main_run_paper_benchmark10_full(true)     % 强制重跑
%
%   依赖: init_paths、真实/模拟 Qwen 与 default_config 中 LLM 设置（与工程其余实验一致）。

if nargin < 1 || isempty(force_rerun)
    force_rerun = false;
end

root_dir = fileparts(mfilename('fullpath'));
addpath(root_dir);

addpath(fullfile(root_dir, 'config'));
addpath(fullfile(root_dir, 'utils'));
cfg = default_config();
init_paths(cfg.paths.root);
ensure_dir(cfg.paths.results);
ensure_dir(cfg.paths.logs);

out_tag = 'global_experiments_paper10';
base_res = fullfile(cfg.paths.results, out_tag);
mat_dir = fullfile(base_res, 'mat');
tbl_dir = fullfile(base_res, 'tables');
wgt_dir = fullfile(base_res, 'weights');
fig_llm = fullfile(cfg.paths.figures, out_tag, 'llm_stage_weights');
cellfun(@ensure_dir, {base_res, mat_dir, tbl_dir, wgt_dir, fig_llm}, 'UniformOutput', false);

result_mat = fullfile(mat_dir, 'global_results.mat');
log_file = fullfile(cfg.paths.logs, 'paper_benchmark10_full.log');

if exist(result_mat, 'file') && ~force_rerun && ~cfg.rerun_global_experiments
    fprintf(2, ['\n*** CACHED ***\nLoaded %s — no optimization run.\n' ...
        'To force rerun: main_run_paper_benchmark10_full(true)\n\n'], result_mat);
    loaded = load(result_mat, 'out', 'summary_tbl', 'rank_tbl');
    out = loaded.out;
else
    [algo_list, ~] = paper_benchmark_algorithms10();
    gidx_list = paper_benchmark_zoo_global_indices();

    map_list = generate_maps(cfg);
    stage_weights_map = build_llm_stage_weights_for_maps(cfg, map_list, wgt_dir, fig_llm, log_file);

    opts = struct();
    opts.stage_weights_map = stage_weights_map;
    opts.log_file = log_file;
    opts.verbose_console = true;
    opts.seed_global_indices = gidx_list;

    log_message(log_file, sprintf('Paper benchmark 10: %s', strjoin(algo_list, ', ')));
    log_message(log_file, sprintf('Zoo global indices: %s', mat2str(gidx_list')));

    out = run_experiment_batch(cfg, map_list, algo_list, cfg.exp.runs_per_map, opts);

    summary_tbl = compute_statistics(out.records);
    rank_tbl = friedman_rank(out.records);
    save(result_mat, 'out', 'summary_tbl', 'rank_tbl', 'cfg', 'algo_list', 'map_list', 'gidx_list', '-v7');
    writetable(out.records, fullfile(tbl_dir, 'records.csv'));
    writetable(summary_tbl, fullfile(tbl_dir, 'summary.csv'));
    writetable(rank_tbl, fullfile(tbl_dir, 'friedman_rank.csv'));
    export_seeds_used_csv(cfg, algo_list, gidx_list, tbl_dir);
end

records_csv = fullfile(tbl_dir, 'records.csv');
if ~isfile(records_csv)
    writetable(out.records, records_csv);
end

generate_main_tables(struct('records_csv', records_csv));
fprintf(1, '\n=== Done. Table 3 (and related) -> %s\n', ...
    fullfile(cfg.paths.results, 'tables', 'paper_main'));
end

function stage_weights_map = build_llm_stage_weights_for_maps(cfg, map_list, wgt_dir, fig_llm, log_file)
stage_weights_map = struct();
for i = 1:numel(map_list)
    map_name = map_list{i}.name;
    [sw, meta] = generate_llm_weights(extract_map_features(map_list{i}, ''), cfg, '');
    stage_weights_map.(map_name) = sw;
    save_json(fullfile(wgt_dir, ['weights_', map_name, '.json']), sw);
    log_message(log_file, sprintf('Map=%s EEFOLLM weights: fallback=%d msg=%s', ...
        map_name, meta.used_fallback, meta.message));
    plot_weight_bars(sw, fullfile(fig_llm, ['weights_', map_name]), ...
        ['LLM Stage Weights - ', map_name], cfg);
end
end

function export_seeds_used_csv(cfg, algo_list, gidx_list, tbl_dir)
maps = cfg.maps.names;
rows = [];
for mi = 1:numel(maps)
    for ai = 1:numel(algo_list)
        gidx = gidx_list(ai);
        for r = 1:cfg.exp.runs_per_map
            x.Map = string(maps{mi});
            x.Algorithm = string(algo_list{ai});
            x.Run = r;
            x.GlobalAlgoIndex = gidx;
            x.Seed = cfg.base_seed + mi * 1000 + gidx * 100 + r;
            rows = [rows; x]; %#ok<AGROW>
        end
    end
end
writetable(struct2table(rows), fullfile(tbl_dir, 'seeds_used.csv'));
end
