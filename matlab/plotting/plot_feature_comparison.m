function plot_feature_comparison(feature_tbl, save_base, cfg)
%PLOT_FEATURE_COMPARISON Visualize map complexity features.
f = figure('Visible', 'off', 'Color', 'w', 'Position', [100 100 1200 700]);
vars = {'obstacle_density','narrow_corridor_ratio','turning_difficulty_score','clutter_score'};
for i = 1:numel(vars)
    subplot(2,2,i);
    bar(categorical(feature_tbl.map_name), feature_tbl.(vars{i}));
    title(vars{i}); grid on;
end
sgtitle('Map Complexity Feature Comparison');
exportgraphics(f, [save_base, '.png'], 'Resolution', cfg.plot.dpi);
savefig(f, [save_base, '.fig']);
close(f);
end
