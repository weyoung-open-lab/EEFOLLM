function main_regenerate_all_maps()
%MAIN_REGENERATE_ALL_MAPS Delete saved Map1–Map5 and rebuild from default_config (sizes + complexity aligned).
% Run once after editing cfg.maps.sizes or cfg.maps.complexity.
%
%   main_regenerate_all_maps

root_dir = fileparts(mfilename('fullpath'));
addpath(fullfile(root_dir, 'config'));
addpath(fullfile(root_dir, 'utils'));
cfg = default_config();
init_paths(root_dir);

for i = 1:numel(cfg.maps.names)
    name = cfg.maps.names{i};
    for ext = {'.mat', '.png', '.fig'}
        f = fullfile(cfg.paths.maps, [name, ext{1}]);
        if isfile(f)
            delete(f);
        end
    end
end
manifest = fullfile(cfg.paths.maps, 'map_manifest.mat');
if isfile(manifest)
    delete(manifest);
end

map_list = generate_maps(cfg);
fprintf(1, 'Regenerated %d maps. sizes=%s complexity=%s\n', numel(map_list), ...
    mat2str(cfg.maps.sizes), mat2str(cfg.maps.complexity, 3));
fprintf(1, 'Maps dir: %s\n', cfg.paths.maps);
end
