function L = compute_length(path_pts)
%COMPUTE_LENGTH Total polyline length.
seg = diff(path_pts, 1, 1);
L = sum(sqrt(sum(seg.^2, 2)));
end
