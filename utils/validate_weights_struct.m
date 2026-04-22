function [ok, stage_weights, msg] = validate_weights_struct(raw_weights, cfg)
%VALIDATE_WEIGHTS_STRUCT Backward-compatible alias for validate_llm_weights.
%   Legacy callers (e.g. batch cache loaders) use this name.
%
%   See also: validate_llm_weights

[ok, stage_weights, msg] = validate_llm_weights(raw_weights, cfg);
end
