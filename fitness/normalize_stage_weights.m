function w_out = normalize_stage_weights(w_in)
%NORMALIZE_STAGE_WEIGHTS Normalize one stage struct {wL,wC,wS,wT} to sum 1, nonnegative.
%   w_in may be a struct with fields wL, wC, wS, wT or a 1x4 numeric vector.
%
%   See also: validate_llm_weights

if isnumeric(w_in)
    v = max(double(w_in(:))', 0);
else
    keys = {'wL', 'wC', 'wS', 'wT'};
    v = zeros(1, 4);
    for i = 1:4
        if ~isfield(w_in, keys{i})
            error('normalize_stage_weights:MissingField', 'Missing field %s.', keys{i});
        end
        v(i) = max(double(w_in.(keys{i})), 0);
    end
end
s = sum(v);
if s <= eps
    v = [0.25, 0.25, 0.25, 0.25];
else
    v = v / s;
end
w_out = struct('wL', v(1), 'wC', v(2), 'wS', v(3), 'wT', v(4));
end
