function [cluster] = fuzzymodel(Lx, Ly, Bx, By, demandL, demandB, repox, repoy, C, K)
    % 根据Fuzzy model来进行分簇
    N = length([Lx, Bx]);        % 总节点数
    linehaulnum = length(Lx);    % linehaul节点数
    demand = [demandL, demandB]; 
    D = zeros(N,N);   % 节点间的距离
    S = zeros(N,N);   % 节点间的节约代价
    for i = 1:N
        for j = i:N
            if i <= linehaulnum
                if j<= linehaulnum
                    D(i,j) = sqrt((Lx(i)-Lx(j))^2+(Ly(i)-Ly(j))^2);
                    S(i,j) = sqrt((Lx(i)-repox)^2+(Ly(i)-repoy)^2) + ...
                             sqrt((Lx(j)-repox)^2+(Ly(j)-repoy)^2) - D(i,j);                       
                else
                    D(i,j) = sqrt((Lx(i)-Bx(j-linehaulnum))^2+(Ly(i)-By(j-linehaulnum))^2);
                    S(i,j) = sqrt((Lx(i)-repox)^2+(Ly(i)-repoy)^2) + ...
                             sqrt((Bx(j-linehaulnum)-repox)^2+(By(j-linehaulnum)-repoy)^2) - D(i,j);  
                end
            else
                D(i,j) = sqrt((Bx(i-linehaulnum)-Bx(j-linehaulnum))^2+ ...
                    (By(i-linehaulnum)-By(j-linehaulnum))^2);
                S(i,j) = sqrt((Bx(i-linehaulnum)-repox)^2+(By(i-linehaulnum)-repoy)^2) + ...
                             sqrt((Bx(j-linehaulnum)-repox)^2+(By(j-linehaulnum)-repoy)^2) - D(i,j);  
            end
            D(j,i) = D(i,j);
            S(j,i) = S(i,j);
        end
    end
    best_x_D = integermodel(linehaulnum, N, demand, C, K, D, 1);  % 节点总距离最短时的x
    best_D = sum(sum(best_x_D.*D));   % 节点最短总距离
    worst_x_D = integermodel(linehaulnum, N, demand, C, K, D, 2); % 节点总距离最长时的x
    worst_D = sum(sum(worst_x_D.*D)); % 节点最长总距离
    S_1 = sum(sum(best_x_D .* S));    % 当节点总距离最短时的节约代价
    best_x_S = integermodel(linehaulnum, N, demand, C, K, S, 2); % 节点总节约代价最大时的x
    best_S = sum(sum(best_x_S.*S)); % 最大总节约代价
    worst_x_S = integermodel(linehaulnum, N, demand, C, K, S, 1); % 最小节约代价时的x
    worst_S = sum(sum(worst_x_S.*S)); % 最小节约代价
    D_1 = sum(sum(best_x_S .* D));  % 节约代价最小时的节点距离
    miu = zeros(2,2);   % pay-off matrix
    miu(1,1) =  best_D;
    miu(1,2) = (S_1 - worst_S)/(best_S-worst_S);
    miu(2,1) = (worst_D - D_1)/(worst_D - best_D);
    miu(2,2) = best_S;
    w = sdpvar(1,2);   % 距离和节约代价加权
    v = sdpvar(1,1);
    F = [];
    F = F + [w*miu(1,:)' >= v];
    F = F + [w*miu(2,:)' >= v];
    F = F + [w(1) + w(2) == 1];
    F = F + [w(1:2) >= 0];
    ops = sdpsettings( 'solver','cplex');
    f = -v*1;
    solvesdp(F,f, ops);
    w = double(w);
    final_x = integermodel(linehaulnum, N, demand, C, K, w(1)*D-w(2)*S, 1);
%     final_x = integermodel(linehaulnum, N, demand, C, K, -S, 1);
    final_x = uint8(final_x);
    cluster = cell(K);
    clusterindex = zeros(1,K);  % seed customer标号
    count = 1;
    for i = 1:N
        if final_x(i,i) == 1
            clusterindex(count) = i;
            count = count + 1;
        end
    end
    for i = 1:K
        cluster{i} = [];
    end
    for i = 1:N
        j = find(final_x(i,:) == 1);
        kk = find(j == clusterindex);   % 找到归属于第几个seed customer
        temp = cluster{kk};
        temp = [temp, i];
        cluster{kk} = temp;
    end
    
    for i = 1:K   % 重新排列, linehaul节点在前面
        temp = cluster{i};
        sortcluster = [];
        index = find(temp <= linehaulnum);
        sortcluster = [sortcluster, temp(index)];
        sortcluster = [sortcluster, setdiff(temp, sortcluster)];
        cluster{i} = sortcluster;
    end
end

function [x] = integermodel(linehaulnum, N, demand, C, K, objective, option)
    % 计算以objective为目标函数时的整数规划问题
    % option = 1表示求最小值，=2 表示求最大值
    x = binvar(N,N,'full');
    F = [];
    for i = 1:N
        F = F + [sum(x(i,1:N)) == 1];
    end

    for j = 1:N
        F = F + [sum(demand(1:linehaulnum)*x(1:linehaulnum,j)) <= C*x(j,j)];
    end

    for j = 1:N
        F = F + [sum(demand(linehaulnum+1:N)*x(linehaulnum+1:N,j)) <= C*x(j,j)];
    end

    temp = 0;
    for i = 1:N
        temp = temp + x(i,i);
    end
    F = F + [temp == K];
    ops = sdpsettings( 'solver','cplex');
    f = sum(sum(objective.*x));
    if option == 1  % min
        solvesdp(F,f, ops);
    else  % max
        solvesdp(F,-f, ops);
    end
    x = double(x);
%     x = int8(x);
%     for i = 1:N
%         x(i,i) = 0;
%     end
end

