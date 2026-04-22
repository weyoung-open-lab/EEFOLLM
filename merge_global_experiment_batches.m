function T = merge_global_experiment_batches(out_path)
%MERGE_GLOBAL_EXPERIMENT_BATCHES Vertically merge records.csv from batch1..batch3 into one CSV.
%
%   merge_global_experiment_batches()  % writes results/global_experiments_merged/tables/records_merged.csv
%   T = merge_global_experiment_batches('path/to/out.csv');

root_dir = fileparts(mfilename('fullpath'));
addpath(fullfile(root_dir, 'config'));
addpath(fullfile(root_dir, 'utils'));
cfg = default_config();
parts = {};
for b = 1:3
    f = fullfile(cfg.paths.results, sprintf('global_experiments_batch%d', b), 'tables', 'records.csv');
    if ~isfile(f)
        warning('Missing %s — run main_run_global_experiments_batch(%d) first.', f, b);
        continue;
    end
    parts{end+1} = readtable(f); %#ok<AGROW>
end
if isempty(parts)
    error('No batch records.csv found.');
end
T = vertcat(parts{:});
if nargin < 1 || isempty(out_path)
    d = fullfile(cfg.paths.results, 'global_experiments_merged', 'tables');
    ensure_dir(d);
    out_path = fullfile(d, 'records_merged.csv');
else
    ensure_dir(fileparts(out_path));
end
writetable(T, out_path);
fprintf(1, 'Merged %d rows -> %s\n', height(T), out_path);
end
