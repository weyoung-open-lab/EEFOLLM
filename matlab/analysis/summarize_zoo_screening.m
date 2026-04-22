function summarize_zoo_screening(records, out_csv_path)
%SUMMARIZE_ZOO_SCREENING Mean BestFit per algorithm; flag algorithms weaker than EEFOLLM (higher = worse).
if ischar(records) || isstring(records)
    T = readtable(records);
else
    T = records;
end

T.Algorithm = cellstr(string(T.Algorithm));
T.Map = cellstr(string(T.Map));
algs = unique(T.Algorithm, 'stable');
maps = unique(T.Map, 'stable');
nA = numel(algs);
nM = numel(maps);
mean_map = nan(nA, nM);
for ai = 1:nA
    for mi = 1:nM
        rows = T(strcmp(T.Algorithm, algs{ai}) & strcmp(T.Map, maps{mi}), :);
        mean_map(ai, mi) = mean(rows.BestFit, 'omitnan');
    end
end
overall = mean(mean_map, 2, 'omitnan');

ref = find(strcmp(algs, 'EEFOLLM'), 1);
if isempty(ref)
    ref = find(strcmp(algs, 'LLM-EEFO'), 1);
end
if isempty(ref)
    ref_fit = nan;
    weaker = false(nA, 1);
else
    ref_fit = overall(ref);
    weaker = overall > ref_fit;
end

tbl = table(string(algs), overall, weaker, 'VariableNames', {'Algorithm', 'MeanBestFit_AllMaps', 'WeakerThan_EEFOLLM'});
for mi = 1:nM
    fn = matlab.lang.makeValidName(['Mean_' maps{mi}]);
    tbl.(fn) = mean_map(:, mi);
end

if nargin >= 2 && ~isempty(out_csv_path)
    writetable(tbl, out_csv_path);
    cmp_tbl = compare_vs_llmsfo(records, 'EEFOLLM');
    writetable(cmp_tbl, fullfile(fileparts(out_csv_path), 'comparison_vs_llm_eefo.csv'));
end

fprintf(1, '\n=== Reference EEFOLLM mean BestFit (all maps): %.6g ===\n', ref_fit);
fprintf(1, 'Algorithms with higher mean BestFit (weaker than EEFOLLM):\n');
for ai = 1:nA
    if weaker(ai)
        fprintf(1, '  %s  (mean=%.6g)\n', algs{ai}, overall(ai));
    end
end
end
