function compatibility_score = CalculateCompatibility_WithCase(solution, components_db, case_demand)
    % 计算电脑组件的兼容性评分（0-1之间）
    % 输入：
    %   solution - 组件选择向量 [CPU, GPU, 主板, 电源, 内存, 散热器, 机箱]
    %   components_db - 组件数据库
    %   case_demand - 机箱需求（0或1）
    % 输出：
    %   compatibility_score - 兼容性评分（0-1，越高表示兼容性越好）
    
    % 确保solution是列向量
    solution = solution(:);
    
    % 获取组件索引
    cpu_idx = round(solution(1));
    gpu_idx = round(solution(2));
    mobo_idx = round(solution(3));
    psu_idx = round(solution(4));
    ram_idx = round(solution(5));
    cooler_idx = round(solution(6));
    case_idx = round(solution(7));
    
    compatibility_score = 1.0;  % 初始兼容性分数
    
    % 检查每个组件是否在有效范围内
    if cpu_idx < 1 || cpu_idx > 5
        compatibility_score = compatibility_score * 0.8;
    end
    
    if gpu_idx < 1 || gpu_idx > 5
        compatibility_score = compatibility_score * 0.8;
    end
    
    if mobo_idx < 1 || mobo_idx > 5
        compatibility_score = compatibility_score * 0.8;
    end
    
    if psu_idx < 1 || psu_idx > 5
        compatibility_score = compatibility_score * 0.8;
    end
    
    if ram_idx < 1 || ram_idx > 5
        compatibility_score = compatibility_score * 0.8;
    end
    
    if cooler_idx < 1 || cooler_idx > 5
        compatibility_score = compatibility_score * 0.8;
    end
    
    if case_demand == 1 && (case_idx < 1 || case_idx > 5)
        compatibility_score = compatibility_score * 0.8;
    end
    
    % 1. 电源功率检查
    % 获取每个组件的功率估算
    cpu_power = [65, 95, 125, 150, 200];  % CPU功率（瓦）
    gpu_power = [75, 120, 180, 250, 350]; % GPU功率（瓦）
    psu_power = [400, 550, 650, 750, 850]; % 电源额定功率（瓦）
    
    total_power = 0;
    if cpu_idx >= 1 && cpu_idx <= 5
        total_power = total_power + cpu_power(cpu_idx);
    end
    
    if gpu_idx >= 1 && gpu_idx <= 5
        total_power = total_power + gpu_power(gpu_idx);
    end
    
    % 加上其他组件的基础功耗（主板、内存、散热器）
    total_power = total_power + 50;  % 基础功耗
    
    psu_available = 0;
    if psu_idx >= 1 && psu_idx <= 5
        psu_available = psu_power(psu_idx);
    end
    
    if psu_available > 0
        power_ratio = total_power / psu_available;
        if power_ratio > 0.9
            % 电源负载超过90%，降低兼容性
            compatibility_score = compatibility_score * 0.7;
        elseif power_ratio > 0.8
            compatibility_score = compatibility_score * 0.9;
        elseif power_ratio < 0.4
            % 电源负载过低，效率不高
            compatibility_score = compatibility_score * 0.95;
        end
    end
    
    % 2. 散热器与CPU匹配检查
    if cpu_idx >= 4 && cooler_idx <= 2  % 高端CPU配基础散热器
        compatibility_score = compatibility_score * 0.7;
    elseif cpu_idx >= 3 && cooler_idx == 1  % 中高端CPU配基础散热器
        compatibility_score = compatibility_score * 0.8;
    elseif cpu_idx <= 2 && cooler_idx >= 4  % 低端CPU配高端散热器（浪费）
        compatibility_score = compatibility_score * 0.9;
    end
    
    % 3. 内存与主板匹配检查
    if ram_idx >= 4 && mobo_idx <= 2  % 大内存配入门主板
        compatibility_score = compatibility_score * 0.8;
    end
    
    % 4. GPU与机箱兼容性（仅限有机箱情况）
    if case_demand == 1
        if gpu_idx >= 4 && case_idx <= 2  % 高端GPU配小机箱
            compatibility_score = compatibility_score * 0.6;
        elseif gpu_idx >= 3 && case_idx == 1  % 中高端GPU配基础机箱
            compatibility_score = compatibility_score * 0.8;
        end
    else
        % 无机箱时，散热考虑
        if cpu_idx >= 3 || gpu_idx >= 3
            % 中高端以上组件在无机箱时散热可能不足
            compatibility_score = compatibility_score * 0.85;
        end
    end
    
    % 5. CPU与主板匹配（简化检查）
    if (cpu_idx >= 4 && mobo_idx <= 2) || (cpu_idx <= 2 && mobo_idx >= 4)
        % 高端CPU配低端主板，或低端CPU配高端主板
        compatibility_score = compatibility_score * 0.85;
    end
    
    % 确保兼容性分数在0-1之间
    compatibility_score = max(0, min(1, compatibility_score));
    
    % 添加一些随机性（实际配置可能有细微差异）
    compatibility_score = compatibility_score * (0.95 + 0.05 * rand());
end