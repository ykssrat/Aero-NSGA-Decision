function b = Dominates(x, y)
    % 判断个体x是否支配个体y
    % 输入: x, y - 个体结构体或成本向量
    % 输出: b - 布尔值，true表示x支配y

    % 如果输入是结构体，提取成本
    if isstruct(x)
        x = x.Cost;
    end

    if isstruct(y)
        y = y.Cost;
    end

    % x支配y的条件：在所有目标上都不差于y，且至少在一个目标上严格优于y
    b = all(x <= y) && any(x < y);
end