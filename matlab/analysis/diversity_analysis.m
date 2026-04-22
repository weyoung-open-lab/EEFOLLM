function div_curve = diversity_analysis(history)
%DIVERSITY_ANALYSIS Population diversity over iterations.
if ~isfield(history, 'population') || isempty(history.population)
    div_curve = [];
    return;
end
T = numel(history.population);
div_curve = nan(1, T);
for t = 1:T
    X = history.population{t};
    if isempty(X), continue; end
    div_curve(t) = mean(std(X, 0, 1, 'omitnan'), 'omitnan');
end
end
