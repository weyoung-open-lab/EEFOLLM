function pts = decode_path(x, map_data)
%DECODE_PATH Convert optimization vector to full path points.
%   x: 1 x (2K) vector for waypoint coordinates.

k = numel(x) / 2;
mid = reshape(x, 2, k)';
mid(:, 1) = max(1, min(map_data.size(2), mid(:, 1)));
mid(:, 2) = max(1, min(map_data.size(1), mid(:, 2)));

pts = [map_data.start; mid; map_data.goal];
end
