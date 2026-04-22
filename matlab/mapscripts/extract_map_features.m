function feat = extract_map_features(map_data, out_json_path)
%EXTRACT_MAP_FEATURES Compute 9 complexity features for LLM input.
repo = fileparts(fileparts(fileparts(mfilename('fullpath'))));
addpath(fullfile(repo, 'matlab', 'utils'));
G = map_data.grid;
free = (G == 0);
obs = (G == 1);
[rows, cols] = size(G);

feat.map_name = map_data.name;
feat.obstacle_density = nnz(obs) / numel(G);
feat.free_space_ratio = nnz(free) / numel(G);

CC = local_conncomp(free, 4);
feat.connected_free_regions = CC.NumObjects;

free_dist = local_bwdist(obs);
corridor_mask = free & (free_dist <= 3);
feat.avg_corridor_width_est = 2 * mean(free_dist(free), 'omitnan');
feat.narrow_corridor_ratio = nnz(corridor_mask) / max(nnz(free), 1);

obs_cc = local_conncomp(obs, 4);
feat.num_obstacle_blocks = obs_cc.NumObjects;
if obs_cc.NumObjects > 0
    block_sizes = cellfun(@numel, obs_cc.PixelIdxList);
    feat.avg_obstacle_block_size = mean(block_sizes);
else
    feat.avg_obstacle_block_size = 0;
end

function CC = local_conncomp(BW, conn)
if nargin < 2, conn = 4; end
[rows, cols] = size(BW);
visited = false(rows, cols);
pixel_lists = {};
if conn == 8
    dirs = [1 0; -1 0; 0 1; 0 -1; 1 1; 1 -1; -1 1; -1 -1];
else
    dirs = [1 0; -1 0; 0 1; 0 -1];
end

for r = 1:rows
    for c = 1:cols
        if ~BW(r, c) || visited(r, c)
            continue;
        end
        q = zeros(rows * cols, 2);
        head = 1; tail = 1;
        q(tail, :) = [r, c];
        visited(r, c) = true;
        pix = [];
        while head <= tail
            rc = q(head, :); head = head + 1;
            pix(end + 1, 1) = sub2ind([rows, cols], rc(1), rc(2)); %#ok<AGROW>
            for d = 1:size(dirs, 1)
                nr = rc(1) + dirs(d, 1);
                nc = rc(2) + dirs(d, 2);
                if nr < 1 || nr > rows || nc < 1 || nc > cols
                    continue;
                end
                if ~BW(nr, nc) || visited(nr, nc)
                    continue;
                end
                tail = tail + 1;
                q(tail, :) = [nr, nc];
                visited(nr, nc) = true;
            end
        end
        pixel_lists{end + 1} = pix; %#ok<AGROW>
    end
end
CC.NumObjects = numel(pixel_lists);
CC.PixelIdxList = pixel_lists;
end

feat.map_scale = rows;
feat.turning_difficulty_score = min(1, 0.5 * feat.narrow_corridor_ratio + ...
    0.3 * min(feat.connected_free_regions / 20, 1) + ...
    0.2 * feat.obstacle_density);
feat.clutter_score = min(1, 0.6 * feat.obstacle_density + ...
    0.4 * min(feat.avg_obstacle_block_size / 8, 1));

if nargin >= 2 && ~isempty(out_json_path)
    save_json(out_json_path, feat);
end
end

function D = local_bwdist(BW)
% Try Image Processing Toolbox first, fallback to Manhattan approximation.
if exist('bwdist', 'file') == 2
    D = bwdist(BW);
    return;
end

[r, c] = size(BW);
D = inf(r, c);
obs_idx = find(BW);
if isempty(obs_idx)
    D(:) = max(r, c);
    return;
end
[or, oc] = ind2sub([r, c], obs_idx);
for y = 1:r
    for x = 1:c
        D(y, x) = min(abs(or - y) + abs(oc - x));
    end
end
end
