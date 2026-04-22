function f = metah_eval_fitness(problem, params, x, iter, T)
%METAH_EVAL_FITNESS Shared fitness for population-based metaheuristics.
if isfield(params, 'use_stage_weights') && params.use_stage_weights
    wgt = select_stage_weights(params.stage_weights, iter, T, params.cfg);
else
    wgt = params.weights;
end
[f, ~] = problem.fitness_handle(x, problem.map_data, wgt, params.cfg);
end
