function [cluster] = fuzzymodel(Lx, Ly, Bx, By, demandL, demandB, repox, repoy, C, K)
    N = length([Lx, Bx]);
    linehaulnum = length(Lx);
    demand = [demandL, demandB];
    D = zeros(N,N);
    S = zeros(N,N);
    for i = 1:N
        for j = i:N
            if i <= linehaulnum
                if j<= linehaulnum
                    D(i,j) = sqrt((Lx(i)-Lx(j)^2)+(Ly(i)-Ly(j)^2));
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
    best_x_D = integermodel(linehaulnum, N, demand, C, K, D, 1);
    worst_x_D = integermodel(linehaulnum, N, demand, C, K, D, 2);
    S_1 = sum(sum(best_x_D * S));
    best_x_S = integermodel(linehaulnum, N, demand, C, K, S, 2);
    worst_x_S = integermodel(linehaulnum, N, demand, C, K, S, 1);
    D_1 = sum(sum(best_x_S * D));
    miu2 = (S_1 - worst_x_S)/(best_x_S-worst_x_S);
    miu1 = (worst_x_D - D_1)/(worst_x_D - best_x_D);
    miu = [miu1, miu2];
    w = sqdvar(1,2);
    F = [];
    F = F + [w*miu' <= v];
    F = F + [w(1) + w(2) == 1];
    F = F + [w >= 0];
    ops = sdpsettings( 'solver','cplex');
    w = solve(F,-f, ops);
    w = double(w);
    final_x = integermodel(linehaulnum, N, demand, C, K, w(1)*D-w(2)*S, 1);
    cluster = cell(K);
    for i = 1:K
        cluster{i} = [];
    end
    for i = 1:N
        j = find(final_x(i,:) == 1);
        cluster{j} = [cluster{j}, i];
    end
    
    for i = 1:K   % ÷ÿ–¬≈≈¡–
        temp = cluster{i};
        sortcluster = [];
        index = find(temp <= linehaulnum);
        sortcluster = [sortcluster, temp(index)];
        sortcluster = [sortcluster, setdiff(temp, sortcluster)];
    end
    cluster = sortcluster;
end

function [x] = integermodel(linehaulnum, N, demand, C, K, objective, option)
    x = intvar(N,N,'full');
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
    x = int8(x);
%     for i = 1:N
%         x(i,i) = 0;
%     end
end

