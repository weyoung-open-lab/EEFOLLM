function init_paths(root_dir)
%INIT_PATHS Add all project module folders to MATLAB path.
%   root_dir = repository root (parent of matlab/).
if nargin < 1 || isempty(root_dir)
    root_dir = fileparts(fileparts(fileparts(mfilename('fullpath'))));
end
m = fullfile(root_dir, 'matlab');
addpath(genpath(fullfile(m, 'algorithms')));
addpath(genpath(fullfile(m, 'fitness')));
addpath(genpath(fullfile(m, 'mapscripts')));
addpath(genpath(fullfile(m, 'analysis')));
addpath(genpath(fullfile(m, 'plotting')));
addpath(genpath(fullfile(m, 'utils')));
addpath(genpath(fullfile(m, 'config')));
addpath(fullfile(m, 'llm_bridge'));
end
