% Goetschlcks and Jacobs-blecha�����ݼ�
clc;clear;
close all;
xrange = [0 24000];   % �����귶Χ
yrange = [0 32000];   % �����귶Χ
repox = 12000;        % �ֿ�x����
repoy = 16000;        % �ֿ�y����

N;
load NPro;
PROID = 6;

% plot([Lx, Bx], [Ly,By],'o');
% axis([0 24000 0 32000]);
% grid on;
% set(gca,'xtick', 0:3000:24000, 'ytick',0:4000:32000); 

% ������ֵ

%% cluster
capacity = capacity(PROID);
K = carnum(PROID);
[big_cluster] = fuzzymodel(Lx, Ly, Bx, By, demandL, demandB, repox, repoy, capacity, K);

%% routing
% �������
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

% ���·��
totalcost = 0;
path = cell(K);
for k = 1:K
    mem = big_cluster{k};  % ���ڳ�Ա
    memlen = length(mem);  % ���ڳ�Ա��Ŀ
    if memlen == 0   % ��·��
        path{k} = [0 0];
    else
%             save('haha.mat', 'mem','linehaulnum', 'big_cluster','k');
        linemem = mem(find(mem<=linehaulnum)); % linehaul�ڵ㣬���Զ�λ
        cdist_spot = dist_spot(mem, mem);  % ��ǰ�˿ͽڵ��ľ���
        cdist_repo = dist_repo(mem);       % ��ǰ�˿ͽڵ���ֿ�֮��ľ���
        fprintf('The path for %d cluster\n',k);
        [best_path, best_cost] = TSPB_intprog(memlen, length(linemem), cdist_spot, cdist_repo);
        totalcost = totalcost + best_cost;
        relative_pos = best_path(2:end-1);  % ��һ�������һ���ڵ��ǲֿ�
        best_path(2:end-1) = mem(relative_pos);  % ��·���еı�Ż��ɾ��Զ�λ
        path{k} = best_path;
    end
end

%% local search
[route, reducecost, routedemandL, routedemandB] = localsearch(dist_repo, dist_spot, demandL, demandB, capacity, path);   
path = route;


%% ���ս��
totalcost = totalcost + reducecost;


