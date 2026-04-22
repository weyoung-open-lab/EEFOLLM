function cfg = default_config()
%DEFAULT_CONFIG Central configuration for EEFOLLM path planning project.
%   All experiment scripts should load this function first to ensure
%   reproducible and fair settings across methods.

cfg.project_name = 'EEFOLLM-PathPlanning';
cfg.base_seed = 20260417;

% Rerun controls
cfg.regenerate_maps = false;
cfg.rerun_main_experiments = false;
cfg.rerun_ablation = false;
cfg.rerun_param_study = false;
cfg.rerun_global_experiments = false;
cfg.use_llm_reward = true;
cfg.fallback_to_handcrafted = true;
cfg.use_real_qwen = true;

% Paths
cfg.paths.root = fileparts(fileparts(mfilename('fullpath')));
cfg.paths.maps = fullfile(cfg.paths.root, 'maps');
cfg.paths.results = fullfile(cfg.paths.root, 'results');
cfg.paths.figures = fullfile(cfg.paths.root, 'figures');
cfg.paths.logs = fullfile(cfg.paths.root, 'logs');
cfg.paths.llm = fullfile(cfg.paths.root, 'llm');
cfg.paths.venv_python = fullfile(cfg.paths.root, '.venv', 'Scripts', 'python.exe');

% --- Benchmark maps (single source of truth; run main_regenerate_all_maps after any change) ---
%   Map   Grid     Density   Role (paper-style description)
%   Map1  40x40    0.08      Small, sparse
%   Map2  40x40    0.13      Small, medium clutter
%   Map3  40x40    0.18      Small, dense (hardest among 40x40)
%   Map4  70x70    0.08      Large, same density target as Map1
%   Map5  70x70    0.10      Large, slightly higher clutter than Map4
% Start/goal: N=40 -> start_40/goal_40; N>40 -> corner [2,2] to [N-2,N-2] (see generate_maps.m).
cfg.maps.names = {'Map1', 'Map2', 'Map3', 'Map4', 'Map5'};
cfg.maps.sizes = [40, 40, 40, 70, 70];
cfg.maps.complexity = [0.08, 0.13, 0.18, 0.08, 0.10];
cfg.maps.start_40 = [2, 2];
cfg.maps.goal_40 = [38, 38];
cfg.maps.start_80 = [2, 2];
cfg.maps.goal_80 = [78, 78]; % for N=80 equals [N-2,N-2]; large maps use [N-2,N-2] in generate_maps
cfg.maps.safe_zone_radius = 2;

% Path encoding (waypoint count K; dimension = 2K).
cfg.path.default_k = 5;
cfg.path.sample_step = 0.5;
cfg.path.enable_post_smooth = false;

% Budget and fairness settings
cfg.exp.population = 30;
cfg.exp.iterations = 100;
cfg.exp.runs_per_map = 20;
cfg.exp.smoke_runs = 3;
cfg.exp.algorithms = {'EEFOLLM', 'SFO', 'PSO', 'GWO', 'HO', 'EEFO', 'SBOA', 'ARO'};
% Full zoo list (30) for screening / paper comparison; EEFOLLM uses LLM stage weights; SFO/EEFO/etc. use static default weights.
cfg.exp.algorithms_zoo30 = { ...
    'EEFOLLM', 'SFO', 'PSO', 'GWO', 'HO', 'EEFO', 'SBOA', 'ARO', ...
    'DE', 'WOA', 'ABC', 'SSA', 'FA', 'BA', 'CS', 'GA', 'TLBO', 'SCA', ...
    'HHO', 'MFO', 'GSA', 'MVO', 'AOA', 'JAYA', 'WCA', 'SMA', 'MPA', 'EO', 'TSA', 'GTO'};

% SFO behavior probabilities
cfg.sfo.p_fast = 0.35;
cfg.sfo.p_gather = 0.25;
cfg.sfo.p_disp = 0.20;
cfg.sfo.p_escape = 0.20;
cfg.sfo.escape_prob = 0.1;

% Default static reward weights (sum to 1)
cfg.weights.default = struct('wL', 0.35, 'wC', 0.35, 'wS', 0.18, 'wT', 0.12);
cfg.weights.handcrafted = struct('wL', 0.28, 'wC', 0.42, 'wS', 0.18, 'wT', 0.12);
cfg.weights.stage_default.early = struct('wL', 0.22, 'wC', 0.52, 'wS', 0.16, 'wT', 0.10);
cfg.weights.stage_default.mid = struct('wL', 0.30, 'wC', 0.40, 'wS', 0.18, 'wT', 0.12);
cfg.weights.stage_default.late = struct('wL', 0.40, 'wC', 0.25, 'wS', 0.20, 'wT', 0.15);

% Handcrafted fallback when LLM JSON is invalid (used by validate_llm_weights)
cfg.weights.handcrafted_stage_weights.early = struct('wL', 0.25, 'wC', 0.40, 'wS', 0.15, 'wT', 0.20);
cfg.weights.handcrafted_stage_weights.mid = struct('wL', 0.30, 'wC', 0.30, 'wS', 0.20, 'wT', 0.20);
cfg.weights.handcrafted_stage_weights.late = struct('wL', 0.30, 'wC', 0.20, 'wS', 0.25, 'wT', 0.25);

% NSGA-II (EEFOLLM-PARETO): SBX / polynomial mutation; p_mut default = min(0.2, 1/dim) in run_pareto_nsga2
cfg.pareto = struct('eta_c', 15, 'eta_m', 20);

% OAW (Online Adaptive Weights): see fitness/adapt_stage_weights_online.m, algorithms/run_eefo.m
% Applied only for EEFOLLM when params.use_online_adaptive_weights is true (see run_experiment_batch).
% Default false so global batches stay comparable; enable in main_run_llm_eefo_oaw.m
cfg.online_adaptive = struct( ...
    'enable', false, ...
    'every', 5, ...
    'frac_high', 0.35, ...
    'frac_low', 0.08, ...
    'eta_up', 0.06, ...
    'eta_down', 0.04, ...
    'factor_min', 0.92, ...
    'factor_max', 1.12);

% Iteration progress boundaries for early / mid / late (see get_stage_weights)
cfg.stage_split = struct('early_end', 0.30, 'late_start', 0.70);

% One-click pipeline: skip heavy ablation / param study by default (set true to run all)
cfg.pipeline = struct('run_optional_studies', false);

% LLM io and mode
cfg.llm.map_feature_json = fullfile(cfg.paths.llm, 'io', 'map_features_runtime.json');
cfg.llm.weight_json = fullfile(cfg.paths.llm, 'io', 'qwen_weights_runtime.json');
if isfile(cfg.paths.venv_python)
    cfg.llm.python_exec = cfg.paths.venv_python;
else
    cfg.llm.python_exec = 'python';
end
cfg.llm.generator_script = fullfile(cfg.paths.llm, 'generate_qwen_weights.py');
cfg.llm.prompt_file = fullfile(cfg.paths.llm, 'prompts', 'reward_prompt.txt');
cfg.llm.timeout_sec = 120;
cfg.llm.repo_id = 'Qwen/Qwen2.5-3B-Instruct';
cfg.llm.local_model_dir = fullfile(cfg.paths.llm, 'models', 'Qwen2.5-3B-Instruct-full');

% Penalty constants
cfg.penalty.collision_hard = 1e4;
cfg.penalty.obstacle_proximity = 10;
cfg.penalty.min_obstacle_dist = 2.0;
cfg.penalty.sharp_turn_threshold_deg = 100;
cfg.penalty.turn_scale = 2.0;

% Plot style
cfg.plot.line_width = 1.6;
cfg.plot.font_name = 'Arial';
cfg.plot.font_size = 11;
cfg.plot.dpi = 200;

% Parameter study setup
cfg.param.pop_sizes = [20, 30, 50];
cfg.param.iter_counts = [50, 100, 150];
cfg.param.k_values = [3, 5, 7];
cfg.param.weight_grid = [...
    0.25, 0.45, 0.18, 0.12; ...
    0.35, 0.35, 0.18, 0.12; ...
    0.45, 0.25, 0.18, 0.12];

end
