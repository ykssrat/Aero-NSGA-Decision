function y = IntegerMutate_Filtered(x, mutation_rate, var_min, var_max, case_option)
    % 整数变异操作（适应筛选后的数据库）
    
    n = numel(x);
    y = x;
    
    for i = 1:n
        if rand() < mutation_rate
            if i == n  % 机箱变量（最后一个）
                % 根据case_option决定机箱变量
                if case_option == 1
                    y(i) = 1;  % 强制有机箱
                else
                    y(i) = 0;  % 强制无机箱
                end
            else
                % 其他组件：随机变异为新的型号
                if rand() < 0.5  % 一半概率向上变异
                    if y(i) < var_max(i)
                        y(i) = y(i) + 1;
                    end
                else  % 一半概率向下变异
                    if y(i) > var_min(i)
                        y(i) = y(i) - 1;
                    end
                end
            end
        end
    end
    
    % 确保在合法范围内
    y = max(var_min, min(var_max, round(y)));
end