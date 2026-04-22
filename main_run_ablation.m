function main_run_ablation()
%MAIN_RUN_ABLATION Run ablation studies (SFO variants; stage-wise uses EEFOLLM).
root_dir = fileparts(mfilename('fullpath'));
addpath(fullfile(root_dir, 'config'));
addpath(fullfile(root_dir, 'utils'));
cfg = default_config();
init_paths(cfg.paths.root);
result_dir = fullfile(cfg.paths.results, 'ablation');
fig_dir = fullfile(cfg.paths.figures, 'ablation');
ensure_dir(result_dir); ensure_dir(fig_dir);
result_mat = fullfile(result_dir, 'ablation_results.mat');

if exist(result_mat, 'file') && ~cfg.rerun_ablation
    loaded = load(result_mat, 'all_records', 'summary_tbl');
    all_records = loaded.all_records; summary_tbl = loaded.summary_tbl; %#ok<NASGU>
else
    map_list = generate_maps(cfg);
    stage_weights_map = struct();
    static_weight_map = struct();
    for i = 1:numel(map_list)
        feat = extract_map_features(map_list{i}, '');
        [sw, ~] = generate_llm_weights(feat, cfg, '');
        stage_weights_map.(map_list{i}.name) = sw;
        static_weight_map.(map_list{i}.name) = sw.mid;
    end

    records_all = table();
    variants = {'SFO_Baseline', 'SFO_HandcraftedStatic', 'SFO_LLM_Static', ...
        'SFO_LLM_StageWise', 'SFO_LLM_StageWise_Smooth'};
    for vi = 1:numel(variants)
        v = variants{vi};
        opts = struct();
        opts.log_file = fullfile(cfg.paths.logs, ['ablation_', v, '.log']);
        cfg_run = cfg;
        if strcmp(v, 'SFO_Baseline')
            out = run_experiment_batch(cfg_run, map_list, {'SFO'}, cfg.exp.runs_per_map, opts);
        elseif strcmp(v, 'SFO_HandcraftedStatic')
            opts.static_weight_override = cfg.weights.handcrafted;
            out = run_experiment_batch(cfg_run, map_list, {'SFO'}, cfg.exp.runs_per_map, opts);
        elseif strcmp(v, 'SFO_LLM_Static')
            opts.static_weight_map = static_weight_map;
            out = run_experiment_batch(cfg_run, map_list, {'SFO'}, cfg.exp.runs_per_map, opts);
        elseif strcmp(v, 'SFO_LLM_StageWise')
            opts.stage_weights_map = stage_weights_map;
            out = run_experiment_batch(cfg_run, map_list, {'EEFOLLM'}, cfg.exp.runs_per_map, opts);
        else
            cfg_run.path.enable_post_smooth = true;
            opts.stage_weights_map = stage_weights_map;
            out = run_experiment_batch(cfg_run, map_list, {'EEFOLLM'}, cfg.exp.runs_per_map, opts);
        end
        t = out.records;
        t.Variant = repmat(string(v), height(t), 1);
        records_all = [records_all; t]; %#ok<AGROW>
    end

    all_records = records_all;
    summary_tbl = compute_statistics(rename_algo_with_variant(all_records));
    save(result_mat, 'all_records', 'summary_tbl');
    writetable(all_records, fullfile(result_dir, 'ablation_records.csv'));
    writetable(summary_tbl, fullfile(result_dir, 'ablation_summary.csv'));
end

% Ablation boxplot
plot_boxplot(all_records.BestFit, cellstr(all_records.Variant), ...
    fullfile(fig_dir, 'ablation_boxplot_bestfit'), 'Ablation Best Fitness', 'Best Fitness', cfg);

% Ablation bar (mean best fit)
g = findgroups(all_records.Variant);
vars = splitapply(@(x) x(1), all_records.Variant, g);
mean_fit = splitapply(@mean, all_records.BestFit, g);
f = figure('Visible', 'off', 'Color', 'w');
bar(mean_fit); set(gca, 'XTickLabel', cellstr(vars), 'XTickLabelRotation', 20);
ylabel('Mean Best Fitness'); title('Ablation Mean Performance'); grid on;
exportgraphics(f, fullfile(fig_dir, 'ablation_bar_meanfit.png'), 'Resolution', cfg.plot.dpi);
savefig(f, fullfile(fig_dir, 'ablation_bar_meanfit.fig'));
close(f);
end

function t2 = rename_algo_with_variant(t)
t2 = t;
t2.Algorithm = t2.Variant;
end
