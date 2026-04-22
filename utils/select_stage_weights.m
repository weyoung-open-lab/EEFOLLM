function w = select_stage_weights(stage_weights, iter, max_iter, cfg)
%SELECT_STAGE_WEIGHTS Pick early/mid/late weights by iteration ratio.
%   Delegates to fitness/get_stage_weights (default split 30%% / 40%% / 30%% of progress).
%
%   Optional fourth argument cfg carries cfg.stage_split.early_end / late_start.

if nargin < 4
    cfg = [];
end
w = get_stage_weights(iter, max_iter, stage_weights, cfg);
end
