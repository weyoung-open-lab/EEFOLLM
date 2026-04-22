function main_run_all()
%MAIN_RUN_ALL One-click pipeline for the EEFOLLM path planning project.
%
%   Default (cfg.pipeline.run_optional_studies = false):
%     1) Quick EEFOLLM: main_run_eefollm_quick (full benchmark: main_run_global_experiments_batch(1))
%
%   Optional (set cfg.pipeline.run_optional_studies = true in default_config.m):
%     2) map overview + method diagrams
%     3) main experiments, ablation, parameter study, seeds log
%     (Dedicated smoke / tune drivers are not shipped in the public tree.)

root_dir = fileparts(mfilename('fullpath'));
addpath(fullfile(root_dir, 'config'));
addpath(fullfile(root_dir, 'utils'));
cfg = default_config();
init_paths(cfg.paths.root);
ensure_dir(cfg.paths.results); ensure_dir(cfg.paths.figures); ensure_dir(cfg.paths.logs);
log_file = fullfile(cfg.paths.logs, 'main_run_all.log');
log_message(log_file, '===== Start main_run_all =====');

try
    main_run_eefollm_quick();
    log_message(log_file, 'EEFOLLM quick benchmark done (results/eefollm_benchmark). Batch: main_run_global_experiments_batch(1).');

    if ~isfield(cfg, 'pipeline') || ~isfield(cfg.pipeline, 'run_optional_studies') || ...
            ~cfg.pipeline.run_optional_studies
        log_message(log_file, 'Skipping optional smoke / main / ablation / param (cfg.pipeline.run_optional_studies=false).');
        log_message(log_file, '===== main_run_all completed (quick benchmark only) =====');
        return;
    end

    map_list = generate_maps(cfg);
    log_message(log_file, 'Stage1 done: maps generated/loaded.');
    plot_all_maps_overview(map_list, fullfile(cfg.paths.figures, 'all_maps_overview'), cfg);
    generate_method_diagrams(cfg);
    log_message(log_file, 'Method diagrams exported.');

    main_run_main_experiments();
    log_message(log_file, 'Stage3 done: main experiments finished.');

    main_run_ablation();
    log_message(log_file, 'Stage4 done: ablation finished.');

    main_run_param_study();
    log_message(log_file, 'Stage5 done: parameter study finished.');

    export_seed_log(cfg);
    log_message(log_file, 'Stage7/8 done: analysis outputs and reproducibility logs updated.');
    log_message(log_file, '===== main_run_all completed successfully =====');
catch ME
    log_message(log_file, ['FATAL: ', ME.message]);
    rethrow(ME);
end
end

function export_seed_log(cfg)
maps = cfg.maps.names;
algos = cfg.exp.algorithms;
rows = [];
for mi = 1:numel(maps)
    for ai = 1:numel(algos)
        for r = 1:cfg.exp.runs_per_map
            x.Map = string(maps{mi});
            x.Algorithm = string(algos{ai});
            x.Run = r;
            x.Seed = cfg.base_seed + mi * 1000 + ai * 100 + r;
            rows = [rows; x]; %#ok<AGROW>
        end
    end
end
T = struct2table(rows);
writetable(T, fullfile(cfg.paths.results, 'seeds_log.csv'));
end
