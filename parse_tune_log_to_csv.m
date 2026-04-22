function parse_tune_log_to_csv(log_file, out_csv)
%PARSE_TUNE_LOG_TO_CSV Recover grid-search rows from tune_map45_llmsfo.log when the run was interrupted.
%
% Usage: current folder must be project root (E:\sfollm), then:
%   parse_tune_log_to_csv
%
% Or:
%   parse_tune_log_to_csv('logs/tune_map45_llmsfo.log', 'results/tune_map45_recovered_from_log.csv')
%
% Input log lines look like:
%   id=12 pop=80 iter=1400 k=13 pen_x=2.00 rate4=0.00 rate5=0.00 strict_ok=0
%
% Output: mean_bestfit columns are NaN (not logged on summary lines).

root_dir = fileparts(mfilename('fullpath'));
if nargin < 1 || isempty(log_file)
    log_file = fullfile(root_dir, 'logs', 'tune_map45_llmsfo.log');
end
if nargin < 2 || isempty(out_csv)
    out_csv = fullfile(root_dir, 'results', 'tune_map45_recovered_from_log.csv');
end

if ~isfile(log_file)
    error('Log not found: %s', log_file);
end

txt = fileread(log_file);
lines = splitlines(txt);
pat = 'id=(\d+) pop=(\d+) iter=(\d+) k=(\d+) pen_x=([\d.]+) rate4=([\d.]+) rate5=([\d.]+) strict_ok=(\d+)';

idv = []; popv = []; iterv = []; kv = []; psv = []; r4 = []; r5 = []; strict = [];
for li = 1:numel(lines)
    line = lines{li};
    tok = regexp(line, pat, 'tokens', 'once');
    if isempty(tok)
        continue;
    end
    idv(end + 1, 1) = str2double(tok{1}); %#ok<AGROW>
    popv(end + 1, 1) = str2double(tok{2});
    iterv(end + 1, 1) = str2double(tok{3});
    kv(end + 1, 1) = str2double(tok{4});
    psv(end + 1, 1) = str2double(tok{5});
    r4(end + 1, 1) = str2double(tok{6});
    r5(end + 1, 1) = str2double(tok{7});
    strict(end + 1, 1) = str2double(tok{8});
end

if isempty(idv)
    error('No matching id= summary lines in %s', log_file);
end

m4 = nan(numel(idv), 1);
m5 = nan(numel(idv), 1);
T = table(idv, popv, iterv, kv, psv, r4, r5, strict, m4, m5, ...
    'VariableNames', {'id', 'pop', 'iter', 'k_waypoints', 'penalty_scale', ...
    'map4_feasible_rate', 'map5_feasible_rate', 'both_maps_all_runs_ok', 'mean_bestfit_map4', 'mean_bestfit_map5'});

outd = fileparts(out_csv);
if ~isempty(outd) && ~isfolder(outd)
    mkdir(outd);
end
writetable(T, out_csv);
fprintf(1, 'Parsed %d rows -> %s\n', height(T), out_csv);
fprintf(1, 'Note: if the log contains two runs, filter by pop/iter/k as needed.\n');
end
