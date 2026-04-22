function summary_tbl = compute_statistics(records_tbl)
%COMPUTE_STATISTICS Aggregate metrics by map and algorithm.
g = findgroups(records_tbl.Map, records_tbl.Algorithm);
Map = splitapply(@(x) x(1), records_tbl.Map, g);
Algorithm = splitapply(@(x) x(1), records_tbl.Algorithm, g);
SR = splitapply(@mean, records_tbl.Success, g);
BestFitness = splitapply(@min, records_tbl.BestFit, g);
MeanFitness = splitapply(@mean, records_tbl.BestFit, g);
WorstFitness = splitapply(@max, records_tbl.BestFit, g);
StdFitness = splitapply(@std, records_tbl.BestFit, g);
Runtime = splitapply(@mean, records_tbl.Runtime, g);
PathLength = splitapply(@mean, records_tbl.PathLength, g);
Smoothness = splitapply(@mean, records_tbl.Smoothness, g);
AvgTurning = splitapply(@mean, records_tbl.AvgTurningAngle, g);
CollisionFreeRate = splitapply(@mean, records_tbl.CollisionFree, g);

summary_tbl = table(Map, Algorithm, SR, BestFitness, MeanFitness, WorstFitness, ...
    StdFitness, Runtime, PathLength, Smoothness, AvgTurning, CollisionFreeRate);
end
