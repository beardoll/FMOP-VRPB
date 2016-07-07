function [] = drawcluster(cluster, Lx, Ly, Bx, By, linehaulnum, picturerange)
coloroption = char('ro','bo','go','mo','ko');
clusternum = length(cluster);
for i = 1:clusternum
    cc_cluster = cluster{i};
    choose = mod(i,length(coloroption));
    if choose == 0
        choose = length(coloroption);
    end
    for j = 1:length(cc_cluster);
        ccp = cc_cluster(j);
        if ccp <= linehaulnum
            plot(Lx(ccp), Ly(ccp), coloroption(choose,:));
        else
            plot(Bx(ccp-linehaulnum), By(ccp-linehaulnum), coloroption(choose,:));
        end
        hold on;
        axis(picturerange);
    end
    hold on;
end
hold off;
