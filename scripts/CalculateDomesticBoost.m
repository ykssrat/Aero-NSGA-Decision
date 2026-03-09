function [boost_factor, boost_description] = CalculateDomesticBoost(domestic_count)
    % 计算国产化硬件的性能降低系数
    % 输入：domestic_count - 国产化硬件数量
    % 输出：
    %   boost_factor - 性能系数（小于1表示降低）
    %   boost_description - 描述字符串
    
    if domestic_count < 0
        error('国产化硬件数量不能为负数');
    end
    
    % 国产化数量与性能降低的对应关系（系数 = 1 - 降低百分比）
    boost_table = {
        0, 1.00, '无影响';
        1, 0.99, '降低1%';
        2, 0.97, '降低3%';
        3, 0.94, '降低6%';
        4, 0.90, '降低10%';
        5, 0.85, '降低15%';
        6, 0.79, '降低21%';
        7, 0.72, '降低28%';
    };
    
    % 如果数量超过表格范围，使用递减规则（每多一个降低7%）
    if domestic_count > 7
        boost_factor = 0.72 - (domestic_count - 7) * 0.07;
        % 防止因子变得过低，但暂时不设下限
        boost_description = sprintf('降低%.0f%%', (1 - boost_factor) * 100);
    else
        boost_factor = boost_table{domestic_count + 1, 2};
        boost_description = boost_table{domestic_count + 1, 3};
    end
end