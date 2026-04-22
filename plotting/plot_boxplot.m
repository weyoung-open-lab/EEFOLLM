function plot_boxplot(data_mat, labels, save_path, title_str, ylab, cfg)
%PLOT_BOXPLOT Generic boxplot wrapper.
f = figure('Visible', 'off', 'Color', 'w');
boxplot(data_mat, labels, 'LabelOrientation', 'inline');
title(title_str); ylabel(ylab); grid on;
set(gca, 'FontName', cfg.plot.font_name, 'FontSize', cfg.plot.font_size);
exportgraphics(f, [save_path, '.png'], 'Resolution', cfg.plot.dpi);
savefig(f, [save_path, '.fig']);
close(f);
end
