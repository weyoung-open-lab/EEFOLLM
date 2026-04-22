function w = get_stage_weights(iter, maxIter, weights_struct, cfg)
%GET_STAGE_WEIGHTS Return reward weights for the current optimization iteration.
%
%   Stage schedule (default, over normalized progress t = iter / maxIter):
%     early: t <= early_end   (default 0.30)
%     mid  : early_end < t <= late_start (default 0.30 < t <= 0.70)
%     late : t > late_start   (default > 0.70)
%
%   Override bounds via cfg.stage_split.early_end and cfg.stage_split.late_start
%
%   See also: select_stage_weights, run_eefo

if nargin < 4 || isempty(cfg)
    early_end = 0.30;
    late_start = 0.70;
else
    if isfield(cfg, 'stage_split') && isfield(cfg.stage_split, 'early_end')
        early_end = double(cfg.stage_split.early_end);
    else
        early_end = 0.30;
    end
    if isfield(cfg, 'stage_split') && isfield(cfg.stage_split, 'late_start')
        late_start = double(cfg.stage_split.late_start);
    else
        late_start = 0.70;
    end
end

T = max(double(maxIter), 1);
r = double(iter) / T;

if r <= early_end
    w = weights_struct.early;
elseif r <= late_start
    w = weights_struct.mid;
else
    w = weights_struct.late;
end
end
