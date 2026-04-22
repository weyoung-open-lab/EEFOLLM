function [stage_weights, meta] = generate_llm_weights(map_features, cfg, force_mode)
%GENERATE_LLM_WEIGHTS Generate stage-wise weights using Python, then validate in MATLAB.
%
%   Pipeline: map_features -> Python JSON -> validate_llm_weights -> return
%
%   meta fields:
%     .weights_llm_validated — same as returned stage_weights after validation
%     .stage_weights_final    — same as stage_weights
%     .used_fallback          — Python failed or validation used handcrafted
%     .llm_validation_ok      — JSON structure valid
%     .validation_msg

if nargin < 3 || isempty(force_mode)
    if cfg.use_real_qwen
        force_mode = 'auto';
    else
        force_mode = 'mock';
    end
end

save_json(cfg.llm.map_feature_json, map_features);
write_run_status(cfg, 'Saved map_features JSON for Python.');
model_arg = cfg.llm.repo_id;
if isfolder(cfg.llm.local_model_dir) && ...
        exist(fullfile(cfg.llm.local_model_dir, 'model.safetensors.index.json'), 'file')
    model_arg = cfg.llm.local_model_dir;
end
cmd = sprintf('"%s" "%s" --input "%s" --output "%s" --mode %s --prompt "%s" --model "%s"', ...
    cfg.llm.python_exec, cfg.llm.generator_script, cfg.llm.map_feature_json, ...
    cfg.llm.weight_json, force_mode, cfg.llm.prompt_file, model_arg);
fprintf(1, '[LLM] Calling Python weight generator (mode=%s) ...\n', force_mode);
write_run_status(cfg, sprintf('Calling Python (mode=%s). Command window may stay silent until Python returns.', force_mode));
if cfg.use_real_qwen && strcmpi(force_mode, 'mock') == 0
    fprintf(1, '[LLM] First real-Qwen load + generate can take several minutes (GPU if available, else CPU); please wait.\n');
    write_run_status(cfg, 'Real Qwen: loading model + generate can take MINUTES. Watch Task Manager: python.exe may use GPU and/or CPU/RAM.');
end
drawnow;
t_llm = tic;
[status, output] = system(cmd);
fprintf(1, '[LLM] Python finished in %.1f s (exit code %d).\n', toc(t_llm), status);
write_run_status(cfg, sprintf('Python finished in %.1f s, exit=%d.', toc(t_llm), status));
if ~isempty(output)
    fprintf(1, '%s', output);
end

meta = struct();
meta.cmd_status = status;
meta.cmd_output = output;
meta.used_fallback = false;
meta.message = '';
meta.llm_validation_ok = false;
meta.validation_msg = '';

if status ~= 0 || ~exist(cfg.llm.weight_json, 'file')
    stage_weights = default_stage_weights(cfg);
    meta.used_fallback = true;
    meta.message = 'Python call failed, use MATLAB handcrafted stage weights.';
    meta.weights_llm_validated = stage_weights;
    meta.llm_validation_ok = false;
    meta.stage_weights_final = stage_weights;
    return;
end

raw = load_json(cfg.llm.weight_json);
[ok, sw_valid, msg] = validate_llm_weights(raw, cfg);
meta.llm_validation_ok = ok;
meta.validation_msg = msg;
meta.weights_llm_validated = sw_valid;
if ~ok
    meta.used_fallback = true;
    meta.message = ['Invalid weight JSON: ', msg];
else
    meta.message = msg;
end

if isfield(raw, '_meta')
    meta.raw_meta = raw.('_meta');
end

stage_weights = sw_valid;
meta.stage_weights_final = stage_weights;
end
