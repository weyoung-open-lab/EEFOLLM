function f = get_algorithm_handle(algo_name)
%GET_ALGORITHM_HANDLE Return optimizer function handle by name (30+ zoo methods).
key = upper(strtrim(algo_name));
switch key
    case 'LLM-SFO'
        f = @run_llm_sfo;
    case {'EEFOLLM', 'LLM-EEFO'}  % LLM-EEFO legacy alias
        f = @run_llm_eefo;
    case 'EEFOLLM-PARTIAL'
        f = @run_llm_eefo_partial;
    case 'EEFOLLM-NS'
        f = @run_llm_eefo_ns;
    case 'EEFOLLM-NJ'
        f = @run_llm_eefo_nj;
    case 'EEFO-PARTIAL'
        f = @run_eefo_partial;
    case {'EEFOLLM-PARETO', 'LLM-EEFO-PARETO'}
        f = @run_llm_eefo_pareto;
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
    case 'ABC'
        f = @run_abc;
    case 'SSA'
        f = @run_ssa;
    case 'FA'
        f = @run_fa;
    case 'BA'
        f = @run_ba;
    case 'CS'
        f = @run_cs;
    case 'GA'
        f = @run_ga;
    case 'TLBO'
        f = @run_tlbo;
    case 'SCA'
        f = @run_sca;
    case 'HHO'
        f = @run_hho;
    case 'MFO'
        f = @run_mfo;
    case 'GSA'
        f = @run_gsa;
    case 'MVO'
        f = @run_mvo;
    case 'AOA'
        f = @run_aoa;
    case 'JAYA'
        f = @run_jaya;
    case 'WCA'
        f = @run_wca;
    case 'SMA'
        f = @run_sma;
    case 'MPA'
        f = @run_mpa;
    case 'EO'
        f = @run_eo;
    case 'TSA'
        f = @run_tsa;
    case 'GTO'
        f = @run_gto;
    otherwise
        error('Unknown algorithm: %s', algo_name);
end
end
