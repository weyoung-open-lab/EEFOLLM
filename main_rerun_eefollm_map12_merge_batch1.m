function main_rerun_eefollm_map12_merge_batch1(regen_figures)
%MAIN_RERUN_EEFOLLM_MAP12_MERGE_BATCH1  Wrapper: EEFOLLM on Map1+Map2, merge batch1 (see main_rerun_eefollm_maps_merge_batch1).
if nargin < 1 || isempty(regen_figures)
    regen_figures = true;
end
main_rerun_eefollm_maps_merge_batch1({'Map1', 'Map2'}, regen_figures);
end
