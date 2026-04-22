function S = compute_smoothness(path_pts)
%COMPUTE_SMOOTHNESS Smoothness penalty using direction cosine changes.
S = 0;
for i = 2:size(path_pts, 1) - 1
    v1 = path_pts(i, :) - path_pts(i - 1, :);
    v2 = path_pts(i + 1, :) - path_pts(i, :);
    n1 = norm(v1); n2 = norm(v2);
    if n1 < eps || n2 < eps
        continue;
    end
    c = max(-1, min(1, dot(v1, v2) / (n1 * n2)));
    S = S + (1 - c);
end
end
