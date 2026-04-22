function varargout = generate_main_tables(opts)
%GENERATE_MAIN_TABLES 从 results 合并记录生成论文主表（Table 3 风格适应度 + Table 5 风格运行时间）
%
%   实验设定: 10 算法 x 5 图 x 每图 20 次；「我们的方法」注册名为 EEFOLLM。
%   优先读取 global_experiments_merged/tables/records_merged.csv；若不存在则内存合并 batch1~batch3。
%
%   输出目录: results/tables/paper_main/
%     - table3_fitness_long.csv          （主文表 3：适应度）
%     - table3_fitness_wide.tex          （booktabs，算法为列；EEFOLLM 列加粗）
%     - table3_summary_ranks.csv
%     - table5_runtime_long.csv          （主文表 5：运行时间）
%     - table5_runtime_wide.tex
%     - table5_summary_ranks.csv
%     - generation_log.txt
%     - paper_main_tables.mat            （T3_long, T5_long, T3_sum, T5_sum）
%
%   地图设定表见 generate_map_setting_table.m（主文表 1）
%
%   用法:
%       generate_main_tables
%       generate_main_tables(struct('expected_runs',20))
%
%   兼容: Algorithm 若为旧名 LLM-EEFO，会视为 EEFOLLM。

if nargin < 1, opts = struct(); end
if ~isfield(opts, 'expected_runs'), opts.expected_runs = 20; end
if ~isfield(opts, 'out_subdir'), opts.out_subdir = 'paper_main'; end
if ~isfield(opts, 'records_csv'), opts.records_csv = ''; end

root_dir = fileparts(mfilename('fullpath'));
addpath(root_dir); % merge_global_experiment_batches.m 等在工程根目录
addpath(fullfile(root_dir, 'config'));
addpath(fullfile(root_dir, 'utils'));
init_paths(root_dir);

cfg = default_config();
[algo_list, ~] = paper_benchmark_algorithms10();
maps = cfg.maps.names(:);
if isstring(maps), maps = cellstr(maps); end
our_algo = 'EEFOLLM';

out_dir = fullfile(cfg.paths.results, 'tables', opts.out_subdir);
ensure_dir(out_dir);
log_path = fullfile(out_dir, 'generation_log.txt');
logfid = fopen(log_path, 'w');
cleanup = onCleanup(@() fclose(logfid));

fprintf(logfid, '=== generate_main_tables %s ===\n', datestr(now, 31));
fprintf(1, 'Output dir: %s\n', out_dir);

records_source = '';
T = table();
if ~isempty(opts.records_csv) && isfile(opts.records_csv)
    T = readtable(opts.records_csv, 'TextType', 'string');
    records_source = opts.records_csv;
    fprintf(logfid, 'Loaded opts.records_csv: %s\n', opts.records_csv);
end
if isempty(T)
    T = try_load_merged_records(cfg);
    if ~isempty(T)
        records_source = fullfile(cfg.paths.results, 'global_experiments_merged', 'tables', 'records_merged.csv');
    end
end
if isempty(T)
    fprintf(1, 'Merged CSV absent; running merge_global_experiment_batches() ...\n');
    fprintf(logfid, 'merge_global_experiment_batches() called.\n');
    try
        T = merge_global_experiment_batches();
        records_source = fullfile(cfg.paths.results, 'global_experiments_merged', 'tables', 'records_merged.csv');
    catch ME
        fprintf(logfid, 'merge_global_experiment_batches failed: %s\n', ME.message);
        fprintf(1, 'Falling back to in-memory merge of batch1..batch3.\n');
        T = merge_batches_in_memory(cfg);
        records_source = 'batch123_in_memory';
    end
end
if isempty(T)
    error('generate_main_tables:NoData', ...
        'No records found. Place records under global_experiments_batch*/tables/records.csv or pass opts.records_csv.');
end
fprintf(logfid, 'Data source: %s\n', records_source);

T = normalize_algorithm_column(T);
T.Algorithm = cellstr(string(T.Algorithm));
T.Map = cellstr(string(T.Map));

exp_maps = maps(:);
exp_algos = algo_list(:);
row_keep = ismember(string(T.Map), string(exp_maps)) & ismember(string(T.Algorithm), string(exp_algos));
T = T(row_keep, :);
if isempty(T)
    warning('generate_main_tables:EmptyAfterFilter', ...
        'No rows left after filtering to paper_benchmark_algorithms10 — check zoo30 batches completed.');
end

check_coverage(T, exp_maps, exp_algos, opts.expected_runs, logfid);

T3_long = build_fitness_long_table(T, exp_maps, exp_algos);
% 论文表：适应度与排名列保留两位小数
vn = {'BestFitness', 'MeanFitness', 'WorstFitness', 'StdFitness', 'RankByMean'};
for vi = 1:numel(vn)
    v = vn{vi};
    if ismember(v, T3_long.Properties.VariableNames)
        T3_long.(v) = round(T3_long.(v), 2);
    end
end
writetable(T3_long, fullfile(out_dir, 'table3_fitness_long.csv'));

T3_sum = build_summary_ranks_fitness(T3_long, exp_maps, exp_algos);
writetable(T3_sum, fullfile(out_dir, 'table3_summary_ranks.csv'));

tex1 = latex_table_fitness_wide(T3_long, T3_sum, exp_maps, exp_algos, our_algo);
write_text(fullfile(out_dir, 'table3_fitness_wide.tex'), tex1);

T5_long = build_runtime_long_table(T, exp_maps, exp_algos);
writetable(T5_long, fullfile(out_dir, 'table5_runtime_long.csv'));

T5_sum = build_summary_ranks_runtime(T5_long, exp_maps, exp_algos);
writetable(T5_sum, fullfile(out_dir, 'table5_summary_ranks.csv'));

tex2 = latex_table_runtime_wide(T5_long, T5_sum, exp_maps, exp_algos, our_algo);
write_text(fullfile(out_dir, 'table5_runtime_wide.tex'), tex2);

save(fullfile(out_dir, 'paper_main_tables.mat'), 'T3_long', 'T5_long', 'T3_sum', 'T5_sum', 'algo_list', 'maps', 'records_source', '-v7');

fprintf(1, 'Done. See %s\n', log_path);
fprintf(logfid, '=== finished OK ===\n');

if nargout > 0
    varargout{1} = T3_long;
    if nargout > 1, varargout{2} = T5_long; end
end
end

%% --- Data loading ---
function T = try_load_merged_records(cfg)
p = fullfile(cfg.paths.results, 'global_experiments_merged', 'tables', 'records_merged.csv');
if isfile(p)
    T = readtable(p, 'TextType', 'string');
else
    T = table();
end
end

function T = merge_batches_in_memory(cfg)
parts = {};
for b = 1:3
    f = fullfile(cfg.paths.results, sprintf('global_experiments_batch%d', b), 'tables', 'records.csv');
    if isfile(f)
        parts{end+1} = readtable(f, 'TextType', 'string'); %#ok<AGROW>
    end
end
if isempty(parts), T = table(); return; end
T = vertcat(parts{:});
end

function T = normalize_algorithm_column(T)
a = string(T.Algorithm);
a(a == "LLM-EEFO") = "EEFOLLM";
T.Algorithm = cellstr(a);
end

function check_coverage(T, maps, algos, expected_runs, logfid)
for mi = 1:numel(maps)
    for ai = 1:numel(algos)
        n = sum(strcmp(T.Map, maps{mi}) & strcmp(T.Algorithm, algos{ai}));
        if n == 0
            fprintf(logfid, 'WARN: missing all runs: Map=%s Algorithm=%s\n', maps{mi}, algos{ai});
            warning('generate_main_tables:MissingBlock', 'Missing: %s | %s', maps{mi}, algos{ai});
        elseif n ~= expected_runs
            fprintf(logfid, 'WARN: expected %d runs, got %d: Map=%s Algorithm=%s\n', ...
                expected_runs, n, maps{mi}, algos{ai});
        end
    end
end
end

%% --- Table builders ---
function T1 = build_fitness_long_table(T, maps, algos)
rows = cell(0, 7);
for mi = 1:numel(maps)
    m = maps{mi};
    nA = numel(algos);
    bf = nan(nA, 1);
    mn = nan(nA, 1);
    wx = nan(nA, 1);
    sd = nan(nA, 1);
    for ai = 1:nA
        a = algos{ai};
        ix = strcmp(T.Map, m) & strcmp(T.Algorithm, a);
        vals = T.BestFit(ix);
        vals = vals(isfinite(vals));
        if isempty(vals), continue; end
        bf(ai) = min(vals);
        mn(ai) = mean(vals);
        wx(ai) = max(vals);
        if numel(vals) > 1
            sd(ai) = std(vals);
        else
            sd(ai) = 0;
        end
    end
    rk = ranks_lower_better(mn);
    for ai = 1:nA
        rows(end+1, :) = {m, algos{ai}, bf(ai), mn(ai), wx(ai), sd(ai), rk(ai)}; %#ok<AGROW>
    end
end
T1 = cell2table(rows, 'VariableNames', ...
    {'Map', 'Algorithm', 'BestFitness', 'MeanFitness', 'WorstFitness', 'StdFitness', 'RankByMean'});
end

function S = build_summary_ranks_fitness(T3_long, maps, algos)
A = nan(numel(algos), numel(maps));
for mi = 1:numel(maps)
    for ai = 1:numel(algos)
        sel = strcmp(T3_long.Map, maps{mi}) & strcmp(T3_long.Algorithm, algos{ai});
        if any(sel)
            A(ai, mi) = T3_long.RankByMean(sel);
        end
    end
end
mean_rk = mean(A, 2, 'omitnan');
fr = competition_rank_best_lowest(mean_rk);
S = table(algos(:), mean_rk, fr, 'VariableNames', {'Algorithm', 'MeanRank_across_maps', 'FinalRank'});
end

function T2 = build_runtime_long_table(T, maps, algos)
rows = cell(0, 4);
for mi = 1:numel(maps)
    m = maps{mi};
    nA = numel(algos);
    rt = nan(nA, 1);
    for ai = 1:nA
        a = algos{ai};
        ix = strcmp(T.Map, m) & strcmp(T.Algorithm, a);
        vals = T.Runtime(ix);
        vals = vals(isfinite(vals));
        if isempty(vals), continue; end
        rt(ai) = mean(vals);
    end
    rk = ranks_lower_better(rt);
    for ai = 1:nA
        rows(end+1, :) = {m, algos{ai}, rt(ai), rk(ai)}; %#ok<AGROW>
    end
end
T2 = cell2table(rows, 'VariableNames', {'Map', 'Algorithm', 'MeanRuntime', 'RankByRuntime'});
end

function S = build_summary_ranks_runtime(T5_long, maps, algos)
A = nan(numel(algos), numel(maps));
for mi = 1:numel(maps)
    for ai = 1:numel(algos)
        sel = strcmp(T5_long.Map, maps{mi}) & strcmp(T5_long.Algorithm, algos{ai});
        if any(sel)
            A(ai, mi) = T5_long.RankByRuntime(sel);
        end
    end
end
mean_rk = mean(A, 2, 'omitnan');
fr = competition_rank_best_lowest(mean_rk);
S = table(algos(:), mean_rk, fr, 'VariableNames', {'Algorithm', 'MeanRank_across_maps', 'FinalRank'});
end

function r = competition_rank_best_lowest(x)
% Mean rank / aggregate score: lower x is better -> Final Rank 1 = best.
x = double(x(:));
n = numel(x);
r = nan(n, 1);
ok = isfinite(x);
if ~any(ok), return; end
xi = x(ok);
[sorted, ord] = sort(xi);
m = numel(sorted);
pr = nan(m, 1);
i = 1;
while i <= m
    j = i;
    while j <= m && abs(sorted(j) - sorted(i)) <= 1e-9 * max(1, abs(sorted(i)))
        j = j + 1;
    end
    pr(i:j-1) = i; % competition rank "1224"
    i = j;
end
rank_vec = nan(m, 1);
rank_vec(ord) = pr;
ix = find(ok);
r(ix) = rank_vec;
end

function r = ranks_lower_better(x)
% Lower value -> better rank 1. Ties -> average rank. NaN stays NaN.
x = double(x(:));
n = numel(x);
r = nan(n, 1);
ixf = find(isfinite(x));
if isempty(ixf), return; end
xs = x(ixf);
[sorted, ord] = sort(xs);
pr = tiedrank_asc(sorted);
r(ixf(ord)) = pr;
end

function pr = tiedrank_asc(sorted)
m = numel(sorted);
pr = nan(m, 1);
i = 1;
while i <= m
    j = i;
    while j <= m && abs(sorted(j) - sorted(i)) <= 1e-9 * max(1, abs(sorted(i)))
        j = j + 1;
    end
    pr(i:j-1) = mean(i:(j-1));
    i = j;
end
end

%% --- LaTeX wide tables (booktabs, no vertical rules) ---
function tex = latex_table_fitness_wide(T1, T1sum, maps, algos, our_algo)
na = numel(algos);
colspec = ['l l ', repmat('c ', 1, na)];
lines = {
    '% Requires: \\usepackage{booktabs,multirow}'
    ['\\begin{tabular}{@{}', strtrim(colspec), '@{}}']
    '\\toprule'
    };
header = {'Map No.', 'Metrics'};
for ai = 1:na
    if strcmp(algos{ai}, our_algo)
        header{end+1} = ['\\textbf{', escape_tex(algos{ai}), '}']; %#ok<AGROW>
    else
        header{end+1} = escape_tex(algos{ai}); %#ok<AGROW>
    end
end
lines{end+1} = catcell_row(header);
lines{end+1} = '\\midrule';

labels = {'Best', 'Mean', 'Worst', 'Std', 'Rank'};
fields = {'BestFitness', 'MeanFitness', 'WorstFitness', 'StdFitness', 'RankByMean'};
nDec = [3, 3, 3, 3, 2];

for mi = 1:numel(maps)
    m = maps{mi};
    for li = 1:numel(labels)
        row = cell(1, 2 + na);
        if li == 1
            row{1} = ['\\multirow{5}{*}{', m, '}'];
        else
            row{1} = '';
        end
        row{2} = labels{li};
        for ai = 1:na
            v = fitness_pick(T1, m, algos{ai}, fields{li});
            bold = strcmp(algos{ai}, our_algo);
            row{2+ai} = fmt_tex_num(v, nDec(li), bold);
        end
        lines{end+1} = catcell_row(row); %#ok<AGROW>
    end
    if mi < numel(maps)
        lines{end+1} = '\\addlinespace[2pt]';
        lines{end+1} = ['\\cmidrule(lr){1-' num2str(2 + na) '}'];
    end
end
lines{end+1} = '\\midrule';
% Footer: Mean Rank, Final Rank (by mean fitness across maps)
sumrow = cell(1, 2 + na);
sumrow{1} = '';
sumrow{2} = 'Mean Rank';
for ai = 1:na
    v = summary_pick(T1sum, algos{ai}, 'MeanRank_across_maps');
    sumrow{2+ai} = fmt_tex_num(v, 2, strcmp(algos{ai}, our_algo));
end
lines{end+1} = catcell_row(sumrow);
sumrow2 = cell(1, 2 + na);
sumrow2{1} = '';
sumrow2{2} = 'Final Rank';
for ai = 1:na
    v = summary_pick(T1sum, algos{ai}, 'FinalRank');
    sumrow2{2+ai} = fmt_tex_rank_int(v, strcmp(algos{ai}, our_algo));
end
lines{end+1} = catcell_row(sumrow2);

lines{end+1} = '\\bottomrule';
lines{end+1} = '\\end{tabular}';

tex = sprintf('%s\n', lines{:});
end

function tex = latex_table_runtime_wide(T2, T2sum, maps, algos, our_algo)
na = numel(algos);
colspec = ['l l ', repmat('c ', 1, na)];
lines = {
    '% Requires: \\usepackage{booktabs,multirow}'
    ['\\begin{tabular}{@{}', strtrim(colspec), '@{}}']
    '\\toprule'
    };
header = {'Map No.', 'Metrics'};
for ai = 1:na
    if strcmp(algos{ai}, our_algo)
        header{end+1} = ['\\textbf{', escape_tex(algos{ai}), '}']; %#ok<AGROW>
    else
        header{end+1} = escape_tex(algos{ai}); %#ok<AGROW>
    end
end
lines{end+1} = catcell_row(header);
lines{end+1} = '\\midrule';

for mi = 1:numel(maps)
    m = maps{mi};
    for li = 1:2
        row = cell(1, 2 + na);
        if li == 1
            row{1} = ['\\multirow{2}{*}{', m, '}'];
        else
            row{1} = '';
        end
        if li == 1
            row{2} = 'Time';
        else
            row{2} = 'Rank';
        end
        for ai = 1:na
            if li == 1
                v = runtime_pick(T2, m, algos{ai}, 'MeanRuntime');
            else
                v = runtime_pick(T2, m, algos{ai}, 'RankByRuntime');
            end
            bold = strcmp(algos{ai}, our_algo);
            if li == 1
                row{2+ai} = fmt_tex_num(v, 2, bold);
            else
                row{2+ai} = fmt_tex_num(v, 2, bold);
            end
        end
        lines{end+1} = catcell_row(row); %#ok<AGROW>
    end
    if mi < numel(maps)
        lines{end+1} = '\\addlinespace[2pt]';
        lines{end+1} = ['\\cmidrule(lr){1-' num2str(2 + na) '}'];
    end
end
lines{end+1} = '\\midrule';
sumrow = cell(1, 2 + na);
sumrow{1} = '';
sumrow{2} = 'Mean Rank';
for ai = 1:na
    v = summary_pick(T2sum, algos{ai}, 'MeanRank_across_maps');
    sumrow{2+ai} = fmt_tex_num(v, 2, strcmp(algos{ai}, our_algo));
end
lines{end+1} = catcell_row(sumrow);
sumrow2 = cell(1, 2 + na);
sumrow2{1} = '';
sumrow2{2} = 'Final Rank';
for ai = 1:na
    v = summary_pick(T2sum, algos{ai}, 'FinalRank');
    sumrow2{2+ai} = fmt_tex_rank_int(v, strcmp(algos{ai}, our_algo));
end
lines{end+1} = catcell_row(sumrow2);
lines{end+1} = '\\bottomrule';
lines{end+1} = '\\end{tabular}';

tex = sprintf('%s\n', lines{:});
end

function v = summary_pick(tbl, algo, field)
ix = strcmp(tbl.Algorithm, algo);
if ~any(ix), v = nan; return; end
v = tbl.(field)(find(ix, 1));
end

function v = fitness_pick(T1, m, algo, field)
sel = strcmp(T1.Map, m) & strcmp(T1.Algorithm, algo);
if ~any(sel), v = nan; return; end
v = T1.(field)(find(sel, 1));
end

function v = runtime_pick(T2, m, algo, field)
sel = strcmp(T2.Map, m) & strcmp(T2.Algorithm, algo);
if ~any(sel), v = nan; return; end
v = T2.(field)(find(sel, 1));
end

function s = fmt_tex_num(v, nd, bold)
if isempty(v) || ~isfinite(v)
    s = '---';
else
    if nd == 2
        s = sprintf('%.2f', v);
    elseif nd == 3
        s = sprintf('%.3f', v);
    else
        s = sprintf(['%.' int2str(nd) 'f'], v);
    end
end
if bold
    s = ['\\textbf{', s, '}'];
end
end

function s = fmt_tex_rank_int(v, bold)
if isempty(v) || ~isfinite(v)
    s = '---';
else
    s = sprintf('%d', round(double(v)));
end
if bold
    s = ['\\textbf{', s, '}'];
end
end

function s = catcell_row(cells)
for k = 1:numel(cells)
    if isempty(cells{k}), cells{k} = ''; end
end
s = strjoin(cells, ' & ');
s = [s, ' \\'];
end

function s = escape_tex(s)
s = strrep(s, '_', '\\_');
s = strrep(s, '%', '\\%');
end

function write_text(path_str, txt)
fid = fopen(path_str, 'w');
if fid < 0, error('Cannot write %s', path_str); end
try
    fwrite(fid, txt, 'char');
finally
    fclose(fid);
end
end
