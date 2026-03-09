function pop = CalcCrowdingDistance(pop, F)
    % 计算拥挤度距离
    % 输入: pop - 种群个体数组
    %       F - 前沿面数组
    % 输出: pop - 添加了拥挤度距离的种群

    nF = numel(F);
    
    for k = 1:nF
        % 获取当前前沿面的成本矩阵
        Costs = [pop(F{k}).Cost];
        
        nObj = size(Costs, 1);
        n = numel(F{k});
        
        d = zeros(n, nObj);
        
        % 对每个目标函数计算拥挤度
        for j = 1:nObj
            [cj, so] = sort(Costs(j, :));
            
            % 边界点的拥挤度设为无穷大
            d(so(1), j) = inf;
            
            % 计算中间点的拥挤度
            for i = 2:n-1
                d(so(i), j) = abs(cj(i+1) - cj(i-1)) / abs(cj(1) - cj(end));
            end
            
            d(so(end), j) = inf;
        end
        
        % 计算总拥挤度
        for i = 1:n
            pop(F{k}(i)).CrowdingDistance = sum(d(i, :));
        end
    end
end