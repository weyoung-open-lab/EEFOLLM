function plot_weight_bars(stage_weights, save_path, title_str, cfg)
%PLOT_WEIGHT_BARS Plot stage-wise reward weights.
stages = {'early', 'mid', 'late'};
keys = {'wL', 'wC', 'wS', 'wT'};
W = zeros(3, 4);
for i = 1:3
    s = stage_weights.(stages{i});
    for j = 1:4
        W(i, j) = s.(keys{j});
    end
end

f = figure('Visible', 'off', 'Color', 'w');
bar(W, 'grouped');
set(gca, 'XTickLabel', stages, 'FontName', cfg.plot.font_name, 'FontSize', cfg.plot.font_size);
legend(keys, 'Location', 'best');
ylabel('Weight'); title(title_str); grid on;
exportgraphics(f, [save_path, '.png'], 'Resolution', cfg.plot.dpi);
savefig(f, [save_path, '.fig']);
close(f);
end
