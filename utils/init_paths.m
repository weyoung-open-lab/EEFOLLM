function init_paths(root_dir)
%INIT_PATHS Add all project module folders to MATLAB path.
if nargin < 1 || isempty(root_dir)
    root_dir = fileparts(fileparts(mfilename('fullpath')));
end
addpath(genpath(fullfile(root_dir, 'algorithms')));
addpath(genpath(fullfile(root_dir, 'fitness')));
addpath(genpath(fullfile(root_dir, 'mapscripts')));
addpath(genpath(fullfile(root_dir, 'analysis')));
addpath(genpath(fullfile(root_dir, 'plotting')));
addpath(genpath(fullfile(root_dir, 'utils')));
addpath(genpath(fullfile(root_dir, 'config')));
addpath(fullfile(root_dir, 'llm'));
end
