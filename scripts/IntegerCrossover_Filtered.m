function [child1, child2] = IntegerCrossover_Filtered(parent1, parent2, VarMin, VarMax, case_option)
    % 整数交叉操作（适应筛选后的数据库）
    % 支持单点交叉，确保机箱变量符合case_option
    
    % 确保是行向量
    parent1 = parent1(:)';
    parent2 = parent2(:)';
    
    nVar = length(parent1);
    child1 = parent1;
    child2 = parent2;
    
    % 随机选择交叉点（不交叉机箱变量）
    cross_point = randi([1, nVar-2]); % 避免在最后一个变量（机箱）处交叉
    
    % 执行单点交叉
    child1(1:cross_point) = parent1(1:cross_point);
    child1(cross_point+1:end-1) = parent2(cross_point+1:end-1);
    
    child2(1:cross_point) = parent2(1:cross_point);
    child2(cross_point+1:end-1) = parent1(cross_point+1:end-1);
    
    % 确保机箱变量符合用户选择
    if case_option == 1
        child1(end) = 1;  % 有机箱
        child2(end) = 1;
    else
        child1(end) = 0;  % 无机箱
        child2(end) = 0;
    end
    
    % 确保在合法范围内
    child1 = max(VarMin, min(VarMax, round(child1)));
    child2 = max(VarMin, min(VarMax, round(child2)));
    
    % 确保组件索引是整数
    child1 = round(child1);
    child2 = round(child2);
end