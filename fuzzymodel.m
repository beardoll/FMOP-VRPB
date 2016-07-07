function [] = fuzzymodel(Lx, Ly, Bx, By, demandL, demandB, repox, repoy, C, K)
N = length([Lx, Bx]);
linehaulnum = length(Lx);
demand = [demandL, demandB];
D = zeros(N,N);
S = zeros(N,N);
for i = 1:N
    D(i,i) = -inf;
    S(i,i) = 0;
    for j = i+1:N
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
solvesdp(F,f, ops);
x = double(x);
x = int8(x);
