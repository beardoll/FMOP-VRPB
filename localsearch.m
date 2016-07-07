function [route, reducecost, routedemandL, routedemandB] = localsearch(dist_repo, dist_spot, demandL, demandB, capacity, route)
    % 基于欧式距离分簇的局部搜索算法
    % 对route中的路径进行节点间的交换/路径间的交换
    M = size(dist_spot,1);
    D = zeros(M+1, M+1);
    D(1,2:end) = dist_repo;  % 标号为1的表示仓库
    D(2:end,1) = dist_repo;
    D(1,1) = inf;
    D(2:M+1,2:M+1) = dist_spot; % 顾客节点从2开始

    linehaulnum = length(demandL);

    K = length(route);

    routedemandL = zeros(1,K);   % 各路径的Linehaul节点负担
    routedemandB = zeros(1,K);   % 个路径的backhaul节点负担
    reducecost = 0;

    for i = 1:K
        r = route{i};
        routelen = length(r);
        temp1 = 0;
        temp2 = 0;
        if routelen > 2   % 当路径长度大于2时（有2个点是仓库节点）才有意义
            for j = 2:routelen-1
                cpos = r(j);
                if cpos <= linehaulnum
                    temp1 = temp1 + demandL(cpos);
                else
                    temp2 = temp2 + demandB(cpos-linehaulnum);
                end
            end
        end
        routedemandL(i) = temp1;
        routedemandB(i) = temp2;
    end

    maxsc = -1;
    alpha = 1000;  % 惩罚因子，惩罚超载
    while abs(maxsc) > 10^(-6)
        maxsc = inf;
        for i = 1:K
            croute = route{i};  % 路径，首尾都是仓库节点，注意仓库节点标号为0
            remainindex = setdiff(1:K,i);  % 其他的路径
            len = length(croute); % 路径长度，包括首尾的仓库节点
            ordemandL = routedemandL(i);
            ordemandB = routedemandB(i);
            restdemandL = sum(ordemandL);   % 为了路径交换而准备
            restdemandB = sum(ordemandB);
            for j = 2:len-1   % 遍历所有的顾客节点
                ppos = croute(j-1);  % 前节点
                cpos = croute(j);    % 当前节点
                npos = croute(j+1);  % 后继节点
                if cpos <= linehaulnum  % cpos是linehaul节点
                    cdemand = demandL(cpos);  % 当前要交换的顾客节点的代价
                    restdemandL = restdemandL - cdemand;
                else
                    cdemand = demandB(cpos-linehaulnum);
                    restdemandB = restdemandB - cdemand;
                end
                for k = 1:length(remainindex)
                    frroute = route{remainindex(k)};  % 要进行交换操作的路径
                    frlen = length(frroute);
                    frdemandL = routedemandL(remainindex(k));   % 要进行交换操作路径的linehaul负担
                    frdemandB = routedemandB(remainindex(k));   % 要进行交换操作路径的backhaul负担
                    frrestdemandL = sum(frdemandL);
                    frrestdemandB = sum(frdemandB);
                    for m = 2:frlen - 1
                        frppos = frroute(m-1);        % 前节点
                        frcpos = frroute(m);          % 当前节点
                        frnpos = frroute(m+1);        % 后继节点
%                         save('hehe','frroute');
% %                         frroute
                        if frcpos <= linehaulnum  % frcpos是linehaul节点
                            if frcpos == 0
                                frcdemand = 0;
                            else
                                frcdemand = demandL(frcpos);
                                frrestdemandL = frrestdemandL - frcdemand;
                            end
                        else
                            frcdemand = demandB(frcpos-linehaulnum);
                            frrestdemandB = frrestdemandB - frcdemand;
                        end
                        if cpos <= linehaulnum && npos <= linehaulnum  % 要送走的边是linehaul边
                            if frcpos <= linehaulnum  % 要求插入到linehaul边或者接口边
                                penalty1 = max(frdemandL + cdemand - capacity, 0) * alpha;  % 超载惩罚
                                csc1 = -D(ppos+1,cpos+1) - D(cpos+1,npos+1) + D(ppos+1,npos+1) + ...
                                      D(frcpos+1, cpos+1) + D(cpos+1,frnpos+1) - D(frcpos+1,frnpos+1) + penalty1;
                                if csc1 < maxsc
                                    best.operation = 1;  % insert;
                                    best.interchangeroute = [i,remainindex(k)];  % 进行交换的两条路径
                                    best.pos = [cpos, frcpos];  % 进行交换的具体位置，第一个是被交换
                                    best.demand = [ordemandL-cdemand, ordemandB, frdemandL+cdemand, frdemandB];  % 交换后的路径代价
                                    maxsc = csc1;
                                end
                                penalty2 = (max(ordemandL - restdemandL + frrestdemandL - capacity, 0) + ...
                                           max(ordemandB - restdemandB + frrestdemandB - capacity, 0) + ...
                                           max(frdemandL - frrestdemandL + restdemandL - capacity, 0) + ...
                                           max(frdemandB - frrestdemandB + restdemandB - capacity, 0)) * alpha;
                                csc2 = -D(cpos+1, npos+1) - D(frcpos+1, frnpos+1) + ...
                                       +D(cpos+1, frnpos+1) + D(frcpos+1, npos+1)+penalty2;
                                if csc2 < maxsc
                                    best.operation = 2;  % interchange
                                    best.interchangeroute = [i,remainindex(k)];  % 进行交换的两条路径
                                    best.pos = [cpos, frcpos];      % 进行交换的具体位置，第一个是被交换
                                    best.demand = [ordemandL - restdemandL + frrestdemandL,ordemandB - restdemandB + frrestdemandB ...
                                                   frdemandL - frrestdemandL + restdemandL, frdemandB - frrestdemandB + restdemandB];
                                    maxsc = csc2; 
                                end
                                penalty3 = (max(ordemandL-cdemand+frcdemand-capacity, 0) + ...
                                           max(frdemandL-frcdemand+cdemand-capacity, 0))*alpha;
                                csc3 = -D(ppos+1, cpos+1)-D(cpos+1,npos+1)+D(ppos+1,frcpos+1)+D(frcpos+1,npos+1) ...
                                       -D(frppos+1,frcpos+1)-D(frcpos+1,frnpos+1)+D(frppos+1,cpos+1)+D(cpos+1,frnpos+1)+penalty3;
                                if csc3 < maxsc
                                    best.operation = 3;  % interchange
                                    best.interchangeroute = [i,remainindex(k)];  % 进行交换的两条路径
                                    best.pos = [cpos, frcpos];      % 进行交换的具体位置，第一个是被交换
                                    best.demand = [ordemandL - cdemand+frcdemand,ordemandB...
                                                   frdemandL - frcdemand + cdemand, frdemandB];
                                    maxsc = csc3; 
                                end   
                            end
                        elseif cpos > linehaulnum % 要送走的边是backhaul边
                            if ppos <= linehaulnum  % 接口边,cpos是后端
                                if frcpos <= linehaulnum  && frnpos > linehaulnum % 接口边前端
                                    if m > 2 % 不允许把唯一的linehaul节点换走
                                        penalty3 = (max(ordemandL+frcdemand-capacity, 0) + ...
                                                   max(frdemandB+cdemand-capacity, 0)) * alpha;
                                        csc3 = -D(ppos+1, cpos+1)-D(cpos+1,npos+1)+D(ppos+1,frcpos+1)+D(frcpos+1,npos+1) ...
                                               -D(frppos+1,frcpos+1)-D(frcpos+1,frnpos+1)+D(frppos+1,cpos+1)+D(cpos+1,frnpos+1)+penalty3;
                                        if csc3 < maxsc
                                            best.operation = 3;  % interchange
                                            best.interchangeroute = [i,remainindex(k)];  % 进行交换的两条路径
                                            best.pos = [cpos, frcpos];      % 进行交换的具体位置，第一个是被交换
                                            best.demand = [ordemandL + frcdemand,ordemandB-cdemand
                                                       frdemandL - frcdemand, frdemandB+cdemand];
                                            maxsc = csc3; 
                                        end
                                    end
                                elseif frcpos > linehaulnum  % 接口边后端或者纯backhaul边
                                    penalty3 = (max(ordemandB-cdemand+frcdemand-capacity, 0) + ...
                                                max(frdemandB-frcdemand+cdemand-capacity, 0))*alpha;
                                    csc3 = -D(ppos+1, cpos+1)-D(cpos+1,npos+1)+D(ppos+1,frcpos+1)+D(frcpos+1,npos+1) ...
                                           -D(frppos+1,frcpos+1)-D(frcpos+1,frnpos+1)+D(frppos+1,cpos+1)+D(cpos+1,frnpos+1)+penalty3;
                                    if csc3 < maxsc
                                        best.operation = 3;  % interchange
                                        best.interchangeroute = [i,remainindex(k)];  % 进行交换的两条路径
                                        best.pos = [cpos, frcpos];      % 进行交换的具体位置，第一个是被交换
                                        best.demand = [ordemandL, ordemandB-cdemand+frcdemand
                                                       frdemandL, frdemandB-frcdemand+cdemand];
                                        maxsc = csc3; 
                                    end
                                end
                            else % 纯backhaul边，只能与backhaul边或者接口边后端交换
                                if frcpos > linehaulnum
                                    penalty3 = (max(ordemandB-cdemand+frcdemand-capacity, 0) + ...
                                                max(frdemandB-frcdemand+cdemand-capacity, 0))*alpha;
                                    csc3 = -D(ppos+1, cpos+1)-D(cpos+1,npos+1)+D(ppos+1,frcpos+1)+D(frcpos+1,npos+1) ...
                                           -D(frppos+1,frcpos+1)-D(frcpos+1,frnpos+1)+D(frppos+1,cpos+1)+D(cpos+1,frnpos+1)+penalty3;
                                    if csc3 < maxsc
                                        best.operation = 3;  % interchange
                                        best.interchangeroute = [i,remainindex(k)];  % 进行交换的两条路径
                                        best.pos = [cpos, frcpos];      % 进行交换的具体位置，第一个是被交换
                                        best.demand = [ordemandL, ordemandB-cdemand+frcdemand
                                                       frdemandL, frdemandB-frcdemand+cdemand];
                                        maxsc = csc3; 
                                    end
                                end
                            end
                            if frcpos <= linehaulnum && frnpos <= linehaulnum  % 要插入的原连接边是linehaul边，则不允许
                                continue;
                            else
                                penalty1 = max(frdemandB + cdemand - capacity, 0) * alpha;  % 超载惩罚
                                csc1 = -D(ppos+1,cpos+1) - D(cpos+1,npos+1) + D(ppos+1,npos+1) + ...
                                      D(frcpos+1, cpos+1) + D(cpos+1,frnpos+1) - D(frcpos+1,frnpos+1) + penalty1;
                                if csc1 < maxsc
                                    best.operation = 1;  % insert;
                                    best.interchangeroute = [i,remainindex(k)];  % 进行交换的两条路径
                                    best.pos = [cpos, frcpos];  % 进行交换的具体位置，第一个是被交换
                                    best.demand = [ordemandL, ordemandB-cdemand, frdemandL, frdemandB+cdemand];  % 交换后的路径代价
                                    maxsc = csc1;
                                end
                                penalty2 = (max(ordemandL - restdemandL + frrestdemandL - capacity, 0) + ...
                                           max(ordemandB - restdemandB + frrestdemandB - capacity, 0) + ...
                                           max(frdemandL - frrestdemandL + restdemandL - capacity, 0) + ...
                                           max(frdemandB - frrestdemandB + restdemandB - capacity, 0)) * alpha;
                                csc2 = -D(cpos+1, npos+1) - D(frcpos+1, frnpos+1) + ...
                                       +D(cpos+1, frnpos+1) + D(frcpos+1, npos+1)+penalty2;
                                if csc2 < maxsc
                                    best.operation = 2;  % interchange
                                    best.interchangeroute = [i,remainindex(k)];  % 进行交换的两条路径
                                    best.pos = [cpos, frcpos];      % 进行交换的具体位置，第一个是被交换
                                    best.demand = [ordemandL - restdemandL + frrestdemandL,ordemandB - restdemandB + frrestdemandB ...
                                                   frdemandL - frrestdemandL + restdemandL, frdemandB - frrestdemandB + restdemandB];
                                    maxsc = csc2; 
                                end
                            end
                        elseif  cpos <= linehaulnum && npos > linehaulnum % 要送走的边是接口边，cpos是接口边的前端
                            if frcpos <= linehaulnum  % linehaul边或者接口边前端
                                penalty3 = (max(ordemandL-cdemand+frcdemand-capacity, 0) + ...
                                           max(frdemandL-frcdemand+cdemand-capacity, 0))*alpha;
                                csc3 = -D(ppos+1, cpos+1)-D(cpos+1,npos+1)+D(ppos+1,frcpos+1)+D(frcpos+1,npos+1) ...
                                       -D(frppos+1,frcpos+1)-D(frcpos+1,frnpos+1)+D(frppos+1,cpos+1)+D(cpos+1,frnpos+1)+penalty3;
                                if csc3 < maxsc
                                    best.operation = 3;  % interchange
                                    best.interchangeroute = [i,remainindex(k)];  % 进行交换的两条路径
                                    best.pos = [cpos, frcpos];      % 进行交换的具体位置，第一个是被交换
                                    best.demand = [ordemandL - cdemand+frcdemand,ordemandB, ...
                                                   frdemandL - frcdemand + cdemand, frdemandB];
                                    maxsc = csc3; 
                                end     
                            elseif frcpos > linehaulnum && frppos<=linehaulnum  % 接口边后端
                                if j>2  % 不允许把路径中最后一个linehaul节点给转移走
                                    penalty3 = (max(ordemandB+frcdemand-capacity, 0) + ...
                                                max(frdemandL+cdemand-capacity, 0))*alpha;
                                    csc3 = -D(ppos+1, cpos+1)-D(cpos+1,npos+1)+D(ppos+1,frcpos+1)+D(frcpos+1,npos+1) ...
                                           -D(frppos+1,frcpos+1)-D(frcpos+1,frnpos+1)+D(frppos+1,cpos+1)+D(cpos+1,frnpos+1)+penalty3;
                                    if csc3 < maxsc
                                        best.operation = 3;  % interchange
                                        best.interchangeroute = [i,remainindex(k)];  % 进行交换的两条路径
                                        best.pos = [cpos, frcpos];      % 进行交换的具体位置，第一个是被交换
                                        best.demand = [ordemandL - cdemand, ordemandB + frcdemand, ... 
                                                       frdemandL + cdemand, frdemandB - frcdemand];
                                        maxsc = csc3; 
                                    end 
                                end                                                                              
                            end
                            if frcpos <= linehaulnum && j>2 
                                % 要插入的原连接边只能是linehaul边或者接口边
                                % 不允许把路径中最后一个linehaul节点给挖走
                                penalty1 = max(frdemandL + cdemand - capacity, 0) * alpha;  % 超载惩罚
                                csc1 = -D(ppos+1,cpos+1) - D(cpos+1,npos+1) + D(ppos+1,npos+1) + ...
                                        D(frcpos+1, cpos+1) + D(cpos+1,frnpos+1) - D(frcpos+1,frnpos+1) + penalty1;
                                if csc1 < maxsc
                                    best.operation = 1;  % insert;
                                    best.interchangeroute = [i,remainindex(k)];  % 进行交换的两条路径
                                    best.pos = [cpos, frcpos];  % 进行交换的具体位置，第一个是被交换
                                    best.demand = [ordemandL-cdemand, ordemandB, frdemandL+cdemand, frdemandB];  % 交换后的路径代价
                                    maxsc = csc1;
                                end
                            end
                            penalty2 = (max(ordemandL - restdemandL + frrestdemandL - capacity, 0) + ...
                            max(ordemandB - restdemandB + frrestdemandB - capacity, 0) + ...
                            max(frdemandL - frrestdemandL + restdemandL - capacity, 0) + ...
                            max(frdemandB - frrestdemandB + restdemandB - capacity, 0)) * alpha;
                            csc2 = -D(cpos+1, npos+1) - D(frcpos+1, frnpos+1) + ...
                                   +D(cpos+1, frnpos+1) + D(frcpos+1, npos+1)+penalty2;
                            if csc2 < maxsc
                                best.operation = 2;  % interchange
                                best.interchangeroute = [i,remainindex(k)];  % 进行交换的两条路径
                                best.pos = [cpos, frcpos];      % 进行交换的具体位置，第一个是被交换
                                best.demand = [ordemandL - restdemandL + frrestdemandL,ordemandB - restdemandB + frrestdemandB ...
                                               frdemandL - frrestdemandL + restdemandL, frdemandB - frrestdemandB + restdemandB];
                                maxsc = csc2; 
                            end
                        end
                    end
                end
            end
        end

        if maxsc < 0  % 当前最优交换带来路径代价减少时才执行
            reducecost = reducecost + maxsc;
            r1 = route{best.interchangeroute(1)};
            r2 = route{best.interchangeroute(2)};
            pos1 = best.pos(1);
            pos2 = best.pos(2);
            index1 = find(r1 == pos1);
            index2 = find(r2 == pos2);  % 锁定交换的位置
            if best.operation == 1  % insertion 
                newroute1 = r1;
                newroute1(index1) = [];
                newroute2 = zeros(1,length(r2)+1);
                newroute2(1:index2) = r2(1:index2);
                newroute2(index2+1) = pos1;
                newroute2(index2+2:end) = r2(index2+1:end);
            elseif best.operation == 2 % interchange
                newroute1 = [];
                newroute2 = [];
                newroute1 = [newroute1 r1(1:index1)];
                newroute1 = [newroute1 r2(index2+1:end)];
                newroute2 = [newroute2 r2(1:index2)];
                newroute2 = [newroute2 r1(index1+1:end)];
            elseif best.operation == 3 % exchange
                newroute1 = r1;
                newroute2 = r2;
                newroute1(index1) = pos2;
                newroute2(index2) = pos1;
            end
            route{best.interchangeroute(1)} = newroute1;
            route{best.interchangeroute(2)} = newroute2;
            routedemandL(best.interchangeroute(1)) = best.demand(1);
            routedemandB(best.interchangeroute(1)) = best.demand(2);
            routedemandL(best.interchangeroute(2)) = best.demand(3);
            routedemandB(best.interchangeroute(2)) = best.demand(4);
        end        
    end
end
                        
                        
                        
                               
                            
                        
            