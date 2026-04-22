function plot_convergence(curves_map, save_path, title_str, cfg)
%PLOT_CONVERGENCE Plot convergence curves for multiple algorithms.
algos = fieldnames(curves_map);
f = figure('Visible', 'off', 'Color', 'w'); hold on;
for i = 1:numel(algos)
    c = curves_map.(algos{i});
    if isempty(c), continue; end
    if ismatrix(c) && size(c, 1) > 1
        y = mean(c, 1, 'omitnan');
    else
        y = c(:)';
    end
    plot(y, 'LineWidth', cfg.plot.line_width, 'DisplayName', algos{i});
end
xlabel('Iteration'); ylabel('Best Fitness');
title(title_str); legend('Location', 'best'); grid on;
set(gca, 'FontName', cfg.plot.font_name, 'FontSize', cfg.plot.font_size);
exportgraphics(f, [save_path, '.png'], 'Resolution', cfg.plot.dpi);
savefig(f, [save_path, '.fig']);
close(f);
end
