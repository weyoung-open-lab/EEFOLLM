function plot_paper_benchmark10(cfg, tbl, out_dir)
%PLOT_PAPER_BENCHMARK10 Bar / heatmap figures: 9 recent baselines + EEFOLLM from long-format table.
%   tbl: table with Map, Algorithm, MedianBestFit, MeanCollisionFreeRate, MeanBestFit, etc.
%   Expects paper_benchmark_algorithms10 names.

if nargin < 3 || isempty(out_dir)
    out_dir = fullfile(cfg.paths.figures, 'paper_benchmark_10');
end
if ~isfolder(out_dir)
    mkdir(out_dir);
end

[bench10, ~] = paper_benchmark_algorithms10();
nA = numel(bench10);
maps = cellstr(string(cfg.maps.names(:)));

our_name = 'EEFOLLM';
our_rgb = [0.85 0.33 0.18];
base_rgb = [0.35 0.45 0.65];

% Median BestFit matrix: rows = map, cols = algorithm order
Mmed = nan(numel(maps), nA);
Mmean = Mmed;
Mcfr = Mmed;
for mi = 1:numel(maps)
    for ai = 1:nA
        sel = strcmp(string(tbl.Map), maps{mi}) & strcmp(string(tbl.Algorithm), bench10{ai});
        if any(sel)
            Mmed(mi, ai) = tbl.MedianBestFit(find(sel, 1));
            Mmean(mi, ai) = tbl.MeanBestFit(find(sel, 1));
            Mcfr(mi, ai) = tbl.MeanCollisionFreeRate(find(sel, 1));
        end
    end
end

% ----- Figure 1: grouped bars — one subplot per map, Median BestFit -----
f1 = figure('Visible', 'off', 'Color', 'w', 'Position', [40 40 1400 900]);
tiledlayout(f1, 2, 3, 'Padding', 'compact', 'TileSpacing', 'compact');
for mi = 1:numel(maps)
    nexttile;
    x = categorical(bench10, bench10, 'Ordinal', true);
    h = bar(x, Mmed(mi, :), 'FaceColor', 'flat');
    col = repmat(base_rgb, nA, 1);
    ix = strcmp(bench10, our_name);
    col(ix, :) = repmat(our_rgb, sum(ix), 1);
    h.CData = col;
    ylabel('Median BestFit');
    title(sprintf('%s', maps{mi}), 'Interpreter', 'none');
    grid on;
    yline(Mmed(mi, ix), '--', 'Color', our_rgb * 0.75, 'LineWidth', 0.8);
    set(gca, 'XTickLabelRotation', 35);
end
nexttile;
axis off;
text(0.1, 0.5, {'9 recent baselines (color) vs EEFOLLM (highlight).', ...
    'Dashed line: EEFOLLM median on same map.'}, 'FontSize', 11);
sgtitle(f1, 'Median BestFit by Map (20 runs each)');
exportgraphics(f1, fullfile(out_dir, 'median_bestfit_bar_per_map.png'), 'Resolution', cfg.plot.dpi);
savefig(f1, fullfile(out_dir, 'median_bestfit_bar_per_map.fig'));
close(f1);

% ----- Figure 2: heatmap Median BestFit (maps x algorithms) -----
f2 = figure('Visible', 'off', 'Color', 'w', 'Position', [80 80 1000 500]);
imagesc(Mmed);
set(gca, 'XTick', 1:nA, 'XTickLabel', bench10, 'XTickLabelRotation', 35);
set(gca, 'YTick', 1:numel(maps), 'YTickLabel', maps);
colorbar;
xlabel('Algorithm');
ylabel('Map');
title('Median BestFit (heatmap; lower greener with default colormap)');
colormap(f2, parula);
set(gca, 'FontSize', cfg.plot.font_size);
exportgraphics(f2, fullfile(out_dir, 'median_bestfit_heatmap.png'), 'Resolution', cfg.plot.dpi);
savefig(f2, fullfile(out_dir, 'median_bestfit_heatmap.fig'));
close(f2);

% ----- Figure 3: Mean Collision-Free Rate -----
f3 = figure('Visible', 'off', 'Color', 'w', 'Position', [40 40 1400 900]);
tiledlayout(f3, 2, 3, 'Padding', 'compact', 'TileSpacing', 'compact');
for mi = 1:numel(maps)
    nexttile;
    x = categorical(bench10, bench10, 'Ordinal', true);
    h = bar(x, Mcfr(mi, :), 'FaceColor', 'flat');
    col = repmat(base_rgb, nA, 1);
    ix = strcmp(bench10, our_name);
    col(ix, :) = repmat(our_rgb, sum(ix), 1);
    h.CData = col;
    ylabel('Mean collision-free rate');
    ylim([0 1.05]);
    title(sprintf('%s', maps{mi}), 'Interpreter', 'none');
    grid on;
    set(gca, 'XTickLabelRotation', 35);
end
nexttile;
axis off;
text(0.1, 0.5, 'Collision-free rate: fraction of runs with feasible path (no hard collision).');
sgtitle(f3, 'Mean Collision-Free Rate by Map');
exportgraphics(f3, fullfile(out_dir, 'collision_free_rate_bar_per_map.png'), 'Resolution', cfg.plot.dpi);
savefig(f3, fullfile(out_dir, 'collision_free_rate_bar_per_map.fig'));
close(f3);

fprintf(1, 'paper_benchmark_10 figures written to: %s\n', out_dir);
end
