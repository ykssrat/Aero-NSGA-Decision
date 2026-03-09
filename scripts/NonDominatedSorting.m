function [pop, F] = NonDominatedSorting(pop)
    % 非支配排序函数
    % 输入: pop - 种群个体数组
    % 输出: pop - 添加了Rank字段的种群
    %       F - 前沿面数组

    nPop = numel(pop);

    % 初始化每个个体的支配集和被支配计数
    for i = 1:nPop
        pop(i).DominationSet = [];
        pop(i).DominatedCount = 0;
    end
    
    F{1} = [];
    
    % 计算支配关系
    for i = 1:nPop
        for j = i+1:nPop
            p = pop(i);
            q = pop(j);
            
            % 检查p是否支配q
            if Dominates(p, q)
                p.DominationSet = [p.DominationSet j];
                q.DominatedCount = q.DominatedCount + 1;
            end
            
            % 检查q是否支配p
            if Dominates(q, p)
                q.DominationSet = [q.DominationSet i];
                p.DominatedCount = p.DominatedCount + 1;
            end
            
            pop(i) = p;
            pop(j) = q;
        end
        
        % 如果个体不被任何其他个体支配，则属于第一前沿面
        if pop(i).DominatedCount == 0
            F{1} = [F{1} i];
            pop(i).Rank = 1;
        end
    end
    
    % 构建后续的前沿面
    k = 1;
    
    while true
        Q = [];
        
        % 遍历当前前沿面的个体
        for i = F{k}
            p = pop(i);
            
            % 遍历被当前个体支配的个体
            for j = p.DominationSet
                q = pop(j);
                
                % 减少被支配计数
                q.DominatedCount = q.DominatedCount - 1;
                
                % 如果不再被任何个体支配，则加入下一前沿面
                if q.DominatedCount == 0
                    Q = [Q j]; %#ok<AGROW>
                    q.Rank = k + 1;
                end
                
                pop(j) = q;
            end
        end
        
        % 如果没有新的个体，则停止
        if isempty(Q)
            break;
        end
        
        % 添加新的前沿面
        F{k+1} = Q; %#ok<AGROW>
        k = k + 1;
    end
end