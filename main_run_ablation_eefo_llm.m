function main_run_ablation_eefo_llm(force_rerun)
%MAIN_RUN_ABLATION_EEFO_LLM EEFO 搜索核消融：全核 / 残缺核 × 静态权 / LLM 阶段权（共 4 组）。
%   若只需「残缺 EEFO + LLM」、五图全量，见 main_run_ablation_eefollm_ablated_only（可只选部分残缺方式）。
%
%   对比：
%     EEFO            — 完整 EEFO + cfg.weights.default
%     EEFO-PARTIAL    — 残缺 EEFO（仅 guide，无 shock、无随机重启）+ 同上静态权
%     EEFOLLM         — 完整 EEFO + LLM 阶段权（与主实验一致）
%     EEFOLLM-PARTIAL — 残缺 EEFO + LLM 阶段权（检验在弱搜索核下 LLM 塑造是否仍有效）
%
%   输出: results/ablation_eefo_llm/tables/records.csv，mat/ablation_eefo_llm.mat
%
%   用法: 工程根目录执行 main_run_ablation_eefo_llm
%         main_run_ablation_eefo_llm(true) 强制重算

if nargin < 1
    force_rerun = false;
end

root_dir = fileparts(mfilename('fullpath'));
addpath(fullfile(root_dir, 'config'));
addpath(fullfile(root_dir, 'utils'));
cfg = default_config();
init_paths(cfg.paths.root);

base_res = fullfile(cfg.paths.results, 'ablation_eefo_llm');
mat_dir = fullfile(base_res, 'mat');
tbl_dir = fullfile(base_res, 'tables');
wgt_dir = fullfile(base_res, 'weights');
cellfun(@ensure_dir, {base_res, mat_dir, tbl_dir, wgt_dir}, 'UniformOutput', false);

result_mat = fullfile(mat_dir, 'ablation_eefo_llm.mat');
log_file = fullfile(cfg.paths.logs, 'ablation_eefo_llm.log');

algo_list = {'EEFO', 'EEFO-PARTIAL', 'EEFOLLM', 'EEFOLLM-PARTIAL'};

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
