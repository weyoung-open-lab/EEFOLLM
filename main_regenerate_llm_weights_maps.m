function main_regenerate_llm_weights_maps(map_names, out_subdir, force_mode)
%MAIN_REGENERATE_LLM_WEIGHTS_MAPS  Regenerate weights_Map*.json for selected maps (Python LLM + validate).
%
%   Calls generate_llm_weights as in main_run_global_experiments_batch (batch 1).
%   Backs up any existing JSON to *.bak-<timestamp> before overwriting.
%
%   Usage (MATLAB, repo root on path):
%     main_regenerate_llm_weights_maps                           % Map1..Map5 -> batch1/weights
%     main_regenerate_llm_weights_maps({'Map1','Map2'})          % subset
%     main_regenerate_llm_weights_maps({'Map3'}, 'global_experiments_batch1/weights')
%
%   force_mode: '' (default: real if cfg.use_real_qwen, else mock), or 'auto'|'real'|'mock'
%
%   See also: generate_llm_weights, main_run_global_experiments_batch

if nargin < 1 || isempty(map_names)
    map_names = {'Map1', 'Map2', 'Map3', 'Map4', 'Map5'};
end
if nargin < 2 || isempty(out_subdir)
    out_subdir = 'global_experiments_batch1/weights';
end
if nargin < 3
    force_mode = '';
end

root_dir = fileparts(mfilename('fullpath'));
addpath(fullfile(root_dir, 'config'));
addpath(fullfile(root_dir, 'utils'));

cfg = default_config();
init_paths(cfg.paths.root);

map_list = generate_maps(cfg);
name2map = containers.Map();
for i = 1:numel(map_list)
    name2map(map_list{i}.name) = map_list{i};
end

out_dir = fullfile(cfg.paths.results, out_subdir);
ensure_dir(out_dir);

ts = datestr(now, 'yyyymmdd_HHMMSS');
for k = 1:numel(map_names)
    mn = char(map_names{k});
    if ~isKey(name2map, mn)
        error('Unknown map name: %s (expected one of generate_maps names).', mn);
    end
    mstruct = name2map(mn);
    feat = extract_map_features(mstruct, '');
    [sw, meta] = generate_llm_weights(feat, cfg, force_mode);

    out_json = fullfile(out_dir, ['weights_', mn, '.json']);
    if isfile(out_json)
        bak = [out_json, '.bak-', ts]; %#ok<NASGU>
        copyfile(out_json, bak);
        fprintf(1, 'Backed up %s -> %s\n', out_json, bak);
    end
    save_json(out_json, sw);
    fprintf(1, 'Wrote %s  fallback=%d  llm_ok=%d  msg=%s\n', ...
        out_json, meta.used_fallback, meta.llm_validation_ok, meta.message);
end

rel = strrep(out_subdir, '\', '/');
fprintf(1, 'Done. Re-run: python scripts/plot_llm_reward_weights.py --weights-dir results/%s\n', rel);
end
