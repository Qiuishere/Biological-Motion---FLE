%%  -----------test if implied motion can result in flash lag-------------
% Qiu Han 9/19/2020
%{
revised version of implied motion. This time 20 different pictures are
included as an attempt to eliminate effects caused by a certain picture.
Besides, pictures could be categorized into serveral categories, which is
eligible for scrutinization of effects of different stimuli
ResultTable is in presentation order, but subTbl was sorted in IM-noIM order
%}
clear all; close all;
Screen('Preference', 'SkipSyncTests',0);
KbName('UnifyKeyNames');
homeDir = pwd;
tic;
HideCursor;
recordTime = datestr(now);
recordvideo = 0;

debugFlag = 1;

if  ~debugFlag
    subName = input('Please input the subject''s name:\n','s');
    if any(isspace(subName));   subName=strtrim(subName);  end
else
    subName='pppr';
end
praflag = 0;
if strcmp(subName(end-1:end),'pr');  praflag = 1;  end

datadir = 'Data_IM_2';
if ~(exist(datadir,'dir')&&exist('Pradata','dir')&&exist('Sbj','dir')&&exist('Prasbj','dir'))
    mkdir(datadir);mkdir('Pradata');mkdir('Sbj');mkdir('Prasbj');  %Make new folder
end


%% =======Sound settings==========

InitializePsychSound(1);
if ~IsLinux
    PsychPortAudio('Verbosity', 10);
end
deviceid = -1;
reqlatencyclass = 2;   %Level 1 (the default) means: Try to get the lowest latency that is possible under the constraint of reliable playback, freedom of choice for all parameters and interoperability with other applications.
%  Level 2 means: Take full control over the audio device, even if this causes other sound applications to fail or shutdown.
freq = 44100;
buffersize = 0;  %'buffersize' requested size and number of internal audio buffers, smaller numbers mean lower latency
suggestedLatencySecs = []; % 'suggestedLatency' optional requested latency in seconds.
if IsWin
    suggestedLatencySecs = 0.015;%%what's taht for?
end
pahandle = PsychPortAudio('Open', deviceid, [], reqlatencyclass, freq, 2, buffersize, suggestedLatencySecs);
%'channels' Number of audio channels to use, defaults to 2 for stereo.
noiseL(1,:) = 0.5 * MakeBeep(600, 0.02, freq);  %MakeBeep(freq,duration,[samplingRate])
noiseL(2,:) = noiseL(1,:);
noise_end(1,:) = 0.5 * MakeBeep(1000, 0.02, freq);  %MakeBeep(freq,duration,[samplingRate])
noise_end(2,:) = noise_end(1,:);


try
    AssertOpenGL;
    useBitspp = 0;
    screenNumber=max(Screen('Screens'));
    BGColor = GrayIndex(screenNumber);
    if ~useBitspp
        PsychImaging('PrepareConfiguration');  % Prepare setup of imaging pipeline for onscreen window.This is the first step in the sequence of configuration steps.
        PsychImaging('AddTask', 'AllViews', 'EnableCLUTMapping');  % Enable support for old-fashioned clut animation  clut mapping. The drawn framebuffer image is transformed by applying a color lookup table (clut)
    else                                                           % it doesn't operate on the hardware gamma tables at all
        %--- Bits++ configuration ---
        PsychImaging('PrepareConfiguration');
        PsychImaging('AddTask', 'General', 'EnableBits++Bits++Output');
    end
    
    w = SetScreen('OpenGL',1, 'debug',0, 'BGColor', BGColor);
    Priority(MaxPriority(w.Number)); % improve the priority of PTB in CPU
    w.ifi = Screen('GetFlipInterval', w.Number);
    Screen('BlendFunction', w.Number, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    
    
    %% =============gamma correction===========
    if ~debugFlag
        monitor.oldclut = Screen('ReadNormalizedGammaTable',screenNumber);
        useBitspp=1;
        if IsWin
            load ../../CalFiles/calib-PC-LeftLens-14-Aug-2018-18-26-14.mat;
            dacsize = 8;
        else
            if useBitspp
                load ../../CalFiles/calib-0-bitspp-byPTB3-30-Nov-2017.mat;
                dacsize = 14;
            else
                load calib-0-25-Dec-2012;
                dacsize = 10;
            end
        end
        monitor.dacsize = dacsize;
        monitor.gamInv = gamInv; % how does it work?
        monitor.maxcol = 2.^dacsize-1;
        ncolors = 256;
        newcmap = rgb2cmapramp([.5 .5 .5],[.5 .5 .5],.999,ncolors,monitor.gamInv);
        newclut = zeros(ncolors,3);
        newclut(1:ncolors,:) = newcmap./monitor.maxcol;  %Values have to be in range between 0.0 (for dark pixel) and 1.0 (for maximum intensity)
        Screen('LoadNormalizedGammaTable', w.Number, newclut, 1); %'loadOnNextFlip' to 1 allows to synchronize change of both the visual stimulus and change of the gamma table with each other and to the vertical retrace.
                                                                           %2 will load the provided table not into the hardware tables of your graphics card, but into the hardware tables of special display devices  
                                                                           %default value of 0 then update of the gamma table will happen at the next vertical retrace 
    end
    
    % ----------text parameter
    text.Col = BlackIndex(screenNumber);
    text.Size = 18;
    Screen('TextFont',w.Number,'Microsoft YaHei');
    Screen('TextSize',w.Number,text.Size);
    Screen('TextStyle',w.Number,0);  %1==bold
    Screen('Preference', 'TextAntiAliasing', 2); %1 = Enable, 2 = EnableHighQuality
    
    % ----------stimuli size and color
    monitor.size = [59.6 33.6];
    if w.StereoMode == 4
        monitor.size(1) =  monitor.size(1)/2;
    end
    monitor.viewDist = 80 ;
    monitor.center = CenterRect([0 0 1 1],w.Rect);
    pixpercm = [w.Rect(3)/monitor.size(1) w.Rect(4)/monitor.size(2)];
    
    
    %% ==========create stimuli===========

    cd ./actions/IM-with-fixation
    Pics = dir('*.jpg');
    fileNames = natsortfiles({Pics.name});
    nPic = length(Pics);
    
    Img.boundary = [-110 135 -300 300]; % position of car body. from center, to above, below, left, riht
    Img.UAngle = 2.45; % KEPP CONSISTENT EITH THE PLW
    Img.Upixel = visAng2xyNew(Img.UAngle, 0, monitor);
    Img.factor = Img.Upixel/abs(Img.boundary(1));

    for h = 1:nPic
        X =  imread(fileNames{h});
        imgs(h).W = size(X,2);
        imgs(h).H = size(X,1);
        imgs(h).Pos = CenterRectOnPoint([0 0 Img.factor*imgs(h).W Img.factor*imgs(h).H], w.center(1) , w.center(2));
        imgtex(1,h,1)=Screen('MakeTexture', w.Number ,X);
        imgtex(1,h,2)=Screen('MakeTexture', w.Number ,fliplr(X));
    end

    cd ../noIM-with-fixation
    for h = 1:nPic
        X =  imread(fileNames{h});
        imgtex(2,h,1)=Screen('MakeTexture', w.Number ,X);
        imgtex(2,h,2)=Screen('MakeTexture', w.Number ,fliplr(X));
    end    
    cd(homeDir);
            
    dot.Ang = 0.2;
    dot.Pix= visAng2xyNew(dot.Ang, 0, monitor);
    dot.Col = [255 255 255];
    
    flash.Ang = 3.4;
    flash.Pos =  -visAng2xyNew(flash.Ang, 0, monitor);
    flash.Col = [255 0 0];
    
    fix.Col = [255 255 255];
    fix.Pix = dot.Pix;
    
    Offsets.Ang = dot.Ang * [ -1.5, -1, - 0.5, 0, 0.5, 1, 1.5 ];
    Offsets.Pix = visAng2xyNew(Offsets.Ang, 0, monitor);
    nlevel = length(Offsets.Pix);
    
        recordRect = CenterRectOnPoint([0 0 2.4*flash.Pos 2.4*flash.Pos],w.center(1),w.center(2));

    %% =============experimental settings==============
    
    % ----------duration
    Dur.motion = 1.2;
    Dur.resp = 5;
    
    % -----------procedures
    nsub = length(dir(['.\' datadir]))-2;  % how many subs are there
    if mod(nsub,2)
        CondiOrder = [1 2 2 1]; % 1: IM, 2: noIM
    else    CondiOrder = [2 1 1 2];
    end
   
    ntrialPerlevel = 20;
    if debugFlag || praflag
        ntrialPerlevel = 2;
        CondiOrder = CondiOrder(1:2);
    end
    ntrial = ntrialPerlevel* nlevel;
    nblock = numel(CondiOrder);
       
    ResultTable = NaN(ntrial, 10, nblock);
    T = zeros(ntrial, 3, nblock);
    trialid = 1; Picid = 2; LorRid = 3;  fixaTid = 4;  flashOffsetid = 5;  flashFrid = 6; flashTid = 7;  respid = 8;  RTid = 9;  lagid = 10;
    flashrange = 30:60;
    
    for i = 1:nblock
        ResultTable(:,trialid, i) = 1: ntrial;
        ResultTable(:,flashOffsetid, i) = randSamp(Offsets.Pix,ntrial,'n');
        for j = Offsets.Pix
            trials = ResultTable(:,flashOffsetid, i)==j;
            ResultTable(trials,Picid, i) = randSamp(1:nPic,length(find(trials)),'n');
            ResultTable(trials,LorRid, i) = randSamp([-1, 1],length(find(trials)),'n'); % 1: facing left 2:facing right            
        end
        ResultTable(:,flashFrid, i) = randSamp(flashrange,ntrial,'n');
        ResultTable(:,fixaTid, i) = rand(ntrial,1)*0.5+0.5; %ranging from 0.5 to 1
    end
    
    Instruct = {'请全程盯紧图片中央的点\n\n在某个时刻，图片中的物体上方会出现一个红点\n\n您需要比较:红点与图片中央的白色方框的水平位置\n\n如果这个红点在白框的左边，请按左键\n\n红点在白框右边，请按右键\n\n图片中的物体的方向与红点的位置之间没有关系\n\n请尽量又快又准确地做出反应\n\n\n准备好之后按空格键开始'};

    %% ============start a block==============
    for theblock = 1:nblock
        
        if ~debugFlag
            DrawFormattedText(w.Number,double(char(Instruct)) ,'center', 'center', text.Col);
            Screen('Flip',w.Number);  %display the dots on the screen
            KbWait;
            KbReleaseWait;
            
            DrawFormattedText(w.Number,double('ready to start') ,'center', 'center', [0 0 255]);
            Screen('Flip',w.Number);  %display the dots on the screen
            WaitSecs(2);
         end
        if recordvideo
            movie = Screen('CreateMovie', w.Number, 'car.mp4',RectWidth(recordRect),RectHeight(recordRect),60,':CodecSettings= Videoquality=1');
        end
        for thetrial = 1:ntrial
            thepic = ResultTable(thetrial,Picid, theblock);
            theori.face = ResultTable(thetrial,LorRid, theblock); % -1:left
            theOffset = -theori.face * ResultTable(thetrial,flashOffsetid, theblock); % originally , positive demotes right offset, now denotes lag behind            
            thefalshfr = ResultTable(thetrial,flashFrid, theblock);
            
            %% =============start presenting=======
            
            vbl = Screen('Flip',w.Number); % read the time when the last flip finished
            T(thetrial,1,theblock) = vbl;
            i = 1;
            while GetSecs - T(thetrial,1,theblock) < Dur.motion- 0.5*w.ifi
                Screen('DrawDots', w.Number,[0; 0], fix.Pix,  fix.Col, w.center, 1);
                Screen('DrawingFinished', w.Number); % insert this between Flips to prevent other drwaing procedure occupying
                [vbl,StimulusOnsetTime, FlipTimestamp] = Screen('Flip',w.Number, vbl + 0.5*w.ifi);  %display the dots on the screen
                i = i+1;
                                if recordvideo
                     Screen('AddFrameToMovie', w.Number,recordRect, 'frontBuffer');
                end
            end
                        
            %% motoin onset
            T(thetrial,2,theblock) = vbl;
            i = 1;
            respflag = 0;
            while ~respflag && GetSecs - T(thetrial,2,theblock) < Dur.motion - 0.5*w.ifi
                %  draw stimuli
                if theori.face == -1
                    Screen('DrawTexture', w.Number, imgtex(CondiOrder(theblock),thepic,1), [], imgs(thepic).Pos);
                elseif theori.face == 1;
                    Screen('DrawTexture', w.Number, imgtex(CondiOrder(theblock),thepic,2), [], imgs(thepic).Pos);
                end
%                 Screen('DrawDots', w.Number,[0; 0], fix.Pix, fix.Col, w.center, 0);

                % draw flash
                if i == thefalshfr && ismember(i,flashrange) % to avoid flash agian in the second cycle
                    Screen('DrawDots',w.Number, [theOffset, flash.Pos] ,dot.Pix, flash.Col,w.center, 0);
                end
                Screen('DrawingFinished', w.Number); % insert this between Flips to prevent other drwaing procedure occupying
                [vbl,StimulusOnsetTime, FlipTimestamp] = Screen('Flip',w.Number, vbl + 0.5*w.ifi);
                                if recordvideo
                     Screen('AddFrameToMovie', w.Number,recordRect, 'frontBuffer');
                end
                if i == thefalshfr && ismember(i,flashrange) 
                    ResultTable(thetrial, flashTid, theblock) = StimulusOnsetTime ;
                    T(thetrial,3,theblock) = StimulusOnsetTime;
                end
                
                [keyIsDown,respT,keyCode] = KbCheck;
                if keyIsDown
                    if keyCode(KbName('ESCAPE'))
                        clear screen;
                        sca;
                        ShowCursor;
                        error('quit by user!');
                    elseif keyCode(KbName( 'LeftArrow')) && i > thefalshfr
                        T(thetrial,4,theblock) = respT;
                        ResultTable(thetrial,respid,theblock) = -1;
                        ResultTable(thetrial,RTid,theblock) = respT- ResultTable(thetrial, flashTid, theblock);
                        ResultTable(thetrial,lagid,theblock) = theori.face ~= ResultTable(thetrial,respid,theblock); %if perceive the opposite of facing direction, code 1
                        respflag=1;
                    elseif  keyCode(KbName('RightArrow')) && i > thefalshfr
                        T(thetrial,4,theblock) = respT;
                        ResultTable(thetrial,respid,theblock) = 1;
                        ResultTable(thetrial,RTid,theblock) = respT- ResultTable(thetrial, flashTid, theblock);
                        ResultTable(thetrial,lagid,theblock) = theori.face ~= ResultTable(thetrial,respid,theblock); %if perceive the opposite of facing direction, code 1
                        respflag=1;
                    end
                end
                
                i = i+1;
            end
            
            
            % cheack for response
            T(thetrial,5,theblock) = vbl;
            
            while ~respflag && GetSecs - T(thetrial,5,theblock) < Dur.resp - 0.5*w.ifi
                DrawFormattedText(w.Number,double('请选择') ,'center', 'center', text.Col);
                [vbl,StimulusOnsetTime, FlipTimestamp] = Screen('Flip',w.Number, vbl + 0.5*w.ifi);
                                if recordvideo
                     Screen('AddFrameToMovie', w.Number,recordRect, 'frontBuffer');
                end
                [keyIsDown,respT,keyCode] = KbCheck;
                if keyIsDown
                    
                    if keyCode(KbName('ESCAPE'))
                        clear screen;
                        sca;
                        ShowCursor;
                        error('quit by user!');
                    elseif keyCode(KbName( 'LeftArrow'))
                        T(thetrial,4,theblock) = respT;
                        ResultTable(thetrial,respid,theblock) = -1;
                        ResultTable(thetrial,RTid,theblock) = respT- ResultTable(thetrial, flashTid, theblock);
                        ResultTable(thetrial,lagid,theblock) = theori.face ~= ResultTable(thetrial,respid,theblock); %if perceive the opposite of facing direction, code 1
                        respflag=1;
                    elseif  keyCode(KbName('RightArrow'))
                        T(thetrial,4,theblock) = respT;
                        ResultTable(thetrial,respid,theblock) = 1;
                        ResultTable(thetrial,RTid,theblock) = respT- ResultTable(thetrial, flashTid, theblock);
                        ResultTable(thetrial,lagid,theblock) = theori.face ~= ResultTable(thetrial,respid,theblock); %if perceive the opposite of facing direction, code 1
                        respflag=1;
                    end
                end
            end
        end
        % ---alarm for end of a block
        PsychPortAudio('DeleteBuffer');
        PsychPortAudio('FillBuffer', pahandle, noise_end);
        PsychPortAudio('Start', pahandle, 1, 0, 0);  WaitSecs(0.2);
        PsychPortAudio('Start', pahandle, 1, 0, 0);  WaitSecs(0.2);
        PsychPortAudio('Start', pahandle, 1, 0, 0);
                if recordvideo            
            Screen('FinalizeMovie', movie);
        end
    end
    
    if ~praflag
        sca;
        prompt = {'性别(1女，2男)','年龄'};
        SbjInfor = inputdlg(prompt,'被试信息',1);
    end

    %% ===============reprocessing and plot===============
    validid = @(k) find(1-(isnan( ResultTable(:,respid,k)) | ResultTable(:,RTid,k)<0.2 | ResultTable(:,RTid,k)>4));

    for k = 1:nblock
        ResultTable(:, flashTid, k) = ResultTable(:, flashTid, k) - T(1,1,k);
        excludedTbl{k} = ResultTable(:,:,k);
        excludedTbl{k} =excludedTbl{k} (validid(k),:);
    end
    for condi = 1:2
        blocks = find(CondiOrder==condi);
        subTbl{condi} = [excludedTbl{blocks(1)}; excludedTbl{blocks(end)}];    %%already sorted in IM-noIM order    
        for thelevel = 1:nlevel
            trials = find(subTbl{condi}(:,flashOffsetid)==Offsets.Pix(thelevel));
            lagtrials = find(subTbl{condi}(trials,lagid) == 1);
            perctLag(condi,thelevel) = length(lagtrials)/ length(trials);
            meanRT(condi,thelevel) = mean(subTbl{condi}(trials,RTid));            
        end
        [fitresult, gof, threshold] = fitLogisticCDF(Offsets.Ang, perctLag(condi,:), 0, 0);
        pse(condi) = fitresult.c;
        adjrsqr(condi) = gof.adjrsquare;
    end
        display(pse) %the larger c is , the more the curve is shifted to the right, negative means left
    display(adjrsqr) 
    figure('Position',[0 100, 350 300]);
    plot(Offsets.Ang, perctLag(1,:),':o','Color',[0 0 0],'LineWidth',2)
    hold on;
    plot(Offsets.Ang, perctLag(2,:),'-^','Color',[0 0 0],'LineWidth',2)
    plot(Offsets.Ang,ones(nlevel,1)*0.5,'--k')
    legend('IM','noIM','Location','SouthEast')
    
    
    ScriptName= {'flash_lag_implied_motion'};
    mycode = cell(length(ScriptName),1);
    for i = 1:length(ScriptName)
        fid = fopen([ScriptName{i} '.m'],'r');
        mycode{i} = fscanf(fid,'%300c');
        fclose('all');
    end
    
    dataFile=[subName,'-',ScriptName{1}];
    if praflag==1; cd Pradata; else cd(datadir); end
    if ~exist(['./' subName],'dir');  mkdir(subName);  end
    cd(subName);
    save(dataFile);
    print( '-dpng', [subName '-IM']);
    
    cd(homeDir);
        
    clear screen;
    sca
    ShowCursor;
    PsychPortAudio('Stop', pahandle, 1);
    PsychPortAudio('Close');
    Priority(0)
    toc;
    
catch ME
    
    clear screen;
    sca;
    ShowCursor;
    PsychPortAudio('Stop', pahandle, 1);
    PsychPortAudio('Close');
    Priority(0);
    toc;
    rethrow(ME);
end
