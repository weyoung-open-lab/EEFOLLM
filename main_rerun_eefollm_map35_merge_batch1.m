function main_rerun_eefollm_map35_merge_batch1(regen_figures)
%MAIN_RERUN_EEFOLLM_MAP35_MERGE_BATCH1  EEFOLLM on Map3 + Map5 only, merge batch1 (seeds use map indices 3 and 5).
if nargin < 1 || isempty(regen_figures)
    regen_figures = true;
end
main_rerun_eefollm_maps_merge_batch1({'Map3', 'Map5'}, regen_figures);
end
