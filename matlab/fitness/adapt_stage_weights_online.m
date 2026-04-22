function params = adapt_stage_weights_online(params, C_pop, cfg)
%ADAPT_STAGE_WEIGHTS_ONLINE Online adaptation of stage-wise reward weights (OAW) during EEFO.
%
%   Uses population collision penalty C: fraction with hard collision (C >= collision_hard)
%   to nudge wC up/down in each stage (early/mid/late), then renormalize per stage.
%
%   Trigger: cfg.online_adaptive.frac_high / frac_low vs population fraction.
%
%   See also: run_eefo

o = cfg.online_adaptive;
nh = cfg.penalty.collision_hard;
frac = mean(double(C_pop(:) >= nh));
if frac > o.frac_high
    factor = 1 + o.eta_up;
elseif frac < o.frac_low
    factor = 1 - o.eta_down;
else
    return;
end
factor = min(max(factor, o.factor_min), o.factor_max);

stages = {'early', 'mid', 'late'};
for si = 1:numel(stages)
    name = stages{si};
    w = params.stage_weights.(name);
    w.wC = double(w.wC) * factor;
    s = double(w.wL) + double(w.wC) + double(w.wS) + double(w.wT);
    s = max(s, eps);
    w.wL = w.wL / s;
    w.wC = w.wC / s;
    w.wS = w.wS / s;
    w.wT = w.wT / s;
    params.stage_weights.(name) = w;
end
end
