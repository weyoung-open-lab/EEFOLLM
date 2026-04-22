function plot_all_maps_overview(map_list, save_base, cfg)
%PLOT_ALL_MAPS_OVERVIEW Plot all benchmark maps in one figure.
f = figure('Visible', 'off', 'Color', 'w', 'Position', [100 100 1400 800]);
for i = 1:numel(map_list)
    subplot(2, 3, i);
    imagesc(1 - map_list{i}.grid); axis equal tight; colormap(gray(2));
    set(gca, 'YDir', 'normal');
    hold on;
    plot(map_list{i}.start(1), map_list{i}.start(2), 'go', 'MarkerSize', 7, 'LineWidth', 1.8);
    plot(map_list{i}.goal(1), map_list{i}.goal(2), 'ro', 'MarkerSize', 7, 'LineWidth', 1.8);
    title(map_list{i}.name);
    hold off;
end
sgtitle('Benchmark Maps with Start/Goal');
exportgraphics(f, [save_base, '.png'], 'Resolution', cfg.plot.dpi);
savefig(f, [save_base, '.fig']);
close(f);
end
