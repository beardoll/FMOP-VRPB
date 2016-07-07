% Goetschlcks and Jacobs-blecha的数据集
clc;clear;
close all;
xrange = [0 24000];   % 横坐标范围
yrange = [0 32000];   % 纵坐标范围
repox = 12000;        % 仓库x坐标
repoy = 16000;        % 仓库y坐标

N;
load NPro;
PROID = 6;

% plot([Lx, Bx], [Ly,By],'o');
% axis([0 24000 0 32000]);
% grid on;
% set(gca,'xtick', 0:3000:24000, 'ytick',0:4000:32000); 

% 函数赋值

%% cluster
capacity = capacity(PROID);
K = carnum(PROID);
[big_cluster] = fuzzymodel(Lx, Ly, Bx, By, demandL, demandB, repox, repoy, capacity, K);

%% routing
% 计算距离
linehaulnum = length([Lx]);
backhaulnum = length([Bx]);
dist_spot = zeros(linehaulnum+backhaulnum, linehaulnum+backhaulnum);
dist_repo = zeros(1, linehaulnum+backhaulnum);
for i = 1:length(dist_repo)
    if i <= linehaulnum
        dist_repo(i) = sqrt((Lx(i) - repox)^2 + (Ly(i) - repoy)^2);
    else
        dist_repo(i) = sqrt((Bx(i-linehaulnum) - repox)^2 + (By(i-linehaulnum) -repoy)^2);
    end
end

for i = 1:length(dist_repo)
    for j = i:length(dist_repo)
        if i == j
            dist_spot(i,j) = inf;
        else
            if i<=linehaulnum
                if j <= linehaulnum
                    dist_spot(i,j) = sqrt((Lx(i) - Lx(j))^2 + (Ly(i) - Ly(j))^2);
                else
                    dist_spot(i,j) = sqrt((Lx(i) - Bx(j-linehaulnum))^2 + (Ly(i) - By(j-linehaulnum))^2);
                end
            else
                dist_spot(i,j) = sqrt((Bx(i-linehaulnum) - Bx(j-linehaulnum))^2 + (By(i-linehaulnum) - By(j-linehaulnum))^2);
            end
        end
        dist_spot(j,i) = dist_spot(i,j);
    end
end

% 求解路径
totalcost = 0;
path = cell(K);
for k = 1:K
    mem = big_cluster{k};  % 簇内成员
    memlen = length(mem);  % 簇内成员数目
    if memlen == 0   % 空路径
        path{k} = [0 0];
    else
%             save('haha.mat', 'mem','linehaulnum', 'big_cluster','k');
        linemem = mem(find(mem<=linehaulnum)); % linehaul节点，绝对定位
        cdist_spot = dist_spot(mem, mem);  % 当前顾客节点间的距离
        cdist_repo = dist_repo(mem);       % 当前顾客节点与仓库之间的距离
        fprintf('The path for %d cluster\n',k);
        [best_path, best_cost] = TSPB_intprog(memlen, length(linemem), cdist_spot, cdist_repo);
        totalcost = totalcost + best_cost;
        relative_pos = best_path(2:end-1);  % 第一个和最后一个节点是仓库
        best_path(2:end-1) = mem(relative_pos);  % 将路径中的标号换成绝对定位
        path{k} = best_path;
    end
end

%% local search
[route, reducecost, routedemandL, routedemandB] = localsearch(dist_repo, dist_spot, demandL, demandB, capacity, path);   
path = route;


%% 最终结果
totalcost = totalcost + reducecost;


