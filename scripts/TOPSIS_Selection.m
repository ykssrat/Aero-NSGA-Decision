function best_idx = TOPSIS_Selection(decision_matrix, weights)
    % TOPSIS方法选择最佳解
    % decision_matrix: 决策矩阵 (n个解 × m个指标)
    % weights: 权重向量 (1 × m)
    
    % 确保权重和为1
    weights = weights / sum(weights);
    
    % 标准化决策矩阵
    normalized_matrix = decision_matrix ./ sqrt(sum(decision_matrix.^2, 1));
    
    % 加权标准化矩阵
    weighted_matrix = normalized_matrix .* weights;
    
    % 确定理想解和负理想解
    % 对于成本：越小越好；对于性能：越大越好
    ideal_solution = [min(weighted_matrix(:,1)), max(weighted_matrix(:,2))];
    negative_ideal_solution = [max(weighted_matrix(:,1)), min(weighted_matrix(:,2))];
    
    % 计算每个解到理想解和负理想解的距离
    n = size(weighted_matrix, 1);
    d_plus = zeros(n, 1);
    d_minus = zeros(n, 1);
    
    for i = 1:n
        d_plus(i) = sqrt(sum((weighted_matrix(i,:) - ideal_solution).^2));
        d_minus(i) = sqrt(sum((weighted_matrix(i,:) - negative_ideal_solution).^2));
    end
    
    % 计算相对接近度
    closeness = d_minus ./ (d_plus + d_minus);
    
    % 选择相对接近度最大的解
    [~, best_idx] = max(closeness);
end