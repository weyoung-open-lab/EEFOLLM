function main_run_ablation_eefollm_ablated_only(force_rerun)
%MAIN_RUN_ABLATION_EEFOLLM_ABLATED_ONLY 仅「残缺 EEFO + LLM 阶段权」，五图 x runs_per_map（默认 20）。
%
%   完整 EEFOLLM 若已跑过，用本脚本只补残缺核 + LLM 的对比；不跑 EEFO / 完整 EEFOLLM。
%
%   残缺方式（与 run_eefo 中 eefo_variant 一致，任选子集；在下面 algo_list 里删掉不需要的）：
%     EEFOLLM-NS      去掉高斯 shock，保留向最优引导 + 概率 0.25 的随机重启
%     EEFOLLM-NJ      去掉随机重启，保留 shock + 引导
%     EEFOLLM-PARTIAL 仅保留向全局最优的引导（无 shock、无随机重启），最简核
%
%   输出: results/ablation_eefollm_ablated_only/tables/records.csv
%
%   用法: main_run_ablation_eefollm_ablated_only
%         main_run_ablation_eefollm_ablated_only(true)

if nargin < 1
    force_rerun = false;
end

root_dir = fileparts(mfilename('fullpath'));
addpath(fullfile(root_dir, 'config'));
addpath(fullfile(root_dir, 'utils'));
cfg = default_config();
init_paths(cfg.paths.root);

base_res = fullfile(cfg.paths.results, 'ablation_eefollm_ablated_only');
mat_dir = fullfile(base_res, 'mat');
tbl_dir = fullfile(base_res, 'tables');
wgt_dir = fullfile(base_res, 'weights');
cellfun(@ensure_dir, {base_res, mat_dir, tbl_dir, wgt_dir}, 'UniformOutput', false);

result_mat = fullfile(mat_dir, 'ablation_eefollm_ablated_only.mat');
log_file = fullfile(cfg.paths.logs, 'ablation_eefollm_ablated_only.log');

algo_list = {'EEFOLLM-NS', 'EEFOLLM-NJ', 'EEFOLLM-PARTIAL'};

if exist(result_mat, 'file') && ~force_rerun && ~cfg.rerun_ablation
    fprintf(1, 'Loaded cached %s (pass true to recompute).\n', result_mat);
    load(result_mat, 'out', 'summary_tbl');
else
    map_list = generate_maps(cfg);
    stage_weights_map = struct();
    for i = 1:numel(map_list)
        mn = map_list{i}.name;
        [sw, meta] = generate_llm_weights(extract_map_features(map_list{i}, ''), cfg, '');
        stage_weights_map.(mn) = sw;
        save_json(fullfile(wgt_dir, ['weights_', mn, '.json']), sw);
        log_message(log_file, sprintf('Map=%s LLM weights ok=%d fallback=%d %s', mn, meta.llm_validation_ok, meta.used_fallback, meta.message));
    end

    opts = struct();
    opts.stage_weights_map = stage_weights_map;
    opts.log_file = log_file;
    opts.seed_algo_offset = 0;
    opts.verbose_console = true;

    out = run_experiment_batch(cfg, map_list, algo_list, cfg.exp.runs_per_map, opts);
    summary_tbl = compute_statistics(out.records);
    save(result_mat, 'out', 'summary_tbl', 'cfg', 'algo_list', 'map_list');
    writetable(out.records, fullfile(tbl_dir, 'records.csv'));
    writetable(summary_tbl, fullfile(tbl_dir, 'summary.csv'));
    fprintf(1, 'Saved %s\n', fullfile(tbl_dir, 'records.csv'));
end

end
