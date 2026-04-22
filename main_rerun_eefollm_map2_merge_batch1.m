function main_rerun_eefollm_map2_merge_batch1(regen_figures)
%MAIN_RERUN_EEFOLLM_MAP2_MERGE_BATCH1  Only Map2 EEFOLLM + merge batch1 (current weights_Map2.json).
%   main_rerun_eefollm_map2_merge_batch1
%   main_rerun_eefollm_map2_merge_batch1(false)   % no conv/path figures
if nargin < 1 || isempty(regen_figures)
    regen_figures = true;
end
main_rerun_eefollm_maps_merge_batch1({'Map2'}, regen_figures);
end
