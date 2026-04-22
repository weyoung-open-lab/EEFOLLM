function map_list = generate_maps(cfg)
%GENERATE_MAPS Build and save five reproducible benchmark maps.
addpath(fullfile(cfg.paths.root, 'utils'));
addpath(fullfile(cfg.paths.root, 'plotting'));
ensure_dir(cfg.paths.maps);

map_list = cell(1, numel(cfg.maps.names));
for i = 1:numel(cfg.maps.names)
    map_name = cfg.maps.names{i};
    map_file = fullfile(cfg.paths.maps, [map_name, '.mat']);
    img_file = fullfile(cfg.paths.maps, [map_name, '.png']);

    if exist(map_file, 'file') && ~cfg.regenerate_maps
        loaded = load(map_file, 'map_data');
        map_list{i} = loaded.map_data;
        continue;
    end

    map_data = build_single_map(cfg, i);
    save(map_file, 'map_data');
    plot_maps(map_data, img_file, []);
    map_list{i} = map_data;
end

meta_file = fullfile(cfg.paths.maps, 'map_manifest.mat');
save(meta_file, 'map_list');
end

function map_data = build_single_map(cfg, idx)
set_seed(cfg.base_seed + idx * 97);
N = cfg.maps.sizes(idx);
density_target = cfg.maps.complexity(idx);
safe_r = cfg.maps.safe_zone_radius;

if N == 40
    start_pt = cfg.maps.start_40;
    goal_pt = cfg.maps.goal_40;
else
    start_pt = cfg.maps.start_80;
    % [N-2, N-2] works for 70/80/…; cfg.maps.goal_80 is [78,78] == 80-2
    goal_pt = [N - 2, N - 2];
end

max_retry = 120;
for t = 1:max_retry
    grid = zeros(N, N);
    target_cells = round(N * N * density_target);
    occ_cells = 0;

    while occ_cells < target_cells
        h = randi([1, 4]);
        w = randi([1, 4]);
        r0 = randi([1, N - h + 1]);
        c0 = randi([1, N - w + 1]);
        patch = zeros(N, N);
        patch(r0:r0+h-1, c0:c0+w-1) = 1;
        grid = max(grid, patch);
        occ_cells = nnz(grid);
    end

    grid = carve_safe_zone(grid, start_pt, safe_r);
    grid = carve_safe_zone(grid, goal_pt, safe_r);

    if has_path(grid, start_pt, goal_pt)
        map_data.name = cfg.maps.names{idx};
        map_data.grid = grid;
        map_data.size = [N, N];
        map_data.start = start_pt;
        map_data.goal = goal_pt;
        map_data.seed = cfg.base_seed + idx * 97;
        map_data.target_density = density_target;
        map_data.real_density = nnz(grid) / numel(grid);
        map_data.complexity_level = idx;
        return;
    end
end
error('Failed to generate reachable map: %s', cfg.maps.names{idx});
end

function grid = carve_safe_zone(grid, center, radius)
rows = size(grid, 1);
cols = size(grid, 2);
cx = center(1);
cy = center(2);
for y = max(1, cy-radius):min(rows, cy+radius)
    for x = max(1, cx-radius):min(cols, cx+radius)
        grid(y, x) = 0;
    end
end
end

function ok = has_path(grid, start_pt, goal_pt)
rows = size(grid, 1);
cols = size(grid, 2);
visited = false(rows, cols);
q = zeros(rows * cols, 2);
head = 1;
tail = 1;
q(tail, :) = [start_pt(2), start_pt(1)];
visited(start_pt(2), start_pt(1)) = true;
dirs = [1 0; -1 0; 0 1; 0 -1];

ok = false;
while head <= tail
    rc = q(head, :); head = head + 1;
    if rc(1) == goal_pt(2) && rc(2) == goal_pt(1)
        ok = true;
        return;
    end
    for d = 1:4
        nr = rc(1) + dirs(d, 1);
        nc = rc(2) + dirs(d, 2);
        if nr < 1 || nr > rows || nc < 1 || nc > cols
            continue;
        end
        if visited(nr, nc) || grid(nr, nc) == 1
            continue;
        end
        tail = tail + 1;
        q(tail, :) = [nr, nc];
        visited(nr, nc) = true;
    end
end
end
