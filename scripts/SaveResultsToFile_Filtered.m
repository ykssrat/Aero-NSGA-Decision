function SaveResultsToFile_Filtered(pareto_solutions, pareto_costs, best_solution, best_cost, best_performance, PC_Problem, param7_option, attr3_choice, param_filters)
    % 保存结果到文件
    
    current_time = datetime('now', 'Format', 'yyyy-MM-dd_HH-mm');
    filename = sprintf('Optimization_Results_%s.mat', char(current_time));
    
    results = struct();
    results.timestamp = char(datetime('now'));
    results.param7_option = param7_option;
    results.attr3_choice = attr3_choice;
    results.param_filters = param_filters;
    results.pareto_solutions = pareto_solutions;
    results.pareto_costs = pareto_costs;
    results.best_solution = best_solution;
    results.best_cost = best_cost;
    results.best_performance = best_performance;
    results.PC_Problem = PC_Problem;
    
    save(filename, 'results');
    fprintf('\n结果已保存到MAT文件: %s\n', filename);
    
    txt_filename = strrep(filename, '.mat', '.txt');
    fid = fopen(txt_filename, 'w');
    
    fprintf(fid, '通用多目标优化结果 - %s\n\n', char(datetime('now')));
    
    if param7_option == 1
        fprintf(fid, '参数7需求: 需要\n');
    else
        fprintf(fid, '参数7需求: 不需要\n');
    end
    
    if attr3_choice == 1
        fprintf(fid, '属性3需求: 需要\n');
    else
        fprintf(fid, '属性3需求: 不需要\n');
    end
    
    fprintf(fid, '\n各参数筛选条件:\n');
    for i = 1:PC_Problem.nVar
        disp_name = PC_Problem.DisplayNames{i};
        field_name = PC_Problem.FieldNames{i};
        if isfield(param_filters, field_name)
            attr4_req = param_filters.(field_name).attr4;
            attr5_req = param_filters.(field_name).attr5;
            
            if strcmp(field_name, 'Param7') && param7_option == 2
                continue;
            end
            
            if attr4_req == 1
                attr4_str = '需要';
            else
                attr4_str = '不需要';
            end
            
            if attr5_req == 1
                attr5_str = '需要';
            else
                attr5_str = '不需要';
            end
            
            fprintf(fid, '  %s: 属性4-%s, 属性5-%s\n', disp_name, attr4_str, attr5_str);
        end
    end
    
    fprintf(fid, '\n最佳配置方案:\n');
    fprintf(fid, '总成本: ¥%.2f\n', best_cost);
    fprintf(fid, '总性能: %.2f\n', best_performance);
    
    if best_cost > 0
        fprintf(fid, '性价比: %.4f\n\n', best_performance / best_cost);
    else
        fprintf(fid, '性价比: N/A\n\n');
    end
    
    if param7_option == 1
        components_db = PC_Problem.FilteredComponents_WithCase;
        orig_db = PC_Problem.FilteredComponents_WithCase;
    else
        components_db = PC_Problem.FilteredComponents_WithoutCase;
        orig_db = PC_Problem.FilteredComponents_WithoutCase;
    end
    
    fprintf(fid, '详细配置:\n');
    
    domestic_count = 0;
    domestic_params = {};
    
    for i = 1:PC_Problem.nVar
        disp_name = PC_Problem.DisplayNames{i};
        field_name = PC_Problem.FieldNames{i};
        model_idx = best_solution(i);
        
        if isfield(components_db, field_name)
            comp_data = components_db.(field_name).data;
            
            if model_idx >= 1 && model_idx <= size(comp_data, 1)
                price = comp_data(model_idx, 1);
                performance = comp_data(model_idx, 2);
                attr3 = comp_data(model_idx, 3);
                attr4 = comp_data(model_idx, 4);
                attr5 = comp_data(model_idx, 5);
                
                if attr4 == 1
                    domestic_count = domestic_count + 1;
                    domestic_params{end+1} = disp_name;
                end
                
                orig_idx = orig_db.(field_name).original_indices(model_idx);
                
                if i == 7 && param7_option == 2
                    fprintf(fid, '%12s: 无参数7\n', disp_name);
                else
                    fprintf(fid, '%12s: 型号%d - 成本: ¥%d, 性能: %d', ...
                            disp_name, orig_idx, price, performance);
                    fprintf(fid, ' [属性3:%d, 属性4:%d, 属性5:%d]\n', ...
                            attr3, attr4, attr5);
                end
            else
                fprintf(fid, '%12s: 无效索引\n', disp_name);
            end
        end
    end
    
    [boost_factor, boost_str] = CalculateDomesticBoost(domestic_count);
    
    fprintf(fid, '\n--- 属性4性能影响 ---\n');
    fprintf(fid, '属性4为1的数量: %d\n', domestic_count);
    if domestic_count > 0
        fprintf(fid, '具有属性4的参数: %s\n', strjoin(domestic_params, ', '));
    end
    fprintf(fid, '性能影响: %s\n', boost_str);
    fprintf(fid, '性能系数: %.2f\n', boost_factor);
    
    fprintf(fid, '\n--- Pareto前沿统计 ---\n');
    fprintf(fid, '解数量: %d\n', size(pareto_solutions, 2));
    
    if ~isempty(pareto_costs)
        cost_vals = pareto_costs(:, 1);
        perf_vals = -pareto_costs(:, 2);
        fprintf(fid, '成本范围: ¥%.2f - ¥%.2f\n', min(cost_vals), max(cost_vals));
        fprintf(fid, '性能范围: %.2f - %.2f\n', min(perf_vals), max(perf_vals));
        
        valid = cost_vals > 0;
        if any(valid)
            avg_ratio = mean(perf_vals(valid) ./ cost_vals(valid));
            fprintf(fid, '平均性价比: %.4f\n', avg_ratio);
        end
    end
    
    fclose(fid);
    fprintf('文本结果已保存到: %s\n', txt_filename);
end