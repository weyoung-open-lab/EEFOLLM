function [ok, stage_weights, msg] = validate_llm_weights(raw_weights, cfg)
%VALIDATE_LLM_WEIGHTS Validate LLM JSON stage weights; fallback to handcrafted if invalid.
%
%   Checks:
%     - stages early / mid / late exist
%     - each has wL, wC, wS, wT
%     - values are finite, nonnegative, non-NaN
%
%   On failure: if cfg.fallback_to_handcrafted, returns normalized handcrafted
%   stage weights from cfg.weights.handcrafted_stage_weights (else defaults).
%
%   Output stage_weights: struct early/mid/late, each normalized to sum 1
%
%   See also: load_llm_weights_json, generate_llm_weights

ok = false;
msg = '';
stage_weights = default_stage_weights(cfg);
required_stages = {'early', 'mid', 'late'};
required_keys = {'wL', 'wC', 'wS', 'wT'};

try
    for s = 1:numel(required_stages)
        st_name = required_stages{s};
        if ~isfield(raw_weights, st_name)
            msg = sprintf('Missing stage: %s', st_name);
            stage_weights = fallback_handcrafted(cfg);
            return;
        end
        ws = raw_weights.(st_name);
        for k = 1:numel(required_keys)
            ky = required_keys{k};
            if ~isfield(ws, ky)
                msg = sprintf('Missing key: %s.%s', st_name, ky);
                stage_weights = fallback_handcrafted(cfg);
                return;
            end
            val = double(ws.(ky));
            if ~isscalar(val) || ~isfinite(val) || isnan(val) || val < 0
                msg = sprintf('Invalid value: %s.%s', st_name, ky);
                stage_weights = fallback_handcrafted(cfg);
                return;
            end
        end
        stage_weights.(st_name) = normalize_stage_weights(ws);
    end
    ok = true;
    msg = 'OK';
catch ME
    msg = ['validate_llm_weights exception: ', ME.message];
    stage_weights = fallback_handcrafted(cfg);
end
end

function sw = fallback_handcrafted(cfg)
sw = default_stage_weights(cfg);
end
