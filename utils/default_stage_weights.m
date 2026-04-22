function stage_w = default_stage_weights(cfg)
%DEFAULT_STAGE_WEIGHTS Return normalized default stage-wise weights.
%   Prefer cfg.weights.handcrafted_stage_weights when present (LLM fallback).

if isfield(cfg.weights, 'handcrafted_stage_weights') && ...
        isfield(cfg.weights.handcrafted_stage_weights, 'early')
    h = cfg.weights.handcrafted_stage_weights;
    stage_w.early = normalize_stage_weights(h.early);
    stage_w.mid = normalize_stage_weights(h.mid);
    stage_w.late = normalize_stage_weights(h.late);
else
    stage_w = cfg.weights.stage_default;
    stage_w.early = normalize_weights(stage_w.early);
    stage_w.mid = normalize_weights(stage_w.mid);
    stage_w.late = normalize_weights(stage_w.late);
end
end
