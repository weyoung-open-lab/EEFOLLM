function [data, err_msg] = load_llm_weights_json(json_path)
%LOAD_LLM_WEIGHTS_JSON Load LLM-produced reward weights JSON from disk.
%
%   Returns decoded struct from jsondecode. On read/parse failure, data is []
%   and err_msg is nonempty.
%
%   Typical layout: early/mid/late each with wL,wC,wS,wT — still run through
%   validate_llm_weights before optimization.
%
%   See also: generate_llm_weights, validate_llm_weights

if ~exist('load_json', 'file')
    root = fileparts(fileparts(mfilename('fullpath')));
    addpath(fullfile(root, 'utils'));
end

data = [];
err_msg = '';
if nargin < 1 || isempty(json_path) || ~isfile(json_path)
    err_msg = 'JSON file not found.';
    return
end
try
    data = load_json(json_path);
catch ME
    err_msg = ME.message;
    data = [];
end
end
