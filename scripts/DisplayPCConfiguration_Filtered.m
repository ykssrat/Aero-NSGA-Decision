function DisplayPCConfiguration_Filtered(solution, PC_Problem, param7_option, total_cost, total_performance, attr3_choice, param_filters)
    % 显示最佳配置
    
    fprintf('\n========== 最佳配置方案 ==========\n');
    
    if param7_option == 1
        param7_str = '需要参数7';
    else
        param7_str = '不需要参数7';
    end
    fprintf('参数7需求: %s\n', param7_str);
    
    % 属性3需求
    if attr3_choice == 1
        attr3_str = '需要';
    else
        attr3_str = '不需要';
    end
    fprintf('属性3需求: %s\n', attr3_str);
    
    % 各参数筛选条件
    fprintf('\n各参数筛选条件:\n');
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
            
            fprintf('  %s: 属性4-%s, 属性5-%s\n', disp_name, attr4_str, attr5_str);
        end
    end
    
    fprintf('\n总成本: ¥%.2f\n', total_cost);
    fprintf('总性能评分: %.2f\n', total_performance);
    
    if total_cost > 0
        fprintf('性价比: %.4f\n', total_performance / total_cost);
    else
        fprintf('性价比: N/A (零成本)\n');
    end
    
    % 选择数据库
    if param7_option == 1
        components_db = PC_Problem.FilteredComponents_WithCase;
    else
        components_db = PC_Problem.FilteredComponents_WithoutCase;
    end
    
    fprintf('\n--- 详细配置 ---\n');
    
    total_price_check = 0;
    total_performance_raw = 0;
    domestic_count = 0;
    domestic_params = {};
    
    for i = 1:PC_Problem.nVar
        disp_name = PC_Problem.DisplayNames{i};
        field_name = PC_Problem.FieldNames{i};
        model_idx = round(solution(i));
        
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
                
                if param7_option == 1
                    original_indices = PC_Problem.FilteredComponents_WithCase.(field_name).original_indices;
                else
                    original_indices = PC_Problem.FilteredComponents_WithoutCase.(field_name).original_indices;
                end
                original_model_idx = original_indices(model_idx);
                
                if i == 7 && param7_option == 2
                    fprintf('%12s: 无参数7\n', disp_name);
                else
                    fprintf('%12s: 型号%d - 成本: ¥%d, 性能: %d', ...
                            disp_name, original_model_idx, price, performance);
                    fprintf(' [属性3:%d, 属性4:%d, 属性5:%d]\n', ...
                            attr3, attr4, attr5);
                end
                
                total_price_check = total_price_check + price;
                total_performance_raw = total_performance_raw + performance;
            else
                fprintf('%12s: 无效型号索引\n', disp_name);
            end
        else
            fprintf('%12s: 参数数据不存在\n', disp_name);
        end
    end
    
    fprintf('\n参数成本合计: ¥%d, 参数性能合计: %d\n', ...
            total_price_check, total_performance_raw);
    
    % 国产化性能影响
    [boost_factor, boost_str] = CalculateDomesticBoost(domestic_count);
    boosted_performance = total_performance_raw * boost_factor;
    
    fprintf('\n属性4信息:\n');
    fprintf('属性4为1的数量: %d个\n', domestic_count);
    if domestic_count > 0
        fprintf('具有属性4的参数: %s\n', strjoin(domestic_params, ', '));
    end
    fprintf('属性4性能影响: %s (乘数: %.2f)\n', boost_str, boost_factor);
    fprintf('影响后基础性能: %.2f\n', boosted_performance);
    
    fprintf('===================================\n');
end