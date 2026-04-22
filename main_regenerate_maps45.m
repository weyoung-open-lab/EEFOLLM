function main_regenerate_maps45()
%MAIN_REGENERATE_MAPS45 Delete saved Map4/Map5 and rebuild from current cfg.maps.complexity.
% Run once after changing default_config.m (Map4/5 density or sizes).
%
%   main_regenerate_maps45

root_dir = fileparts(mfilename('fullpath'));
addpath(fullfile(root_dir, 'config'));
addpath(fullfile(root_dir, 'utils'));
cfg = default_config();
init_paths(root_dir);

for name = {'Map4', 'Map5'}
    for ext = {'.mat', '.png'}
        f = fullfile(cfg.paths.maps, [name{1}, ext{1}]);
        if isfile(f)
            delete(f);
        end
    end
end

generate_maps(cfg);
fprintf(1, 'Regenerated Map4 and Map5. size(4)=%d size(5)=%d complexity(4)=%.3f complexity(5)=%.3f\n', ...
    cfg.maps.sizes(4), cfg.maps.sizes(5), cfg.maps.complexity(4), cfg.maps.complexity(5));
fprintf(1, 'Maps saved under %s\n', cfg.paths.maps);
end
