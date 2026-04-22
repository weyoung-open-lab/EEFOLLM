function run_experiment(force_rerun)
%RUN_EXPERIMENT  Single entry: 5 maps x cfg.exp.runs_per_map (default 20) x 10 algorithms (EEFOLLM + 9 baselines, zoo order).
%   From repository root:  addpath('matlab');  run_experiment
%   Or:  run('matlab/run_experiment.m')  with Current Folder = repository root
%
%   See README.md. Force full recompute: run_experiment(true)
%
%   See also: run_global_experiments_batch1

if nargin < 1
    force_rerun = false;
end
root_repo = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root_repo, 'matlab', 'config'));
addpath(fullfile(root_repo, 'matlab', 'utils'));
run_global_experiments_batch1(force_rerun);
end
