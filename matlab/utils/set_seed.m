function set_seed(seed)
%SET_SEED Set deterministic random seed for reproducibility.
if nargin < 1 || isempty(seed)
    seed = 1;
end
rng(double(seed), 'twister');
end
