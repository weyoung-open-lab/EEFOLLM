function plot_maps(map_data, save_path, cfg)
%PLOT_MAPS Visualize occupancy map with start/goal.
if nargin < 3 || isempty(cfg)
    cfg.font_name = 'Arial';
    cfg.font_size = 11;
end

f = figure('Visible', 'off', 'Color', 'w');
imagesc(1 - map_data.grid);
axis equal tight;
colormap(gray(2));
hold on;
plot(map_data.start(1), map_data.start(2), 'go', 'MarkerSize', 8, 'LineWidth', 2);
plot(map_data.goal(1), map_data.goal(2), 'ro', 'MarkerSize', 8, 'LineWidth', 2);
title(sprintf('%s (%dx%d)', map_data.name, map_data.size(1), map_data.size(2)));
set(gca, 'YDir', 'normal', 'FontName', cfg.font_name, 'FontSize', cfg.font_size);
xlabel('X'); ylabel('Y');
legend({'Start', 'Goal'}, 'Location', 'best');
hold off;

if ~isempty(save_path)
    [folder, ~, ext] = fileparts(save_path);
    if ~exist(folder, 'dir'), mkdir(folder); end
    if isempty(ext), save_path = [save_path, '.png']; end
    exportgraphics(f, save_path, 'Resolution', 200);
    savefig(f, strrep(save_path, '.png', '.fig'));
end
close(f);
end
