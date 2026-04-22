function f = get_algorithm_handle(algo_name)
%GET_ALGORITHM_HANDLE Return optimizer function handle (10 shipped algorithms).
key = upper(strtrim(algo_name));
switch key
    case {'EEFOLLM', 'LLM-EEFO'}
        f = @run_llm_eefo;
    case 'SFO'
        f = @run_sfo;
    case 'PSO'
        f = @run_pso;
    case 'GWO'
        f = @run_gwo;
    case 'HO'
        f = @run_ho;
    case 'EEFO'
        f = @run_eefo;
    case 'SBOA'
        f = @run_sboa;
    case 'ARO'
        f = @run_aro;
    case 'DE'
        f = @run_de;
    case 'WOA'
        f = @run_woa;
    otherwise
        error('Unknown algorithm: %s', algo_name);
end
end
