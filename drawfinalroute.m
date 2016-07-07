function [] = drawfinalroute(path, Lx, Ly, Bx, By, repox, repoy, picturerange)
    % 画出所有的路径
    % 以圆圈表示linehaul，菱形表示backhaul
    coloroption = char('r-','b-','g-','m-','k-');
    pathnum = length(path);   % 路径数量
    linehaulnum = length(Lx);
    if pathnum == 0
        return;
    else
        for i = 1:pathnum
            temp = mod(i,5);
            if temp == 0
                temp = 5;
            end
            linecolor = coloroption(temp);
%             figure(i+20);
            part_path = path{i};
            if length(part_path) == 0
                continue;
            else
                plot([repox Lx(part_path(1))], [repoy Ly(part_path(1))], linecolor, 'LineWidth', 2);
                axis(picturerange);
                hold on;
                plot(repox, repoy, 'b*','MarkerSize',8);
                plot(Lx(part_path(1)), Ly(part_path(1)), 'go','MarkerSize',8);
                pathlen = length(part_path);
                for j = 2:pathlen+1
                    frontnum = part_path(j-1);
                    if frontnum <= linehaulnum
                        x1 = Lx(frontnum);
                        y1 = Ly(frontnum);
                    else
                        x1 = Bx(frontnum - linehaulnum);
                        y1 = By(frontnum - linehaulnum);
                    end
                    if j <= pathlen
                        backnum = part_path(j);
                        if backnum <= linehaulnum
                            x2 = Lx(backnum);
                            y2 = Ly(backnum);
                            color = 'go';
                        else
                            x2 = Bx(backnum - linehaulnum);
                            y2 = By(backnum - linehaulnum);
                            color = 'bd';
                        end
                        plot(x2, y2, color, 'MarkerSize',8);
                        plot([x1 x2], [y1 y2],linecolor, 'LineWidth', 2);
                    else
                        plot([x1 repox], [y1 repoy], linecolor, 'LineWidth', 2);
                    end
                end
                hold on;
            end
        end
    end        
    hold off;
end