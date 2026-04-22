function varargout = generate_friedman_table(opts)
%GENERATE_FRIEDMAN_TABLE 生成论文 Table 4 风格「Friedman 非参数检验 / 平均秩」表。
%
%   数据: 10 算法 x 5 图 x 每图 20 次 BestFit（与 generate_main_tables 同源 records）。
%   每张图: 对每个 run（行）在 10 个算法间按 fitness 升序赋秩（越小越好，并列平均秩），
%   再对行取平均 -> Friedman Rank（与经典 Friedman 检验中使用的秩结构一致）。
%   可选: 对完整行调用 MATLAB friedman 输出 p 值写入日志（需 Statistics Toolbox）。
%
%   输出: results/tables/paper_main/
%     - table4_friedman_wide.csv
%     - table4_friedman_wide.tex   （booktabs；EEFOLLM 列加粗）
%     - friedman_table.mat         （FriedmanRank, RankInt, MeanFriedmanRank, FinalRank, p_map, ...）
%     - friedman_generation_log.txt
%
%   用法: generate_friedman_table
%         generate_friedman_table(struct('expected_runs',20))

if nargin < 1, opts = struct(); end
if ~isfield(opts, 'expected_runs'), opts.expected_runs = 20; end
if ~isfield(opts, 'out_subdir'), opts.out_subdir = 'paper_main'; end
if ~isfield(opts, 'records_csv'), opts.records_csv = ''; end

root_dir = fileparts(mfilename('fullpath'));
addpath(root_dir);
addpath(fullfile(root_dir, 'config'));
addpath(fullfile(root_dir, 'utils'));
init_paths(root_dir);

cfg = default_config();
[algo_list, ~] = paper_benchmark_algorithms10();
maps = cfg.maps.names(:);
if isstring(maps), maps = cellstr(maps); end
our_algo = 'EEFOLLM';
na = numel(algo_list);

out_dir = fullfile(cfg.paths.results, 'tables', opts.out_subdir);
ensure_dir(out_dir);
log_path = fullfile(out_dir, 'friedman_generation_log.txt');
logfid = fopen(log_path, 'w');
cleanup = onCleanup(@() fclose(logfid));

fprintf(logfid, '=== generate_friedman_table %s ===\n', datestr(now, 31));
fprintf(1, 'Friedman table output: %s\n', out_dir);

T = load_records_table(opts, cfg, logfid);
T = normalize_algorithm_column(T);
T.Algorithm = cellstr(string(T.Algorithm));
T.Map = cellstr(string(T.Map));

exp_maps = maps(:);
exp_algos = algo_list(:);
T = T(ismember(string(T.Map), string(exp_maps)) & ismember(string(T.Algorithm), string(exp_algos)), :);

FriedmanRank = nan(numel(exp_maps), na);
RankInt = nan(numel(exp_maps), na);
p_map = nan(numel(exp_maps), 1);
n_rows_used = nan(numel(exp_maps), 1);

for mi = 1:numel(exp_maps)
    m = exp_maps{mi};
    [M, pval, nuse] = build_run_matrix_and_friedman(T, m, exp_algos, opts.expected_runs, logfid);
    n_rows_used(mi) = nuse;
    p_map(mi) = pval;
    if isempty(M) || nuse < 1
        fprintf(logfid, 'WARN: Map=%s insufficient data for Friedman ranks.\n', m);
        continue;
    end
    R = rank_rows_lower_better(M);
    FriedmanRank(mi, :) = mean(R, 1, 'omitnan');
    RankInt(mi, :) = competition_rank_vector(FriedmanRank(mi, :)')';
end

MeanFriedmanRank = mean(FriedmanRank, 1, 'omitnan')';
FinalRank = competition_rank_vector(MeanFriedmanRank);

% --- Wide tables for CSV / LaTeX ---
vn = [{'MapNo', 'Metric'}, algo_list(:)'];
rows = cell(0, numel(vn));
for mi = 1:numel(exp_maps)
    rows = [rows; [{exp_maps{mi}, 'Friedman Rank'}, num2cell(FriedmanRank(mi, :))]]; %#ok<AGROW>
    rows = [rows; [{exp_maps{mi}, 'Rank'}, num2cell(RankInt(mi, :))]]; %#ok<AGROW>
end
rows = [rows; [{'', 'Mean Rank'}, num2cell(MeanFriedmanRank(:)')]]; %#ok<AGROW>
rows = [rows; [{'', 'Final Rank'}, num2cell(FinalRank(:)')]]; %#ok<AGROW>

T_wide = cell2table(rows, 'VariableNames', vn);
writetable(T_wide, fullfile(out_dir, 'table4_friedman_wide.csv'));

tex = latex_friedman_wide(exp_maps, algo_list, FriedmanRank, RankInt, MeanFriedmanRank, FinalRank, our_algo);
write_text_out(fullfile(out_dir, 'table4_friedman_wide.tex'), tex);

save(fullfile(out_dir, 'friedman_table.mat'), 'FriedmanRank', 'RankInt', 'MeanFriedmanRank', ...
    'FinalRank', 'exp_maps', 'algo_list', 'p_map', 'n_rows_used', 'opts', '-v7');

fprintf(logfid, '=== finished OK ===\n');
fprintf(1, 'Done. Log: %s\n', log_path);

if nargout > 0
    varargout{1} = T_wide;
end
end

%% --- records ---
function T = load_records_table(opts, cfg, logfid)
T = table();
if ~isempty(opts.records_csv) && isfile(opts.records_csv)
    T = readtable(opts.records_csv, 'TextType', 'string');
    fprintf(logfid, 'Loaded records: %s\n', opts.records_csv);
end
if isempty(T)
    p = fullfile(cfg.paths.results, 'global_experiments_merged', 'tables', 'records_merged.csv');
    if isfile(p)
        T = readtable(p, 'TextType', 'string');
        fprintf(logfid, 'Loaded: %s\n', p);
    end
end
if isempty(T)
    try
        T = merge_global_experiment_batches();
        fprintf(logfid, 'merge_global_experiment_batches OK\n');
    catch ME
        fprintf(logfid, 'merge failed: %s\n', ME.message);
        T = merge_batches_mem(cfg);
    end
end
if isempty(T)
    error('generate_friedman_table:NoData', 'No records found.');
end
end

function T = merge_batches_mem(cfg)
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

function [M, pval, nuse] = build_run_matrix_and_friedman(T, map_name, algos, expected_runs, logfid)
na = numel(algos);
M = nan(expected_runs, na);
for ai = 1:na
    ix = strcmp(T.Map, map_name) & strcmp(T.Algorithm, algos{ai});
    sub = T(ix, :);
    for r = 1:expected_runs
        j = find(double(sub.Run) == r, 1);
        if ~isempty(j)
            M(r, ai) = sub.BestFit(j);
        end
    end
    n = sum(isfinite(M(:, ai)));
    if n ~= expected_runs
        fprintf(logfid, 'WARN: Map=%s Algorithm=%s: expected %d runs, found %d.\n', ...
            map_name, algos{ai}, expected_runs, n);
    end
end
okruns = all(isfinite(M), 2);
Mg = M(okruns, :);
nuse = size(Mg, 1);
pval = nan;
if nuse >= 2 && exist('friedman', 'file') == 2
    try
        pval = friedman(Mg);
        fprintf(logfid, 'Map=%s: friedman p=%.4g (complete rows=%d/%d)\n', map_name, pval, nuse, expected_runs);
    catch ME
        fprintf(logfid, 'Map=%s: friedman failed: %s\n', map_name, ME.message);
    end
else
    fprintf(logfid, 'Map=%s: skipped friedman p (complete rows=%d)\n', map_name, nuse);
end
M = Mg;
end

function R = rank_rows_lower_better(M)
% M: n x k fitness, lower better, rank 1 best per row
[n, k] = size(M);
R = nan(n, k);
for r = 1:n
    R(r, :) = tiedrank_row(M(r, :));
end
end

function r = tiedrank_row(x)
x = double(x(:))';
k = numel(x);
r = nan(1, k);
if any(~isfinite(x)), return; end
[sorted, ord] = sort(x);
pr = tiedrank_sorted(sorted);
r(ord) = pr;
end

function pr = tiedrank_sorted(sorted)
m = numel(sorted);
pr = nan(1, m);
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

function rk = competition_rank_vector(x)
% x: column vector, lower is better -> rank 1 best（并列取同序位，下一名跳过）
x = double(x(:));
n = numel(x);
rk = nan(n, 1);
ok = isfinite(x);
if ~any(ok), return; end
ix = find(ok);
xi = x(ix);
[sorted, ord] = sort(xi);
m = numel(sorted);
pr = nan(m, 1);
i = 1;
while i <= m
    j = i;
    while j <= m && abs(sorted(j) - sorted(i)) <= 1e-9 * max(1, abs(sorted(i)))
        j = j + 1;
    end
    pr(i:j-1) = i;
    i = j;
end
rk(ix(ord)) = pr;
end

function tex = latex_friedman_wide(maps, algos, FR, RI, meanFR, finalR, our_algo)
na = numel(algos);
colspec = ['l l ', repmat('c ', 1, na)];
lines = {
    '% Requires: \\usepackage{booktabs,multirow}'
    ['\\begin{tabular}{@{}', strtrim(colspec), '@{}}']
    '\\toprule'
    };
hdr = [{'Map No.', 'Metrics'}, algos(:)'];
lines{end+1} = cat_row_tex(hdr, algos, our_algo);
lines{end+1} = '\\midrule';

for mi = 1:numel(maps)
    m = maps{mi};
    row1 = cell(1, 2 + na);
    row1{1} = ['\\multirow{2}{*}{', m, '}'];
    row1{2} = 'Friedman Rank';
    for ai = 1:na
        row1{2+ai} = fmt_tex(FR(mi, ai), 2, strcmp(algos{ai}, our_algo));
    end
    lines{end+1} = join_tex_row(row1);
    row2 = cell(1, 2 + na);
    row2{1} = '';
    row2{2} = 'Rank';
    for ai = 1:na
        row2{2+ai} = fmt_tex_int(RI(mi, ai), strcmp(algos{ai}, our_algo));
    end
    lines{end+1} = join_tex_row(row2);
    if mi < numel(maps)
        lines{end+1} = '\\addlinespace[2pt]';
        lines{end+1} = ['\\cmidrule(lr){1-' num2str(2 + na) '}'];
    end
end
lines{end+1} = '\\midrule';
rowm = cell(1, 2 + na);
rowm{1} = '';
rowm{2} = 'Mean Rank';
for ai = 1:na
    rowm{2+ai} = fmt_tex(meanFR(ai), 2, strcmp(algos{ai}, our_algo));
end
lines{end+1} = join_tex_row(rowm);
rowf = cell(1, 2 + na);
rowf{1} = '';
rowf{2} = 'Final Rank';
for ai = 1:na
    rowf{2+ai} = fmt_tex_int(finalR(ai), strcmp(algos{ai}, our_algo));
end
lines{end+1} = join_tex_row(rowf);
lines{end+1} = '\\bottomrule';
lines{end+1} = '\\end{tabular}';
tex = sprintf('%s\n', lines{:});
end

function s = cat_row_tex(hdr, algos, our_algo)
cells = cell(size(hdr));
for i = 1:numel(hdr)
    if i <= 2
        cells{i} = hdr{i};
    else
        ai = i - 2;
        if strcmp(algos{ai}, our_algo)
            cells{i} = ['\\textbf{', escape_tex_l(hdr{i}), '}'];
        else
            cells{i} = escape_tex_l(hdr{i});
        end
    end
end
s = join_tex_row(cells);
end

function s = join_tex_row(cells)
for k = 1:numel(cells)
    if isempty(cells{k}), cells{k} = ''; end
end
s = [strjoin(cells, ' & '), ' \\'];
end

function s = fmt_tex(v, nd, bold)
if ~isfinite(v)
    s = '---';
else
    s = sprintf(['%.' int2str(nd) 'f'], v);
end
if bold
    s = ['\\textbf{', s, '}'];
end
end

function s = fmt_tex_int(v, bold)
if ~isfinite(v)
    s = '---';
else
    s = sprintf('%d', round(double(v)));
end
if bold
    s = ['\\textbf{', s, '}'];
end
end

function s = escape_tex_l(str)
s = strrep(str, '_', '\_');
end

function write_text_out(p, txt)
fid = fopen(p, 'w');
if fid < 0, error('Cannot write %s', p); end
try
    fwrite(fid, txt, 'char');
finally
    fclose(fid);
end
end
