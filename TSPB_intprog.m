function [best_path, best_cost] = TSPB_intprog(N, n, dist_spot, dist_repo)
    % 用整数规划求解TSPB问题
    % 先把D矩阵求出来（涵括仓库）
    D = zeros(N+1, N+1);
    D(2:N+1,2:N+1) = dist_spot;
    D(1,2:end) = dist_repo;
    D(2:end,1) = dist_repo;
    D(1,1) = inf;
    for i = 1:N+1
        D(i,i) = 10^10;
    end
    x = intvar(N+1,N+1,'full');
    u = intvar(1,N);
    f = sum(sum(D.*x));   % 目标函数
    F = [];               % 约束集
    
    % 虚拟变量u
    F = [u>=1];
    F = F + [u<=N];
    
    % x为0-1变量
    F = F + [x>=0];
    F = F + [x<=1];
    
    if n ~= N
        F = F + [sum(x(1,2:n+1)) == 1];   % 有一条边仓库到linehaul
        F = F +  [sum(sum(x(2:n+1,n+2:N+1))) == 1]; % 有一条边从linehaul到backhaul
        F = F + [sum(sum(x(n+2:N+1,2:n+1))) == 0];  % 无backhaul到linehaul的反向边
        F = F + [sum(x(n+2:N+1,1)) == 1 ];  % 有一条边从backhaul到仓库
    end
    
    % 禁止自己连自己
    for i = 1:N+1
        F = F+[x(i,i) == 0];
    end
    
    % 出度入度约束
    for i = 1:N+1
        F = F + [x(i,:)*ones(N+1,1) == 1];
        F = F + [ones(1,N+1)*x(:,i) == 1];
    end
    
    % subtour elimination constraint
    for i = 2:N+1
        for j = 2:N+1
           if i == j 
                continue;
           else
                F = F + [u(i-1) - u(j-1) + N*x(i,j) <= N-1];
           end
        end
    end
    
    ops = sdpsettings( 'solver','cplex');
    solvesdp(F,f, ops);
    x = double(x);
    x = int8(x);
    
    % record the route
    best_path = [0];
    cpos = 1;
    for i = 1:N+1
        npos = find(x(cpos,:)==1);
        best_path = [best_path, npos-1];
        cpos = npos;
    end
    best_cost = double(f);
end