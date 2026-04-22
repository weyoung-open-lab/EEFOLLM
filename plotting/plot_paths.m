function plot_paths(map_data, paths_struct, save_path, title_str, cfg)
%PLOT_PATHS Overlay best paths of algorithms on map.
f = figure('Visible', 'off', 'Color', 'w');
imagesc(1 - map_data.grid); axis equal tight; colormap(gray(2)); hold on;
set(gca, 'YDir', 'normal');
plot(map_data.start(1), map_data.start(2), 'go', 'MarkerSize', 9, 'LineWidth', 2);
plot(map_data.goal(1), map_data.goal(2), 'ro', 'MarkerSize', 9, 'LineWidth', 2);

algos = fieldnames(paths_struct);
for i = 1:numel(algos)
    p = paths_struct.(algos{i});
    if isempty(p), continue; end
    plot(p(:, 1), p(:, 2), '-', 'LineWidth', 1.5, 'DisplayName', algos{i});
end
title(title_str); xlabel('X'); ylabel('Y');
legend('Location', 'bestoutside'); grid on;
set(gca, 'FontName', cfg.plot.font_name, 'FontSize', cfg.plot.font_size);
exportgraphics(f, [save_path, '.png'], 'Resolution', cfg.plot.dpi);
savefig(f, [save_path, '.fig']);
close(f);
end
