function main_generate_ablation_result()
%MAIN_GENERATE_ABLATION_RESULT 一键生成 results/ablation_result 下表格、箱线图（Python）与收敛图（MATLAB，需 mat）。
%
%   步骤 1（必须，调 Python）:
%     在项目根目录执行:  python scripts/export_ablation_result.py
%     或在本函数中自动调用（需系统 PATH 中有 python）。
%
%   步骤 2（可选，需曲线数据）:
%     main_plot_ablation_convergence
%
%   输出目录: results/ablation_result/tables/ 与 figures/

root_dir = fileparts(mfilename('fullpath'));
py_script = fullfile(root_dir, 'scripts', 'export_ablation_result.py');
if isfile(py_script)
    fprintf(1, 'Running Python: %s\n', py_script);
    [st, echoed] = system(sprintf('python "%s"', py_script));
    fprintf(1, '%s', echoed);
    if st ~= 0
        warning('Python export returned %d — run manually: python scripts/export_ablation_result.py', st);
    end
else
    warning('Missing %s', py_script);
end

try
    main_plot_ablation_convergence();
catch ME
    warning('Convergence plot skipped: %s', ME.message);
end
end
