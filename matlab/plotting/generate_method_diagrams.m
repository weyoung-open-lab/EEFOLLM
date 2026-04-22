function generate_method_diagrams(cfg)
%GENERATE_METHOD_DIAGRAMS Create framework/module/encoding/behavior diagrams.
fig_dir = fullfile(cfg.paths.figures, 'method_diagrams');
ensure_dir(fig_dir);

% 1) Overall framework
f1 = figure('Visible', 'off', 'Color', 'w', 'Position', [100 100 1200 300]); axis off;
draw_box([0.03 0.35 0.16 0.3], 'Map Generation/Load');
draw_box([0.23 0.35 0.16 0.3], 'Feature Extraction');
draw_box([0.43 0.35 0.16 0.3], 'Qwen Weight Generation');
draw_box([0.63 0.35 0.16 0.3], 'SFO Optimization');
draw_box([0.83 0.35 0.14 0.3], 'Results & Plots');
draw_arrow([0.19 0.50], [0.23 0.50]);
draw_arrow([0.39 0.50], [0.43 0.50]);
draw_arrow([0.59 0.50], [0.63 0.50]);
draw_arrow([0.79 0.50], [0.83 0.50]);
title('Overall Framework Flowchart');
exportgraphics(f1, fullfile(fig_dir, 'overall_framework_flowchart.png'), 'Resolution', cfg.plot.dpi);
savefig(f1, fullfile(fig_dir, 'overall_framework_flowchart.fig')); close(f1);

% 2) LLM reward module
f2 = figure('Visible', 'off', 'Color', 'w'); axis off;
draw_box([0.08 0.35 0.22 0.3], 'Map Features JSON');
draw_box([0.39 0.35 0.22 0.3], 'Qwen/Mock Generator');
draw_box([0.70 0.35 0.22 0.3], 'Stage Weights JSON');
draw_arrow([0.30 0.50], [0.39 0.50]); draw_arrow([0.61 0.50], [0.70 0.50]);
title('LLM Reward-Shaping Module');
exportgraphics(f2, fullfile(fig_dir, 'llm_reward_module.png'), 'Resolution', cfg.plot.dpi);
savefig(f2, fullfile(fig_dir, 'llm_reward_module.fig')); close(f2);

% 3) Path encoding diagram
f3 = figure('Visible', 'off', 'Color', 'w'); hold on; axis equal; grid on;
x = 1:7; y = [1, 2.2, 1.5, 2.8, 2.1, 3.0, 3.5];
plot(x, y, '-o', 'LineWidth', 1.8, 'MarkerFaceColor', 'w');
labels = {'Start','W1','W2','W3','W4','W5','Goal'};
for i = 1:numel(labels), text(x(i)+0.03, y(i)+0.08, labels{i}); end
title('Path Encoding: Start + 5 Waypoints + Goal'); xlabel('X'); ylabel('Y');
exportgraphics(f3, fullfile(fig_dir, 'path_encoding_diagram.png'), 'Resolution', cfg.plot.dpi);
savefig(f3, fullfile(fig_dir, 'path_encoding_diagram.fig')); close(f3);

% 4) SFO behavior illustration
f4 = figure('Visible', 'off', 'Color', 'w', 'Position', [100 100 900 700]);
tiledlayout(2,2);
nexttile; hold on; plot(rand(1,10), rand(1,10), 'o-'); title('Fast Swimming'); grid on;
nexttile; hold on; th = linspace(0,2*pi,30); plot(0.5+0.2*cos(th),0.5+0.2*sin(th),'-'); title('Gathering'); axis equal; grid on;
nexttile; hold on; plot(randn(1,20), randn(1,20), '.-'); title('Dispersal'); grid on;
nexttile; hold on; quiver(0,0,1,0,0); quiver(0,0,0,1,0); title('Escape'); axis([-1.2 1.2 -1.2 1.2]); axis equal; grid on;
sgtitle('SFO Behavior Illustration');
exportgraphics(f4, fullfile(fig_dir, 'sfo_behavior_illustration.png'), 'Resolution', cfg.plot.dpi);
savefig(f4, fullfile(fig_dir, 'sfo_behavior_illustration.fig')); close(f4);
end

function draw_box(pos, txt)
annotation('rectangle', pos, 'LineWidth', 1.2);
annotation('textbox', pos, 'String', txt, 'EdgeColor', 'none', ...
    'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle');
end

function draw_arrow(p1, p2)
annotation('arrow', [p1(1), p2(1)], [p1(2), p2(2)], 'LineWidth', 1.2);
end
