function [pop, F] = SortPopulation(pop)
    % 排序种群：先按前沿面排序，再按拥挤度排序
    % 输入: pop - 种群个体数组
    % 输出: pop - 排序后的种群
    %       F - 排序后的前沿面数组

    % 按拥挤度降序排序
    [~, CDSO] = sort([pop.CrowdingDistance], 'descend');
    pop = pop(CDSO);
    
    % 按前沿面升序排序
    [~, RSO] = sort([pop.Rank]);
    pop = pop(RSO);
    
    % 更新前沿面结构
    Ranks = [pop.Rank];
    MaxRank = max(Ranks);
    F = cell(MaxRank, 1);
    for r = 1:MaxRank
        F{r} = find(Ranks == r);
    end
end