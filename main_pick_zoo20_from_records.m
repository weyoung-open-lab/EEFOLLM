function main_pick_zoo20_from_records(records_csv, n_keep)
%MAIN_PICK_ZOO20_FROM_RECORDS From a full records.csv, list the n_keep algorithms with smallest mean BestFit.
% Use after merge_global_experiment_batches or any run with all algorithms present.
%
%   main_pick_zoo20_from_records()   % default: merged table, or batch1 if no merge
%   main_pick_zoo20_from_records('results/global_experiments_batch1/tables/records.csv', 20)
%
% Writes: results/selected_zoo20_by_meanfit.txt (algorithm names, one line CSV)

if nargin < 1 || isempty(records_csv)
    root_dir = fileparts(mfilename('fullpath'));
    addpath(fullfile(root_dir, 'config'));
    cfg = default_config();
    merged = fullfile(cfg.paths.results, 'global_experiments_merged', 'tables', 'records_merged.csv');
    b1 = fullfile(cfg.paths.results, 'global_experiments_batch1', 'tables', 'records.csv');
    if isfile(merged)
        records_csv = merged;
    elseif isfile(b1)
        records_csv = b1;
        fprintf(1, 'Using batch1 only (%s). Need merged 30-algo CSV to pick among all 30.\n', b1);
    else
        error('No records CSV found. Pass path or run experiments first.');
    end
end
if nargin < 2 || isempty(n_keep)
    n_keep = 20;
end

addpath(fullfile(fileparts(mfilename('fullpath')), 'utils'));
Tr = readtable(records_csv);
n_distinct = numel(unique(cellstr(string(Tr.Algorithm))));
if n_distinct < n_keep
    fprintf(1, 'Note: records contain only %d distinct algorithms (requested top %d).\n', n_distinct, n_keep);
end
[algos, tbl] = pick_smallest_mean_fitness_algorithms(records_csv, n_keep);

fprintf(1, '=== Smallest mean BestFit: top %d (among those present) ===\n', numel(algos));
disp(tbl);

out_dir = fullfile(fileparts(fileparts(fileparts(records_csv))), '');
if isempty(out_dir)
    out_dir = fileparts(records_csv);
end
root_dir = fileparts(mfilename('fullpath'));
addpath(fullfile(root_dir, 'config'));
cfg = default_config();
out_txt = fullfile(cfg.paths.results, sprintf('selected_zoo%d_by_meanfit.txt', n_keep));
fid = fopen(out_txt, 'w');
if fid > 0
    fprintf(fid, '%s\n', strjoin(algos, ', '));
    fclose(fid);
end
mat_file = fullfile(cfg.paths.results, sprintf('selected_zoo%d_by_meanfit.mat', n_keep));
save(mat_file, 'algos', 'tbl', 'records_csv');

fprintf(1, '\nMATLAB cell (paste into cfg if needed):\n');
fprintf(1, 'cfg.exp.algorithms_zoo%d = { ...\n', n_keep);
for i = 1:numel(algos)
    if i == 1
        fprintf(1, '''%s''', algos{i});
    else
        fprintf(1, ', ''%s''', algos{i});
    end
    if mod(i, 8) == 0 && i < numel(algos)
        fprintf(1, ', ...\n');
    end
end
fprintf(1, ' };\n');
fprintf(1, '\nSaved: %s and %s\n', out_txt, mat_file);
end
