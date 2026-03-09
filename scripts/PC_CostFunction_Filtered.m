function z = PC_CostFunction_Filtered(x, PC_Problem, param7_option)
    % 通用目标函数
    % 目标1：最小化总成本（第1列）
    % 目标2：最大化总性能（第2列）
    
    total_cost = 0;
    total_performance = 0;
    domestic_count = 0;  % 统计属性4为1的数量
    
    if param7_option == 1
        components_db = PC_Problem.FilteredComponents_WithCase;
    else
        components_db = PC_Problem.FilteredComponents_WithoutCase;
    end
    
    for i = 1:PC_Problem.nVar
        field_name = PC_Problem.FieldNames{i};
        model_idx = round(x(i));
        
        if model_idx >= 1 && model_idx <= size(components_db.(field_name).data, 1)
            comp_data = components_db.(field_name).data(model_idx, :);
            total_cost = total_cost + comp_data(1);
            total_performance = total_performance + comp_data(2);
            
            if comp_data(4) == 1
                domestic_count = domestic_count + 1;
            end
        else
            % 无效索引惩罚
            total_cost = total_cost + 10000;
            total_performance = total_performance - 100;
        end
    end
    
    % 属性4数量影响性能
    [boost_factor, ~] = CalculateDomesticBoost(domestic_count);
    total_performance = total_performance * boost_factor;
    
    % 随机兼容性调整（可移除或替换为其他规则）
    compatibility_score = 0.9 + 0.1 * rand();
    total_performance = total_performance * compatibility_score;
    
    % 返回两个目标（第二个取负以实现最大化）
    z = [total_cost, -total_performance];
end