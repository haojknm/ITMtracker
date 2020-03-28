%% drow_result
clear
sequence{1} = 'rng14_15';
sequence{2} = 'rng17_20';
sequence{3} = 'rng18_03';
sequence{4} = 'rng22_08';
sequence{5} = 'person1';
sequence{6} = 'person2';

%     struct('name','CT','namePaper','CT'),...
% trackers= {...
%     struct('name','MIL','namePaper','MIL'),...
%     struct('name','IVT','namePaper','IVT'),...    
%     struct('name','SCM','namePaper','SCM'),...
%     struct('name','L1APG','namePaper','L1APG'),...
%     struct('name','CSK','namePaper','CSK'),...
%     struct('name','KCF','namePaper','KCF'),...
%     struct('name','staple','namePaper','staple'),...    
%     struct('name','comb2','namePaper','ITM')};

trackers= {...
    struct('name','intensity','namePaper','ITM'),...
    struct('name','texture','namePaper','ITM'),...    
    struct('name','motion','namePaper','ITM'),...
    struct('name','comb_1_3','namePaper','ITM'),...
    struct('name','comb2','namePaper','ITM')};

%'MIL','CT','CSK','SCM','L1APG','IVT','KCF','staple','ITM'

rltpath = '.\rlt\';
drawSave = '.\rltimg\'

LineWidth = 2;
plotSetting;

for k = 1:6
    
    seq = seqinfor(sequence{k}) ;   
    
    rect_anno = seq.rect_anno;
    
    resultsAll = [];
    for j=1:length(trackers)
        respath = [rltpath seq.name '_rlt_' trackers{j}.name '.mat'];
        load(respath);
        resultsAll{j} = results;
    end       

    pathSave = [drawSave seq.name '\'];
    if ~exist(pathSave,'dir')
        mkdir(pathSave);
    end
    
    figure(1),
    clf,
    CLE = [];
    ALLerrCoverage = [];
    for j = 1:length(trackers)  
        [aveErrCoverage, aveErrCenter,errCoverage, errCenter] = calcSeqErrRobust(resultsAll{j}, rect_anno);
        CLE = errCenter';%sqrt(sum(((rect_anno(1:temprlt.len,1:2) - resultsAll{j}.res(1:temprlt.len,1:2)).^2),2)); 
        ACLE(k,j) = mean(CLE);
%         VOC = calcRectInt(rect_anno,resultsAll{j}.res);
        SR(k,j) = sum(errCoverage>0.5)/seq.len;
        ALLerrCoverage = [ALLerrCoverage;errCoverage];
        plot(seq.startFrame:seq.startFrame -1 + seq.len,CLE,plotDrawStyle{j}.lineStyle,'Color', plotDrawStyle{j}.color, 'LineWidth', 3);
        hold on,
    end
    %set (gcf,'Position',[300,300,320,240]);
    set (gcf,'Color',[1,1,1]);
    title(seq.name,'fontsize',12),
    xlabel('Frame Number','fontsize',12),
    ylabel('Center Location Error','fontsize',12),
    set(gca,'FontSize',12);
    %axis normal;
%     hleg1 = legend('MIL','CT','CSK','SCM','L1APG','IVT','KCF','staple','ITM','Orientation','horizontal');
    hleg1 = legend('MIL','IVT','SCM','L1APG','CSK','KCF','staple','ITM','Orientation','vertical');
%     imwrite(frame2im(getframe(gcf)), ['.\rltimg\' seq.name '.png']);
     
    dirname = seq.path;
    for i = 2:seq.len % loop for each frame, traning on frame indframe and testing on frame indframe+1
        %% read image
        if k == 5 | k == 6
            indframe = seq.startFrame+i-1;
        else
            indframe = seq.startFrame+i-2;
        end
        tempstr = int2str(indframe + 10000) ;
        im = imread([dirname tempstr(2:5) '.bmp']);
        id = tempstr(2:5);
        [hh ww dd] = size(im);
        if dd == 1
            im = cat(3,im, im, im);
        end
        imsz = [hh ww dd];
        figure(2),imshow(im,'border','tight','initialmagnification','fit');
        set (gcf,'Position',[100,100,ww,hh]);
        axis normal;
        text(10, 15, ['#' id], 'Color','y', 'FontWeight','bold', 'FontSize',16);
%         i = indframe;
        
        for j = 1:length(trackers)            
            LineStyle = plotDrawStyle{j}.lineStyle;            
            switch resultsAll{j}.type
                case 'rect'
                    if ~isnan(resultsAll{j}.res(i,3)) && ~isnan(resultsAll{j}.res(i,4)) && resultsAll{j}.res(i,3)~=0 && resultsAll{j}.res(i,4)~=0
                    rectangle('Position', resultsAll{j}.res(i,:), 'EdgeColor', plotDrawStyle{j}.color, 'LineWidth', LineWidth,'LineStyle',LineStyle);
                    end
                case 'ivtAff'
                    drawbox(resultsAll{j}.tmplsize, resultsAll{j}.res(i,:), 'Color', plotDrawStyle{j}.color, 'LineWidth', LineWidth,'LineStyle',LineStyle);
                case 'L1Aff'
                    drawAffine(resultsAll{j}.res(i,:), resultsAll{j}.tmplsize, plotDrawStyle{j}.color, LineWidth, LineStyle);                    
                case 'LK_Aff'
                    [corner c] = getLKcorner(resultsAll{j}.res(2*i-1:2*i,:), resultsAll{j}.tmplsize);
                    hold on,
                    plot([corner(1,:) corner(1,1)], [corner(2,:) corner(2,1)], 'Color', plotDrawStyle{j}.color,'LineWidth',LineWidth,'LineStyle',LineStyle);
                case '4corner'
                    corner = resultsAll{j}.res(2*i-1:2*i,:);
                    hold on,
                    plot([corner(1,:) corner(1,1)], [corner(2,:) corner(2,1)], 'Color', plotDrawStyle{j}.color,'LineWidth',LineWidth,'LineStyle',LineStyle);
                case 'SIMILARITY'
                    warp_p = parameters_to_projective_matrix(resultsAll{j}.type,resultsAll{j}.res(i,:));
                    [corner c] = getLKcorner(warp_p, resultsAll{j}.tmplsize);
                    hold on,
                    plot([corner(1,:) corner(1,1)], [corner(2,:) corner(2,1)], 'Color', plotDrawStyle{j}.color,'LineWidth',LineWidth,'LineStyle',LineStyle);
                otherwise
                    disp('The type of output is not supported!')
                    continue;
            end
            
%             rectangle('Position', resultsAll{j}.res(indframe,:), 'EdgeColor', plotDrawStyle{j}.color, 'LineWidth', LineWidth,'LineStyle',LineStyle);
        end
        imwrite(frame2im(getframe(gcf)), [pathSave id '.png']);
    end
end

save myrlt ACLE SR
