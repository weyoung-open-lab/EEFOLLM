function w = normalize_weights(w, clip_min, clip_max)
%NORMALIZE_WEIGHTS Clip and normalize reward weights to sum 1.
if nargin < 2, clip_min = 0.05; end
if nargin < 3, clip_max = 0.85; end
keys = {'wL', 'wC', 'wS', 'wT'};
vals = zeros(1, 4);
for i = 1:4
    vals(i) = max(clip_min, min(clip_max, double(w.(keys{i}))));
end
vals = vals / max(sum(vals), eps);
for i = 1:4
    w.(keys{i}) = vals(i);
end
end
