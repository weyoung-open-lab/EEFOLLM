function varargout = generate_algorithm_setting_table(opts)
%GENERATE_ALGORITHM_SETTING_TABLE 生成论文用「对比算法参数表」(Table 2 风格)。
%
%   列: Algorithm | Year | KeyParameters
%       KeyParameters 为简短 LaTeX 数学/文本；统一预算写在单独 notes 文件。
%
%   参数数值来源: config/default_config.m + algorithms/run_*.m 中与实现一致的常量
%   （HO/SBOA 为 paper-inspired simplified 实现，无单独年份字段）。
%
%   输出: results/tables/paper_main/
%     - table2_algorithm_settings.csv
%     - table2_algorithm_settings.tex  （booktabs）
%     - table2_algorithm_settings_notes.txt  （统一 N, T, K 与脚注说明）
%     - algorithm_setting_tables.mat   （变量 T_algo）
%
%   用法: generate_algorithm_setting_table

if nargin < 1, opts = struct(); end
if ~isfield(opts, 'out_subdir'), opts.out_subdir = 'paper_main'; end

root_dir = fileparts(mfilename('fullpath'));
addpath(root_dir);
addpath(fullfile(root_dir, 'config'));
addpath(fullfile(root_dir, 'utils'));
init_paths(root_dir);

cfg = default_config();
[algo_list, ~] = paper_benchmark_algorithms10();

N = cfg.exp.population;
Tmax = cfg.exp.iterations;
K = cfg.path.default_k;
dim = 2 * K;

llm_id = cfg.llm.repo_id;
stage = cfg.stage_split;
oaw = cfg.online_adaptive;

rows = build_rows(cfg, algo_list, N, Tmax, K, dim, llm_id, stage, oaw);

T_algo = cell2table(rows, 'VariableNames', ...
    {'Algorithm', 'Year', 'KeyParameters'});

out_dir = fullfile(cfg.paths.results, 'tables', opts.out_subdir);
ensure_dir(out_dir);
writetable(T_algo, fullfile(out_dir, 'table2_algorithm_settings.csv'));
write_text(fullfile(out_dir, 'table2_algorithm_settings.tex'), latex_algo_table(T_algo));
write_text(fullfile(out_dir, 'table2_algorithm_settings_notes.txt'), ...
    build_unified_notes(N, Tmax, K, dim, cfg));
save(fullfile(out_dir, 'algorithm_setting_tables.mat'), 'T_algo', 'cfg', 'algo_list', '-v7');

fprintf(1, 'Algorithm settings table -> %s\n', out_dir);
fprintf(1, 'Algorithms (%d): %s\n', numel(algo_list), strjoin(algo_list, ', '));
fprintf(1, 'If Year is NA, confirm citation year manually for paper (HO/SBOA simplified; EEFOLLM proposed).\n');

if nargout > 0
    varargout{1} = T_algo;
end
end

function rows = build_rows(cfg, algo_list, N, Tmax, K, dim, llm_id, stage, oaw)
% 每行: {Algorithm, Year, KeyParameters_LaTeX}
rows = cell(numel(algo_list), 3);
for i = 1:numel(algo_list)
    a = algo_list{i};
    switch a
        case 'AOA'
            rows(i, :) = { 'AOA', '2021', ...
                ['$\mathrm{MOP}=1-(t/T)^{1/2}$, $\mathrm{MOA}=\mathrm{MOP}_{\min}+t(\mathrm{MOP}_{\max}-\mathrm{MOP}_{\min})/T$; ', ...
                 '$\mathrm{MOP}_{\max}=1$, $\mathrm{MOP}_{\min}=0.2$.'] };
        case 'EO'
            rows(i, :) = { 'EO', '2020', ...
                ['Equilibrium pool $|C_{\mathrm{eq}}|=4$; $T_{\mathrm{iter}}=\exp(-t/T)$; ', ...
                 '$C$, $G$ update as in \texttt{run\_eo.m}.'] };
        case 'GTO'
            rows(i, :) = { 'GTO', '2020', ...
                'Sharing-vs-gain switch probability $k=0.5$; population sorted each iteration.' };
        case 'HHO'
            rows(i, :) = { 'HHO', '2019', ...
                '$E=2E_0(1-t/T)$; exploration ($|E|\ge 1$) vs.\ exploitation ($|E|<1$) with L''evy-like term.' };
        case 'HO'
            rows(i, :) = { 'HO', '2024', ...
                'River drift vs.\ defensive grouping with prob.\ $0.5$; Gaussian scale $0.1$ on $(\mathbf{ub}-\mathbf{lb})$; grouping coeff.\ $0.3$.' };
        case 'MPA'
            rows(i, :) = { 'MPA', '2020', ...
                ['Three motion phases ($t<T/3$, $T/3\le t<2T/3$, else); ', ...
                 'step $\mathrm{stepsize}=0.05\exp(-(2t/T)^2)$.'] };
        case 'SBOA'
            rows(i, :) = { 'SBOA', '2024', ...
                'High-altitude scan vs.\ ground attack prob.\ $0.5$; scales $0.12$, $0.7$, $0.2$ on $(\mathbf{ub}-\mathbf{lb})$ and mean-based term.' };
        case 'SMA'
            rows(i, :) = { 'SMA', '2020', ...
                'Fitness-weight $W$ via ranked population; update with prob.\ $0.5$ between best-guided and random stretch.' };
        case 'SSA'
            rows(i, :) = { 'SSA', '2020', ...
                ['$\mathrm{PD}=0.2$, $\mathrm{ST}=0.8$; scouts $N_s=\max(2,\lfloor 0.2N\rfloor)$; ', ...
                 'producer/sparrow/scrounger updates as in code.'] };
        case 'EEFOLLM'
            % 勿把 LaTeX 写进 sprintf 格式串：MATLAB 会把 \m、\e 等当成无效转义并警告。
            oaw_note = '';
            if oaw.enable
                oaw_note = ['; OAW every ', sprintf('%d', oaw.every), ...
                    ' iters (frac$\in[', sprintf('%.2f', oaw.frac_low), ',', sprintf('%.2f', oaw.frac_high), ...
                    ']$, $\eta_{\uparrow}=', sprintf('%.2f', oaw.eta_up), '$, $\eta_{\downarrow}=', ...
                    sprintf('%.2f', oaw.eta_down), '$).'];
            else
                oaw_note = '; OAW disabled (\texttt{cfg.online\_adaptive.enable=false}) in default batches.';
            end
            se = sprintf('%.2f', stage.early_end);
            sl = sprintf('%.2f', stage.late_start);
            llm_tex = strrep(llm_id, '_', '\_');
            kp = ['\textbf{EEFO core:} $T_{\mathrm{temp}}=1-t/T$, shock scale $0.08$ on $(\mathbf{ub}-\mathbf{lb})$, ', ...
                'random re-init prob.\ $0.25$; stage split early/mid/late: $[0,', se, ')$, $[', se, ',', sl, ...
                ')$, $[', sl, ',1]$. \textbf{LLM:} per-map stage weights via \texttt{', llm_tex, '}.'];
            kp = [kp, oaw_note];
            rows(i, :) = { 'EEFOLLM', '2026', kp };
        otherwise
            error('Unknown algorithm tag: %s', a);
    end
end
end

function txt = build_unified_notes(N, Tmax, K, dim, cfg)
w = cfg.weights.default;
txt = sprintf([ ...
    'Shared experimental budget (all algorithms unless noted):\n', ...
    '  population N = %d\n', ...
    '  max iterations T_max = %d\n', ...
    '  waypoint count K = %d  =>  search dimension dim = 2K = %d\n', ...
    'Static scalarized fitness weights (baselines using cfg.weights.default): ', ...
    'w_L=%.2f, w_C=%.2f, w_S=%.2f, w_T=%.2f (sum=1).\n', ...
    'EEFOLLM uses LLM-derived stage weights (early/mid/late); see KeyParameters column.\n', ...
    'LLM model id (config): %s\n'], ...
    N, Tmax, K, dim, w.wL, w.wC, w.wS, w.wT, cfg.llm.repo_id);
end

function tex = latex_algo_table(T)
n = height(T);
lines = {
    '% Requires: \usepackage{booktabs,array}'
    '\begin{tabular}{@{}llp{88mm}@{}}'
    '\toprule'
    'Algorithm & Year & Key parameters \\'
    '\midrule'
    };
for i = 1:n
    alg = latex_escape(T.Algorithm{i});
    yr = latex_escape(T.Year{i});
    kp = trim_for_tex(T.KeyParameters{i});
    lines{end+1} = sprintf('%s & %s & %s \\\\', alg, yr, kp); %#ok<AGROW>
end
lines{end+1} = '\bottomrule';
lines{end+1} = '\end{tabular}';
tex = sprintf('%s\n', lines{:});
end

function s = trim_for_tex(str)
s = strtrim(str);
s = strrep(s, '%', '\%');
end

function s = latex_escape(str)
s = strtrim(str);
s = strrep(s, '_', '\_');
s = strrep(s, '%', '\%');
s = strrep(s, '&', '\&');
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
