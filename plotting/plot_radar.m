function plot_radar(metric_table, save_path, title_str, cfg)
%PLOT_RADAR Radar chart for normalized aggregated metrics.
algos = metric_table.Algorithm;
vals = [metric_table.SR, metric_table.InvBestFit, metric_table.InvRuntime, ...
    metric_table.InvPathLength, metric_table.InvSmoothness];
labels = {'SR', '1/BestFit', '1/Runtime', '1/PathLen', '1/Smooth'};
nAxis = size(vals, 2);
theta = linspace(0, 2*pi, nAxis + 1);

f = figure('Visible', 'off', 'Color', 'w');
ax = polaraxes; hold(ax, 'on');
for i = 1:size(vals, 1)
    r = [vals(i, :), vals(i, 1)];
    polarplot(ax, theta, r, 'LineWidth', 1.6, 'DisplayName', algos{i});
end
ax.ThetaTick = rad2deg(theta(1:end-1));
ax.ThetaTickLabel = labels;
title(title_str);
legend('Location', 'bestoutside');
set(ax, 'FontName', cfg.plot.font_name, 'FontSize', cfg.plot.font_size);
exportgraphics(f, [save_path, '.png'], 'Resolution', cfg.plot.dpi);
savefig(f, [save_path, '.fig']);
close(f);
end
