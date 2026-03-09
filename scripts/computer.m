%% 通用多目标优化系统 - NSGA-II + TOPSIS（通用版本）
clear; clc; close all;

%% ==== 1. 用户选择是否需要参数7（特殊变量） ====
fprintf('========== 通用多目标优化系统 ==========\n');
fprintf('请选择是否需要参数7（对应最后一个决策变量）：\n');
fprintf('1. 需要参数7\n');
fprintf('2. 不需要参数7\n');

choice = input('请输入选择（1/2）：', 's');
choice = str2double(choice);

if choice == 1
    fprintf('正在优化包含参数7的配置...\n');
    param7_option = 1;
else
    fprintf('正在优化不包含参数7的配置...\n');
    param7_option = 2;
end

%% ==== 2. 定义问题结构 ====
PC_Problem.DisplayNames = {'参数1', '参数2', '参数3', '参数4', '参数5', '参数6', '参数7'};
PC_Problem.FieldNames = {'Param1', 'Param2', 'Param3', 'Param4', 'Param5', 'Param6', 'Param7'};
PC_Problem.nVar = length(PC_Problem.FieldNames);
PC_Problem.VarSize = [1 PC_Problem.nVar];

%% ==== 3. 筛选条件输入 ====
fprintf('\n=== 配置筛选条件 ===\n');

% 询问统一的属性3需求（例如抗电磁干扰）
fprintf('请选择是否需要属性3 (1-需要, 2-不需要, 3-不限制): ');
attr3_input = input('');
if attr3_input == 1
    attr3_choice = 1;
elseif attr3_input == 2
    attr3_choice = 0;
else
    attr3_choice = -1;
end

% 为每个参数单独询问属性4和属性5需求
param_filters = struct();

for i = 1:PC_Problem.nVar
    disp_name = PC_Problem.DisplayNames{i};
    field_name = PC_Problem.FieldNames{i};
    
    % 如果不需要参数7且当前是参数7，则跳过
    if strcmp(field_name, 'Param7') && param7_option == 2
        param_filters.Param7.attr4 = 0;  % 属性4设为0
        param_filters.Param7.attr5 = 0;  % 属性5设为0
        continue;
    end
    
    fprintf('设置 %s 的筛选条件：\n', disp_name);
    
    fprintf('  是否需要属性4（国产化）(1-需要, 2-不需要, 3-不限制): ');
    attr4_input = input('');
    if attr4_input == 1
        attr4 = 1;
    elseif attr4_input == 2
        attr4 = 0;
    else
        attr4 = -1;
    end
    
    fprintf('  是否需要属性5（飞行经历）(1-需要, 2-不需要, 3-不限制): ');
    attr5_input = input('');
    if attr5_input == 1
        attr5 = 1;
    elseif attr5_input == 2
        attr5 = 0;
    else
        attr5 = -1;
    end
    
    param_filters.(field_name).attr4 = attr4;
    param_filters.(field_name).attr5 = attr5;
end

% ==================== 数据库定义 ====================
% 每个参数有10个样本，每个样本5个属性：[成本, 性能, 属性3, 属性4, 属性5]
% 注意：属性3、属性4、属性5的值均为0或1，代表是否具备该属性

%% 从配置文件加载数据库
% 数据存储在 config/data.json 中，包含 Components_WithCase 和 Components_WithoutCase
config_path = fullfile(fileparts(mfilename('fullpath')), '..', 'config', 'data.json');
json_text = fileread(config_path);
db = jsondecode(json_text);

% 将JSON解析的cell数组转换为数值矩阵，赋值给 PC_Problem
param_names = fieldnames(db.Components_WithCase);
for idx = 1:numel(param_names)
    pname = param_names{idx};
    % WithCase 数据
    raw = db.Components_WithCase.(pname);
    if iscell(raw)
        PC_Problem.Components_WithCase.(pname) = cell2mat(cellfun(@(r) r(:)', raw, 'UniformOutput', false));
    else
        PC_Problem.Components_WithCase.(pname) = raw;
    end
    % WithoutCase 数据
    raw = db.Components_WithoutCase.(pname);
    if iscell(raw)
        PC_Problem.Components_WithoutCase.(pname) = cell2mat(cellfun(@(r) r(:)', raw, 'UniformOutput', false));
    else
        PC_Problem.Components_WithoutCase.(pname) = raw;
    end
end

%% ==== 4. 根据筛选条件预处理数据库 ====
fprintf('\n正在根据筛选条件处理数据库...\n');

% 筛选函数
function filtered_indices = filter_components(component_data, attr3_req, attr4_req, attr5_req)
    % 返回符合筛选条件的样本索引
    indices = [];
    for j = 1:size(component_data, 1)
        % 检查条件：属性3、属性4、属性5
        % 如果某个条件为-1，则表示不限制
        attr3_ok = (attr3_req == -1) || (component_data(j, 3) == attr3_req);
        attr4_ok = (attr4_req == -1) || (component_data(j, 4) == attr4_req);
        attr5_ok = (attr5_req == -1) || (component_data(j, 5) == attr5_req);
        
        if attr3_ok && attr4_ok && attr5_ok
            indices = [indices, j];
        end
    end
    filtered_indices = indices;
end

% 筛选需要参数7的数据库
filtered_WithCase = struct();
for i = 1:PC_Problem.nVar
    field_name = PC_Problem.FieldNames{i};
    data = PC_Problem.Components_WithCase.(field_name);
    
    % 获取该参数的筛选条件
    if isfield(param_filters, field_name)
        attr4_req = param_filters.(field_name).attr4;
        attr5_req = param_filters.(field_name).attr5;
    else
        % 如果没有设置，则默认为不限制（-1）
        attr4_req = -1;
        attr5_req = -1;
    end
    
    filtered_idx = filter_components(data, attr3_choice, attr4_req, attr5_req);
    
    if isempty(filtered_idx)
        fprintf('警告：参数 %s 没有符合筛选条件的样本，将使用所有样本\n', PC_Problem.DisplayNames{i});
        filtered_idx = 1:size(data, 1);
    end
    
    filtered_WithCase.(field_name).data = data(filtered_idx, :);
    filtered_WithCase.(field_name).original_indices = filtered_idx;
end

% 筛选不需要参数7的数据库
filtered_WithoutCase = struct();
for i = 1:PC_Problem.nVar
    field_name = PC_Problem.FieldNames{i};
    data = PC_Problem.Components_WithoutCase.(field_name);
    
    % 获取该参数的筛选条件
    if isfield(param_filters, field_name)
        attr4_req = param_filters.(field_name).attr4;
        attr5_req = param_filters.(field_name).attr5;
    else
        attr4_req = -1;
        attr5_req = -1;
    end
    
    filtered_idx = filter_components(data, attr3_choice, attr4_req, attr5_req);
    
    if isempty(filtered_idx)
        fprintf('警告：参数 %s 没有符合筛选条件的样本，将使用所有样本\n', PC_Problem.DisplayNames{i});
        filtered_idx = 1:size(data, 1);
    end
    
    filtered_WithoutCase.(field_name).data = data(filtered_idx, :);
    filtered_WithoutCase.(field_name).original_indices = filtered_idx;
end

PC_Problem.FilteredComponents_WithCase = filtered_WithCase;
PC_Problem.FilteredComponents_WithoutCase = filtered_WithoutCase;

% 设置变量范围（基于筛选后的样本数）
PC_Problem.VarMin = ones(1, PC_Problem.nVar);
PC_Problem.VarMax = zeros(1, PC_Problem.nVar);

for i = 1:PC_Problem.nVar
    field_name = PC_Problem.FieldNames{i};
    if param7_option == 1
        PC_Problem.VarMax(i) = size(filtered_WithCase.(field_name).data, 1);
    else
        PC_Problem.VarMax(i) = size(filtered_WithoutCase.(field_name).data, 1);
    end
end

% 第7个变量（参数7）的特殊处理
if param7_option == 1
    PC_Problem.VarMin(7) = 1;
    PC_Problem.VarMax(7) = max(1, PC_Problem.VarMax(7));
else
    PC_Problem.VarMin(7) = 0;
    PC_Problem.VarMax(7) = 0;
end

%% ==== 5. 定义空个体结构体 ====
empty_individual.Position = [];
empty_individual.Cost = [];
empty_individual.Rank = [];
empty_individual.DominationSet = [];
empty_individual.DominatedCount = [];
empty_individual.CrowdingDistance = [];

%% ==== 6. NSGA-II 参数设置 ====
MaxIt = 100;          % 最大迭代次数
nPop = 100;           % 种群大小
pCrossover = 0.8;     % 交叉概率
nCrossover = 2 * round(pCrossover * nPop / 2);  % 交叉个体数（确保偶数）
pMutation = 0.3;      % 变异概率
nMutation = round(pMutation * nPop);             % 变异个体数
mutationRate = 0.15;  % 变异率

% 早停机制参数
patience = 15;        % 容忍代数（连续多少代前沿无变化则停止）
stall_generations = 0; % 停滞代数计数器
best_front_costs = []; % 记录上一代的最优解代价矩阵

%% ==== 7. 设置目标函数并初始化种群 ====
CostFunction = @(x) PC_CostFunction_Filtered(x, PC_Problem, param7_option);

% 获取目标函数数量
test_solution = zeros(1, PC_Problem.nVar);
for i = 1:PC_Problem.nVar
    if i == 7 && param7_option == 2
        test_solution(i) = 0;
    else
        test_solution(i) = 1;
    end
end
nObj = numel(CostFunction(test_solution));

% 初始化种群
pop = repmat(empty_individual, nPop, 1);

for i = 1:nPop
    pop(i).Position = zeros(1, PC_Problem.nVar);
    for j = 1:PC_Problem.nVar
        if j == 7  % 第7个变量
            if param7_option == 1
                pop(i).Position(j) = 1;  % 需要参数7
            else
                pop(i).Position(j) = 0;  % 不需要参数7
            end
        else
            % 在有效范围内随机选择型号
            pop(i).Position(j) = randi([PC_Problem.VarMin(j), PC_Problem.VarMax(j)]);
        end
    end
    
    % 评估目标函数
    pop(i).Cost = CostFunction(pop(i).Position);
end

% 统计参数7的分布
case_counts = zeros(2, 1);
for i = 1:nPop
    if pop(i).Position(7) == 1
        case_counts(1) = case_counts(1) + 1;
    else
        case_counts(2) = case_counts(2) + 1;
    end
end
fprintf('需要参数7的个体数量: %d (%.1f%%)\n', case_counts(1), case_counts(1)/nPop*100);
fprintf('不需要参数7的个体数量: %d (%.1f%%)\n', case_counts(2), case_counts(2)/nPop*100);

% 非支配排序
[pop, F] = NonDominatedSorting(pop);

% 计算拥挤度距离
pop = CalcCrowdingDistance(pop, F);

% 排序种群
[pop, F] = SortPopulation(pop);

%% ==== 8. NSGA-II 主循环 ====
fprintf('\n开始NSGA-II优化...\n');

for it = 1:MaxIt
    fprintf('Generation %d/%d\n', it, MaxIt);
    
    % 交叉
    popc = repmat(empty_individual, nCrossover/2, 2);
    for k = 1:nCrossover/2
        i1 = randi([1 nPop]);
        p1 = pop(i1);
        
        i2 = randi([1 nPop]);
        p2 = pop(i2);
        
        [popc(k, 1).Position, popc(k, 2).Position] = ...
            IntegerCrossover_Filtered(p1.Position, p2.Position, PC_Problem.VarMin, PC_Problem.VarMax, param7_option);
        
        popc(k, 1).Cost = CostFunction(popc(k, 1).Position);
        popc(k, 2).Cost = CostFunction(popc(k, 2).Position);
    end
    popc = popc(:);
    
    % 变异
    popm = repmat(empty_individual, nMutation, 1);
    for k = 1:nMutation
        i = randi([1 nPop]);
        p = pop(i);
        
        popm(k).Position = IntegerMutate_Filtered(p.Position, mutationRate, PC_Problem.VarMin, PC_Problem.VarMax, param7_option);
        
        popm(k).Cost = CostFunction(popm(k).Position);
    end
    
    % 合并种群
    pop = [pop; popc; popm];
    
    % 非支配排序
    [pop, F] = NonDominatedSorting(pop);
    
    % 计算拥挤度距离
    pop = CalcCrowdingDistance(pop, F);
    
    % 排序种群
    pop = SortPopulation(pop);
    
    % 截断到原始大小
    pop = pop(1:nPop);
    
    % 重新排序
    [pop, F] = NonDominatedSorting(pop);
    pop = CalcCrowdingDistance(pop, F);
    [pop, F] = SortPopulation(pop);
    
    % 获取Pareto前沿
    F1 = pop(F{1});
    
    fprintf('迭代 %d: Pareto前沿解数量 = %d\n', it, numel(F1));
    
    % ---- 早停机制检测 ----
    % 提取当前 Rank 1 的成本数据进行对比
    current_front_costs = reshape([F1.Cost], [], numel(F1))';
    % 排序以便于精确对比（按照成本从小到大）
    current_front_costs = sortrows(current_front_costs);
    
    % 比较当前前沿的解集是否与历史最优解集完全一致
    if isequal(current_front_costs, best_front_costs)
        stall_generations = stall_generations + 1;
    else
        stall_generations = 0;
        best_front_costs = current_front_costs;
    end
    
    if stall_generations >= patience
        fprintf('连续 %d 代 Pareto 前沿解集无变化，系统已收敛，触发早停机制（Early Stopping）！\n', patience);
        PlotPCFront(F1, it);
        drawnow;
        break;
    end
    % --------------------
    
    if mod(it, 20) == 0 || it == MaxIt
        PlotPCFront(F1, it);
        drawnow;
    end
end

%% ==== 9. 结果分析 ====
fprintf('\n=== NSGA-II优化完成 ===\n');
fprintf('Pareto前沿解数量: %d\n', numel(F1));

pareto_pop = F1;
if ~isempty(pareto_pop)
    pareto_costs = [];
    for i = 1:numel(pareto_pop)
        cost_vec = pareto_pop(i).Cost(:)';
        if numel(cost_vec) == 1
            cost_vec = [cost_vec, 0];
        elseif numel(cost_vec) > 2
            cost_vec = cost_vec(1:2);
        end
        pareto_costs = [pareto_costs; cost_vec];
    end
    
    pareto_solutions = zeros(PC_Problem.nVar, numel(pareto_pop));
    for i = 1:numel(pareto_pop)
        pareto_solutions(:, i) = pareto_pop(i).Position(:);
    end
    
    if size(pareto_costs, 2) >= 2
        cost_values = pareto_costs(:, 1);
        performance_values = -pareto_costs(:, 2);  % 性能取负还原
    else
        cost_values = pareto_costs(:, 1);
        performance_values = zeros(size(cost_values));
    end
else
    error('Pareto前沿为空，无法继续优化');
end

%% ==== 10. TOPSIS 决策分析 ====
fprintf('\n=== TOPSIS 决策分析 ===\n');

weights = [0.3, 0.7];  % [成本权重, 性能权重]

best_idx = TOPSIS_Selection([cost_values, performance_values], weights);

if best_idx > numel(pareto_pop) || best_idx < 1
    error('TOPSIS选择索引无效: %d', best_idx);
end

best_solution = pareto_pop(best_idx).Position;
best_cost = cost_values(best_idx);
best_performance = performance_values(best_idx);

% 显示最佳配置
DisplayPCConfiguration_Filtered(best_solution, PC_Problem, param7_option, best_cost, best_performance, attr3_choice, param_filters);

% 绘制最终结果
PlotFinalResults(cost_values, performance_values, best_idx);

%% ==== 11. 保存结果到文件 ====
SaveResultsToFile_Filtered(pareto_solutions, pareto_costs, best_solution, best_cost, best_performance, PC_Problem, param7_option, attr3_choice, param_filters);