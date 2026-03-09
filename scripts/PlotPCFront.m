function PlotPCFront(F1, iteration)
    % 绘制Pareto前沿
         if isempty(F1)
        return;
    end
    
    % 提取成本数据
    n = length(F1);
    if n == 0
        return;
    end
    
    costs = zeros(n, 1);
    performances = zeros(n, 1);
    
    for i = 1:n
        if length(F1(i).Cost) >= 2
            costs(i) = F1(i).Cost(1);  % 成本（第一个目标）
            performances(i) = -F1(i).Cost(2);  % 性能（第二个目标取负）
        end
    end
    
    % 移除无效数据
    valid_idx = ~isnan(costs) & ~isnan(performances);
    costs = costs(valid_idx);
    performances = performances(valid_idx);
    
    if isempty(costs)
        return;
    end
    
    figure(1);
    
    % 使用scatter调用
    scatter(costs, performances, 'b', 'filled');
    xlabel('总成本 (￥)');
    ylabel('总性能');
    title(sprintf('迭代 %d: Pareto前沿', iteration));
    grid on;
    drawnow;
end