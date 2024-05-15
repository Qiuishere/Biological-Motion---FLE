close all;
clear;
homedir = pwd; %homedir must be different from homeDir otherwise it will be covered by loaded data
addpath(genpath(homedir))
whichExp = 1;

dirs = {'Data_1', 'Data_2', 'Data_car', 'Data_static', 'Data_cat_noh',...
    'Data_2cars','Data_eyegaze','Data_IM_2','Data_eyegaze_attention','Data_feet',...
    'Data_feet','Data_feet_reversed','Data_feet_norm_inverse','Data_static_2','Data_BM_with_hip'};
% 'Data_feet_norm_inverse' is actually normal and reversed feet, not
% inverse
codes = {'flash_lag_BM.mat', 'flash_lag_BM_onfeet.mat', 'flash_lag_Car.mat','flash_lag_BM_static.mat','flash_lag_BM_cat.mat',...
    'flash_lag_Car.mat','flash_lag_eyegaze.mat', 'flash_lag_implied_motion.mat', 'flash_lag_eyegaze_attention.mat','flash_lag_feet.mat',...
    'flash_lag_feet_CONSTANT.mat','flash_lag_feet_reverse.mat','flash_lag_feet_norm_inverse.mat','flash_lag_static_2.mat', 'flash_lag_BM_with_hip.mat'};
XTickLabel ={{'Upright' 'Inverted'},{'Upright' 'Inverted'},{'Car' 'Bird'},{'Upright' 'Inverted' }, {'Upright' 'Inverted'},...
    {'static-asymmetrical','symmetrical-motion'},{'Eyegaze' 'Arrow'},{'IM' 'NoIM'}, {'Upright' 'Inverted'}, {'Upright' 'Inverted'}, ...
    {'Upright' 'Inverted'},{'Upright' 'Inverted'},{'Normal' 'Reversed'},{'Upright' 'Inverted'},{'Upright' 'Inverted'}};
cd(dirs{whichExp})
DataDir = dir;
DataDir([1,2]) = [];

% exclude sub who didn't follow instruction or the authors
% subtoExc1 = {'taojiayuan','liujing','chenhuimin','majunyu','yuxiaohan','wuhanbing','gzp','yss','hq','qq','qq_middle'};
subtoExc1 = {'wuhanbing','gzp','yss','hq','qq','qq_middle'};
% if ismember(whichExp,[10 ])
%  subtoExc1 ={'liwenxia','mojiayi','shilixin','qiaolin','hq','qq'};
% end
exid1 = [];
for ii=1:size(DataDir,1)
    for jj = 1:length(subtoExc1)
        if strcmp(DataDir(ii).name, subtoExc1{jj});  exid1=[exid1, ii];   end
    end
end
DataDir(exid1) = [];
% DataDir = DataDir([3 6 8 12 14]);
% % DataDir = DataDir([2 5 7 11 13]);

Nsub= size(DataDir,1);


%% preprocessing
try
    for ss = 1:Nsub  %note!! the index must not have appeared in the main script or it will be overrided
        %rule: use double letter in analysis scripts
        cd (DataDir(ss).name);
        dataFile= ['*' codes{whichExp}];
        fileName=dir(dataFile);
        load(fileName.name);
        %         subTbl{6} = [subTbl{5};subTbl{6}];
        %                 subTbl{5} = subTbl{6};
        
        %             fileName=dir('*scramble_test.mat');
        %             load(fileName.name, 'acc');
        %             Acc_scrb(ss,:) = acc;
        
        blockorder = 1:nblock;
        if ismember(whichExp, [1 2 4 5 10 11 12 13 14 15])  % !! In other experiments the resulttable was already sorted as car first
            
            if ismember(whichExp, [10 11 12])
                blockorder = totestblock;
                nblock = length(blockorder);
            end
            if Invfirst
                blockorder = reshape([blockorder(2:2:end);blockorder(1:2:end)],[],1);
            end
            Inv(ss,1) = Invfirst;
            
        elseif whichExp ==6
            nblock = 1;
            if  isempty(subTbl{2})
                blockorder = 1; 
            else
                blockorder = 2;% in 8 subjects, two blocks are tested, the 2nd is symetrical car
            end
        elseif whichExp == 8
            nblock = 2;
            blockorder = 1:nblock; % in IM_2, the order of subTbl was already sorted as IM- NOIM
        end
        
        for cc= 1:nblock
            kk = blockorder(cc); % with this, all data are in up-inv-up-inv order
            invalidRTid = isnan(subTbl{kk}(:,RTid));
            subTbl{kk}(invalidRTid,:) = [];
            excludedtrial(ss,cc) = 1-size(subTbl{kk},1)/ntrial;
            
            if ismember( whichExp,[ 8])
                pic2ana = [1:3 9:13]; % two human pictures
                toanaid = find(ismember(subTbl{kk}(:,Picid),pic2ana));
                subTbl_sub{kk} = subTbl{kk}(toanaid,:);
            elseif whichExp == 9
                fr2ana = flashrange; %determine a time window where the flash is presented
                toanaid = find(ismember(subTbl{kk}(:,flashFrid),fr2ana));
                subTbl_sub{kk} = subTbl{kk}(toanaid,:);
            end
            for thelevel = 1:nlevel
                trials = find(subTbl{kk}(:,flashOffsetid)==Offsets.Pix(thelevel)); %if whichExp==8 or 9, subTbl should be subTbl_sub
                lagtrials = find(subTbl{kk}(trials,lagid) == 1);%if whichExp==8 or 9, subTbl should be subTbl_sub
                perctLag(cc,thelevel) = length(lagtrials)/ length(trials);
                meanRT(cc,thelevel) = mean(subTbl{kk}(trials,RTid));
            end
            
            x = Offsets.Ang;
            y = perctLag(cc,:);
            if ~isnan(y)
                [fitresult, gof, threshold] = fitLogisticCDF(x, y, 0, 0);
                FitResult{ss,cc} = fitresult;
                GoF{ss,cc} = gof;
                PSE(ss,cc) = fitresult.c; %the larger c is , the more the curve is shifted to the right, negative means left
                %             Threshold(pp,cc) = threshold;  % this is the same as PSE
                Slope(ss,cc) = fitresult.a; %the larger a is , the steeper
                adjrsquare(ss,cc) = gof.adjrsquare;
            end
            perctLag_all(cc,:,ss) = perctLag(kk,:); %dimension: 1:block, 2:level*7, 3:nsub
            meanRT_all(cc,:,ss) = meanRT(kk,:);
        end
        
        if whichExp == 1
            Gender(ss,1) = str2num(SbjInfor{1});
            Percv_U_full(ss,1) = strcmp(SbjInfor{2},'y');
            Percv_U_feet(ss,1) = strcmp(SbjInfor{3},'y');
            Percv_I_full(ss,1) = strcmp(SbjInfor{4},'y');
            Percv_I_feet(ss,1) = strcmp(SbjInfor{5},'y');
        elseif whichExp == 4
            Gender(ss,1) = str2num(SbjInfor{1});
            Percv_U_static(ss,1) = strcmp(SbjInfor{2},'y');
            Percv_I_static(ss,1) = strcmp(SbjInfor{3},'y');
        elseif ismember(whichExp,[3 4 6:9 13])
            Age(ss,1) = str2num(SbjInfor{2});
            Gender(ss,1) = str2num(SbjInfor{1}); %1: female, 2:male
            if whichExp == 13
                Conscious(ss,:) = [strcmp(SbjInfor{3},'y'),strcmp(SbjInfor{4},'y')];
                if Invfirst
                    Conscious(ss,:) = fliplr(Conscious(ss,:));
                end
            end
        elseif ismember(whichExp,[10,11])
            fileName=dir('*-AQ.mat');
            load(fileName.name);
            AQs(ss,:) = cell2mat(struct2cell(ScoreAQ))';
                        
        end
        cd ..
    end
    cd(homedir);
    
    %%
    dataname = ['Group_' dirs{whichExp}(6:end) '.mat'];
    %     save(dataname,  'datadir', 'PSE', 'Slope', 'adjrsquare', 'perctLag_all', 'meanRT_all', 'Gender', 'Percv_U_full', 'Percv_U_feet', 'Percv_I_full', 'Percv_I_feet')
    
    cd Groupdata;
    save(dataname)
    cd ..
    
    %%  exclude
    [row, col] = find(adjrsquare<0.81);% & adjrsquare~=0);
    exid2 = unique(row);
    
    [pse.MU,pse.Sigma,pse.Muci,pse.Sigmaci] = normfit(PSE, 0.05);
    exid3 = [];
    for ii=1:nblock
        ex{ii} = find(abs(PSE(:,ii) - pse.MU(ii)) > 3*pse.Sigma(ii));
        exid3=[exid3; ex{ii}];
    end
    
    DataDir(unique([exid2; exid3])) = [];
    FitResult(unique([exid2; exid3]),:) = [];
    GoF(unique([exid2; exid3]),:) = [];
    PSE(unique([exid2; exid3]),:) = []; %the larger c is , the more the curve is shifted to the right, negative means left
    Slope(unique([exid2; exid3]),:) =[]; %the larger a is , the steeper
    adjrsquare(unique([exid2; exid3]),:) = [];
    perctLag_all(:,:,unique([exid2; exid3])) = []; %dimension: 1:block, 2:level*7, 3:nsub
    meanRT_all(:,:,unique([exid2; exid3])) = [];
    
    if whichExp == 1
        Gender(unique([exid2 exid3]),:) = [];
        Percv_U_full(unique([exid2 exid3]),:) = [];
        Percv_U_feet(unique([exid2 exid3]),:) = [];
        Percv_I_full(unique([exid2 exid3]),:) = [];
        Percv_I_feet(unique([exid2 exid3]),:) = [];
        
        % exclude sub whose RT was not rightly recorded
        subtoExcRT = {'mpl','lwx','yhj','lyj','dw','zm','wzp'};
        exidRT = [];
        for ii=1:size(DataDir,1)
            for jj = 1:length(subtoExcRT)
                if strcmp(DataDir(ii).name, subtoExcRT{jj});  exidRT=[exidRT, ii];   end
            end
        end
        meanRT_all(:,:,exidRT) = [];
        Gender(9)=1;
        
        % AQ
        T = readtable('.\Groupdata\95616608_2_实验后续调查_12_11.xlsx');
        AQtable = T{:,7:56};
        ScoreAQ = calculateAQ(AQtable);
        nametalbe = T{:,57};
        AQid = [7 1 20 11 3 4 2 14 18 19 9];
        dims = {'total','S','A','D','C','I'};
        for dim = 1:6
            for blk = 1:6
                [r,p] = corrcoef(PSE(AQid,blk),ScoreAQ.(dims{dim}));
                R(dim,blk) = r(1,2);
                p_corr(dim,blk) = p(1,2);
                subplot(length(dims),6,(dim-1)*6+blk);
                scatter(ScoreAQ.(dims{dim}),PSE(AQid,blk))
            end
        end
        
    elseif whichExp == 4
        Gender(unique([exid2 exid3]),:) = [];
        Percv_U_static(unique([exid2 exid3]),:) = [];
        Percv_I_static(unique([exid2 exid3]),:) = [];
    elseif ismember(whichExp,6:9)
        Gender(unique([exid2 exid3]),:) = [];
        Age(unique([exid2 exid3]),:) = [];
    end
       
    
    %% ==========descriptive===================
    [pse.MU,pse.Sigma,pse.Muci,pse.Sigmaci] = normfit(PSE);
    pse.CIlength = pse.Muci(2,:) - pse.MU;
    [slp.MU,slp.Sigma,slp.Muci,slp.sigmaci] = normfit(Slope);
    [rt.MU,rt.Sigma,rt.Muci,rt.sigmaci] = normfit(meanRT_all);
    [pctlag.MU,pctlag.Sigma,pctlag.Muci,pctlag.sigmaci] = normfit(perctLag_all);
    
    %% ==========TESTS=============
    
    for aa = 1:nblock
        % before t test: normal distribution test
        h_nrmdistri(aa) = kstest( zscore( PSE(:,aa)));
        [h,pse.p_to0(aa)] = ttest(PSE(:,aa), 0);  % h = 0 indicates that ttest does not reject the null hypothesis
    end
    %     firstblock = [ PSE(upid,1); PSE(invid,2)];%those who are really firstly presented
    %
    %     secondblock = [ PSE(upid,2); PSE(invid,1)];%those who are really firstly presented
    %     [~,p] = ttest(firstblock, secondblock);
    %
    % if inverted differ from upright
    for bb = 1:nblock/2
        % before t test:equal variance test
        h_equvar(bb) = vartest2(PSE(:,bb*2-1), PSE(:,bb*2)); % x and y comes from normal distributions with the same variance
        [h,pse.p_toCtrl(bb)] = ttest(PSE(:,bb*2-1), PSE(:,bb*2));  % h = 0 indicates that ttest does not reject the null hypothesis
        [h,slp.p_toCtrl(bb)] = ttest(Slope(:,bb*2-1), Slope(:,bb*2));  % h = 0 indicates that ttest does not reject the null hypothesis
        %         [~,p.upfirst] = ttest(PSE(upid,bb*2-1), PSE(upid,bb*2));
        %         [~,p.invfirst] = ttest(PSE(invid,bb*2-1), PSE(invid,bb*2));
        [h,p(bb)] = vartest2(PSE(:,bb*2-1),PSE(:,bb*2));
        
    end
    
    [R,pse.corr] = corrcoef(PSE);

    % for those with a consciouness question, test whether the knowledge of
    % direction has something todo with the percetion.
%     [h, p_norm] = ttest2(PSE(Conscious(:,1)),PSE(logical(1-Conscious(:,1))));
%     [h, p_norm] = ttest2(PSE(Conscious(:,2)),PSE(logical(1-Conscious(:,2))));

    %% Correlation with AQ
    dims = {'total','S','A','D','C','I'};
    
    figure;
    for dim = 1:6
        for blk = 1:2
            theblk = blk+4;
            [r,p] = corrcoef(PSE(:,theblk),AQs(:,dim));
            R(dim,blk) = r(1,2);
            p_corr(dim,blk) = p(1,2);
            subplot(6,2,(dim-1)*2+blk); hold on;
            scatter(AQs(:,dim),PSE(:,theblk))
            title(dims{dim})
        end
    end
    
    %% ============PLOT=============
    MarkerSize = 6;
    Col.pink = [255 153 153] /255;
    Col.green = [91 153 153] /255;
    Col.black = [0 0 0];
    Col.grey = [.4 .4 .4];
    Col.white = [1 1 1];
    
    figure('OuterPosition',[0 0 350 500]);
    
    xpos = [1 2];
    %     xpos  = xpos(1:nblock);
    for ii=1:nblock
        barhd(ii) = bar( xpos(ii),pse.MU(ii));
        hold on
        scathd = plot(xpos(ii),PSE(:,ii),'o','MarkerFaceColor',Col.pink,'MarkerEdgeColor',Col.black,'MarkerSize',MarkerSize);
        errorbar(xpos(ii), pse.MU(ii), pse.CIlength(ii), 'k', 'linestyle', 'none');
        if ~mod(ii,2)
            barhd(ii).FaceColor= Col.white;
            barhd(ii).EdgeColor= Col.black;
        else
            barhd(ii).FaceColor= Col.grey;
            barhd(ii).EdgeColor= Col.grey;
        end
        barhd(ii).LineWidth = 2;
        barhd(ii).BarWidth= 0.4;
        plot(xpos, PSE)
    end
    
    
    Title =  dirs{whichExp}(8:end);
    Title(strfind(Title,'_')) = ' ';
    title('feet-reversed' ,'fontsize',16); %% specify the figure name
    set(gca,'XTick',[1 2], 'XTickLabel',XTickLabel{whichExp},'fontsize',14);
    
    title('static')
    ylabel('PSE(degree)','fontsize',12);
    set(gca,'YDir','reverse','ylim',[-0.2 0.2],'fontsize',14);
    box off
    axis ij
    
    %%
    group_plot(pse,PSE)
    
    set(gca, 'XTickLabel',{'with head' 'with hip' 'feet only'},'fontsize',11);
    title('PSE' ,'fontsize',14); %% specify the figure name
    ylabel('PSE(degree)','fontsize',12);
    set(gca,'ylim',[-0.15 0.2]);
    box off;
    
    group_plot(slp,Slope)
    set(gca, 'XTickLabel',{'with head' 'with hip' 'feet only'},'fontsize',11);
    title('Slope' ,'fontsize',14); %% specify the figure name
    ylabel('slope(a)','fontsize',12);
    
    % ---------RT plot
    figure('OuterPosition',[0 0 800 500]);
    for zz = 1:nblock
        subplot(3, 2,zz)
        bar(Offsets.Ang,rt.MU(zz,:),'FaceColor', Col.grey)
        hold on
        errorbar(Offsets.Ang, rt.MU(zz,:), rt.SE(zz,:), 'k', 'linestyle', 'none');
        box off;
    end
    
    % ---------averaged percentage of lag
    figure('OuterPosition',[0 0 1000 400]);
    for zz = 1:nblock/2
        subplot(1,3,zz);
        x = Offsets.Ang;
        
        y = pctlag.MU(zz*2-1,:);
        plot(x,y,'o','MarkerFaceColor', [0.9,0.3,0.2],'MarkerSize',6);        hold on
        errorbar(x,y, pctlag.SE(zz*2-1,:), 'k', 'linestyle', 'none');
        [fitresult, gof, threshold] = fitLogisticCDF(x,y, 0,0);
        plot( fitresult,'-k');
        
        y = pctlag.MU(zz*2,:);
        plot(x,y,'o','MarkerSize',6)
        errorbar(x,y, pctlag.SE(zz*2,:), 'k', 'linestyle', 'none');
        [fitresult, gof, threshold] = fitLogisticCDF(x,y, 0,0);
        plot( fitresult,':k' );
        
        grid on
        box off;
        legend('upright','fitted','inverted','fitted')
    end
    
    %%
    % UPRIGHT: CAN PERCEPTION AFFECT LAG EFFECT OF FEET?
    can.U_feet = PSE(Percv_U_feet,5);
    cant.U_feet = PSE(logical(1-Percv_U_feet),5);
    [~,p_difpercv.U_feet] = ttest2(can.U_feet,cant.U_feet);
    
    
    % INVERTED: CAN PERCEPTION AFFECT LAG EFFECT?
    can.I_feet = PSE(Percv_I_feet,6);
    cant.I_feet = PSE(logical(1-Percv_I_feet),6);
    [~,p_difpercv.I_feet] = ttest2(can.I_feet,cant.I_feet);
    
    % INVERTED: CAN PERCEPTION AFFECT LAG EFFECT OF BODY?
    can.I_full = PSE(Percv_I_full,2);
    cant.I_full = PSE(logical(1-Percv_I_full),2);
    [~,p_difpercv.U_feet] = ttest2(can.I_full,cant.I_full);
    
    % HOW GENDER AFFECT THE RESULT
    can.I_feet = PSE(g,6);
    cant.I_feet = PSE(logical(1-Percv_I_feet),6);
    [~,p_difpercv.I_feet] = ttest2(can.I_feet,cant.I_feet);
    rmpath(genpath(homedir))
    
    
    % for scramble test
    accidx = abs(Acc_scrb-0.5);
    [r,p]=corrcoef(accidx(:,1),PSE(:,1))
    [r,p]=corrcoef(accidx(:,2),PSE(:,2))
    
    id = accidx(:,2)~=0
    [r,p]=corrcoef(accidx(id,2),PSE(id,2))
    
    scatter(accidx(id,2),PSE(id,2))
    
catch ME
    cd(homedir)
    rmpath(genpath(homedir))
    rethrow(ME);
    
end