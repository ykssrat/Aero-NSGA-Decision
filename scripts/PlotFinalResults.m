function PlotFinalResults(cost_values, performance_values, best_idx)
    % 绘制最终结果
    
    if isempty(cost_values) || isempty(performance_values)
        return;
    end
    
    % 确保数据是列向量
    cost_values = cost_values(:);
    performance_values = performance_values(:);
    
    figure('Position', [100, 100, 1200, 800]);
    
    % 1. Pareto前沿图
    subplot(2, 2, 1);
    scatter(cost_values, performance_values, 'b', 'filled');
    hold on;
    
    if ~isempty(best_idx) && best_idx <= length(cost_values)
        plot(cost_values(best_idx), performance_values(best_idx), 'r^', ...
            'MarkerSize', 15, 'MarkerFaceColor', 'r', 'LineWidth', 2);
    end
    
    xlabel('总成本 (￥)');
    ylabel('总性能');
    title('Pareto前沿');
    legend('Pareto解', 'TOPSIS最佳解', 'Location', 'best');
    grid on;
    
    % 2. 成本分布直方图
    subplot(2, 2, 2);
    histogram(cost_values, 10);
    xlabel('总成本 (￥)');
    ylabel('频数');
    title('成本分布');
    grid on;
    
    % 3. 性能分布直方图
    subplot(2, 2, 3);
    histogram(performance_values, 10);
    xlabel('总性能');
    ylabel('频数');
    title('性能分布');
    grid on;
    
    % 4. 性价比散点图
    subplot(2, 2, 4);
    
    % 计算性价比
    valid_idx = cost_values > 0;
    if any(valid_idx)
        ratio = performance_values(valid_idx) ./ cost_values(valid_idx);
        scatter(cost_values(valid_idx), ratio, 'g', 'filled');
        
        if ~isempty(best_idx) && best_idx <= length(valid_idx) && valid_idx(best_idx)
            hold on;
            plot(cost_values(best_idx), ratio(best_idx), 'r^', ...
                'MarkerSize', 15, 'MarkerFaceColor', 'r', 'LineWidth', 2);
        end
    end
    
    xlabel('总成本 (￥)');
    ylabel('性价比 (性能/成本)');
    title('性价比分析');
    legend('Pareto解', 'TOPSIS最佳解', 'Location', 'best');
    grid on;
    
    sgtitle('优化结果');
end