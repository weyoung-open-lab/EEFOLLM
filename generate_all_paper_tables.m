function generate_all_paper_tables()
%GENERATE_ALL_PAPER_TABLES 一键生成论文主文全部表格（按编号）:
%   Table 1 — 地图设定: generate_map_setting_table
%   Table 2 — 对比算法参数: generate_algorithm_setting_table
%   Table 3 — 适应度主结果: generate_main_tables
%   Table 4 — Friedman 非参数检验 / 平均秩: generate_friedman_table
%   Table 5 — 运行时间: 同上（与 Table 3 同次写出）
%
%   在工程根目录执行: generate_all_paper_tables

root_dir = fileparts(mfilename('fullpath'));
addpath(root_dir);

fprintf(1, '--- Table 1: map settings ---\n');
generate_map_setting_table();

fprintf(1, '--- Table 2: algorithm parameters ---\n');
generate_algorithm_setting_table();

fprintf(1, '--- Tables 3 & 5: fitness + runtime ---\n');
generate_main_tables();

fprintf(1, '--- Table 4: Friedman ranks ---\n');
generate_friedman_table();

fprintf(1, 'Done. See folder: results/tables/paper_main/\n');
fprintf(1, '  table1_map_settings.*        (map / benchmark description)\n');
fprintf(1, '  table2_algorithm_settings.*  (algorithm parameters)\n');
fprintf(1, '  table3_fitness_*             (main results)\n');
fprintf(1, '  table4_friedman_*            (Friedman ranks)\n');
fprintf(1, '  table5_runtime_*             (runtime)\n');
fprintf(1, '  paper_main_tables.mat / map_setting_tables.mat / algorithm_setting_tables.mat\n');
end
