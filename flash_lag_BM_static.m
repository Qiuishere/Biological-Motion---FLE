%%  -----------test if biological motin can result in flash lag-------------
% Qiu Han 8/8/2020
%{
% upright and inverted block interleaved according to the order of subjects
revised: can present both moving and static BM.
modified the hip position sothat two hip points are symmetrical to the
fixation
this is the formal verison of the BM and static experiments
%}
clear all; close all;
Screen('Preference', 'SkipSyncTests', 0);
KbName('UnifyKeyNames');
homeDir = pwd;
tic;
HideCursor;
recordTime = datestr(now);
debugFlag = 1;
usestatic = 0;
recordvideo = 0;

if usestatic
    Datadir = 'Data_Exp2_static_2';
    FileName = 'flash_lag_static_2';
else
    Datadir = 'Data_Exp1_BM_with_hip';
    FileName = 'flash_lag_BM_with_hip';
end

if  ~debugFlag
    subName = input('Please input the subject''s name:\n','s');
    if any(isspace(subName));   subName=strtrim(subName);  end
else
    subName='pppr';
end
praflag = 0;
if strcmp(subName(end-1:end),'pr');  praflag = 1;  end

if ~(exist(Datadir,'dir')&&exist('Pradata_static','dir')&&exist('Sbj','dir')&&exist('Prasbj','dir'))
    mkdir(Datadir);mkdir('Pradata_static');mkdir('Sbj');mkdir('Prasbj');  %Make new folder
end

%% ==========create stimuli===========
load ./actions/Walk_Front_60.mat
% id for Vanrie:
nPoint = 13;
nFrame = size(MOV,2)/nPoint;

headid=1;
shoulderid=[2 3];

elbowid=[4 5];
wristid = [6 7];
hipid=[8 9];
kneeid = [10 11];
feetid=[12 13];

LfeetTrajectory = MOV(3,feetid(1):13:end);
flashframe = find(LfeetTrajectory==max(LfeetTrajectory));

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
        newclut=zeros(ncolors,3);
        newclut(1:ncolors,:) = newcmap./monitor.maxcol;  %Values have to be in range between 0.0 (for dark pixel) and 1.0 (for maximum intensity)
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
    
    
    LAngle = 3;
    Lpixel = visAng2xyNew(LAngle, 0, monitor);
    MOV = Lpixel/max(MOV(2,:)) * MOV;
    pixpercm = [w.Rect(3)/monitor.size(1) w.Rect(4)/monitor.size(2)];
    UAngle = atand(abs(min(MOV(2,:)))/pixpercm(2)/monitor.viewDist);
    
    MOV(1,:) = MOV(1,:)- mean([MOV(1, hipid(1):13:end) MOV(1, hipid(2):13:end)]);
    MOV(2,:) = MOV(2,:)- mean([MOV(2, hipid(1):13:end) MOV(2, hipid(2):13:end)]);
plot( MOV(3,13:13:end),MOV(2,13:13:end))
    dot.Ang = 0.2;
    dot.Pix = visAng2xyNew(dot.Ang, 0, monitor);
    dot.Col = [255 255 255];
    flash.Ang = UAngle + 2*dot.Ang;%%THIS IS DIFFERENT FROM THE OTHERS!!NOTE
    flash.Pos =  -visAng2xyNew(flash.Ang, 0, monitor);
    flash.Col = [255 0 0];
    
    fix.Col = [0 0 0];
    
    
    %% =============experimental settings==============
    
    % ----------duration
    Dur.motion = 1.2;
    Dur.resp = 5;
    
    % -----------procedures
    ntrialPerlevel = 20;
    nblock = 2;
    Offsets.Ang = dot.Ang * [ -1.5, -1, - 0.5, 0, 0.5, 1, 1.5 ];

    Offsets.Pix = visAng2xyNew(Offsets.Ang, 0, monitor);
    nlevel = length(Offsets.Pix);
    if debugFlag || praflag
        ntrialPerlevel = 2;
        nblock = 2;
    end
    ntrial = ntrialPerlevel* nlevel;
    
    ResultTable = NaN(ntrial, 10, nblock);
    T = zeros(ntrial, 3, nblock);
    trialid = 1; Invid = 2; LorRid = 3;  startFrid = 4;  flashOffsetid = 5;  flashFrid = 6; flashTid = 7;  respid = 8;  RTid = 9;  lagid = 10;
    
    nsub = length(dir(['.\' Datadir]))-2;  % how many subs are there
    Invfirst = mod(nsub,2);
    ResultTable(:,Invid, 1:2:end) = Invfirst * ones(ntrial,nblock/2); %if Invfirst==1, inverted block first, ==0, upright first
    ResultTable(:,Invid, 2:2:end) = (1-Invfirst)*ones(ntrial,nblock/2); %if Invfirst==1, upright block later, ==0, inveted
    
    for i = 1:nblock
        ResultTable(:,trialid, i) = 1: ntrial;
        ResultTable(:,LorRid, i) = randSamp([-1, 1],ntrial,'n');
        ResultTable(:,flashOffsetid, i) = randSamp(Offsets.Pix,ntrial,'n');
        ResultTable(:,flashFrid, i) = randSamp(nFrame/2:nFrame,ntrial,'n'); 
        ResultTable(:,startFrid, i) = randSamp(1:nFrame,ntrial,'n');
    end
    
    Instruct{1} = {'屏幕上会出现一个由白点和黑点组成的人\n\n在某个时刻，屏幕上方会出现一个红点\n\n您需要比较:红点与人身上的黑点的水平位置\n\n如果这个红点在黑点的左边，请按左键\n\n红点在黑点右边，请按右键\n\n请尽量又快又准确地做出反应\n\n请保证全程盯紧屏幕中央的黑点\n\n\n准备好之后按空格键开始'};
    Instruct{2} = {'屏幕上会出现一个由白点和黑点组成的人\n\n在某个时刻，屏幕下方会出现一个红点\n\n您需要比较:红点与人身上的黑点的水平位置\n\n如果这个红点在黑点的左边，请按左键\n\n红点在黑点右边，请按右键\n\n请尽量又快又准确地做出反应\n\n请保证全程盯紧屏幕中央的黑点\n\n\n准备好之后按空格键开始'};
    if Invfirst
        Instruct([1,2])= Instruct([2,1]);
    end
    
    %% ============start a block==============
    for theblock = 1:nblock
         if recordvideo
             recordRect = round(CenterRect([0 0 408 408],w.Rect));
             movie = Screen('CreateMovie', w.Number, 'BM-INVERTED.avi',RectWidth(recordRect),RectHeight(recordRect),60,':CodecSettings= Videoquality=1');
        end
        if ~debugFlag
            DrawFormattedText(w.Number,double(char(Instruct{theblock})) ,'center', 'center', text.Col);
            Screen('Flip',w.Number);  %display the dots on the screen
            KbWait;
            KbReleaseWait;
            
            DrawFormattedText(w.Number,double('ready to start') ,'center', 'center', [0 0 255]);
            Screen('Flip',w.Number);  %display the dots on the screen
            WaitSecs(2);
        end
        
        for thetrial = 1:ntrial
            theori.face = ResultTable(thetrial,LorRid, theblock); % -1:left
            theori.body = ResultTable(thetrial,Invid, theblock);
            theMOV = RotationMatrix(theori.body*pi,[1 0 0])* RotationMatrix(theori.face*0.5*pi,[0 1 0])* MOV;
            theMOV(1,:) = theMOV(1,:) - mean(theMOV(1, headid:13:end));
            for fr = 1:nFrame
                theMOV(1,13*(fr-1)+hipid) =  theMOV(1,13*(fr-1)+hipid) - mean(theMOV(1,13*(fr-1)+hipid));
                theMOV(2,13*(fr-1)+hipid(1)) = theMOV(2,13*(fr-1)+hipid(2));
            end
            if theori.body == 1
                flash.Pos = visAng2xyNew(flash.Ang, 0, monitor); %below
            else
                flash.Pos = -visAng2xyNew(flash.Ang, 0, monitor); %above
            end
            theOffset = -theori.face * ResultTable(thetrial,flashOffsetid, theblock);
            % originally , positive demotes right offset, now denotes lag behind
            
            thefalshfr = ResultTable(thetrial,flashFrid, theblock);            
            startfr = ResultTable(thetrial,startFrid, theblock); %the position of the frame to draw in the sequence of MOV file

            %% =============start presenting=======
            
            vbl = Screen('Flip',w.Number); % read the time when the last flip finished
            T(thetrial,1,theblock) = vbl;
            i = 1;
            while GetSecs - T(thetrial,1,theblock) < Dur.motion- 0.5*w.ifi
                Screen('DrawDots', w.Number,[0; 0], dot.Pix,  fix.Col, w.center, 1);
                Screen('DrawingFinished', w.Number); % insert this between Flips to prevent other drwaing procedure occupying
                [vbl,StimulusOnsetTime, FlipTimestamp] = Screen('Flip',w.Number, vbl + 0.5*w.ifi);  %display the dots on the screen
                i = i+1;
                if recordvideo
                    Screen('AddFrameToMovie', w.Number,recordRect, 'frontBuffer');
                    theOffset=0;
                end
            end
            
            
            %% motoin onset
            T(thetrial,2,theblock) = vbl;
            i = 1;
            respflag = 0;
            while ~respflag && GetSecs - T(thetrial,2,theblock) < Dur.motion - 0.5*w.ifi
                
                %  draw walker
                if usestatic
                    fr = flashframe;
                else
                    fr = startfr + i-1;
                    while fr > nFrame;  fr = fr - nFrame;  end
                    while fr < 1;  fr = fr + nFrame;  end
                end

                headPos = [0; theMOV(2,fr*13-13+headid)];
                fix.Pos = [0; mean(theMOV(2, fr*13-13+ hipid))];
                Screen('DrawDots',w.Number,theMOV(1:2, fr*13-13+[2:13]),dot.Pix,dot.Col,w.center, 0);
                Screen('DrawDots',w.Number,headPos,dot.Pix,dot.Col,w.center, 0);                
                
                % draw fixation
                Screen('DrawDots', w.Number,fix.Pos, dot.Pix,  fix.Col, w.center, 0);
                
                % draw flash
                if i == thefalshfr && ismember(i,nFrame/2:nFrame) % to avoid flash agian in the second cycle
                    Screen('DrawDots',w.Number, [fix.Pos(1) + theOffset,flash.Pos] ,dot.Pix, flash.Col,w.center, 0);
                end
                Screen('DrawingFinished', w.Number); % insert this between Flips to prevent other drwaing procedure occupying
                
                [vbl,StimulusOnsetTime, FlipTimestamp] = Screen('Flip',w.Number, vbl + 0.5*w.ifi);
                if i == thefalshfr && ismember(i,nFrame/2:nFrame)
                    ResultTable(thetrial, flashTid, theblock) = StimulusOnsetTime ;
                    T(thetrial,3,theblock) = StimulusOnsetTime;
                end
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
    
%     if ~praflag
%         sca;
%         prompt = {'性别(1女，2男)',...
%             '年龄'...
%             '在人是正立时，你是否轻易地感受到人的面向方向？（ｙ／ｎ）',...
%             '在人是倒立时，你是否轻易地感受到人的面向方向？（ｙ／ｎ）'};% item of information
%         SbjInfor = inputdlg(prompt,'被试信息',1);
%     end
%     
    %% ===============reprocessing and plot===============
    validid = @(k) find(1-(isnan( ResultTable(:,respid,k)) | ResultTable(:,RTid,k)<0.2 | ResultTable(:,RTid,k)>4));
    lineColor = [62 125 95; 100 60 110; 160 130 172 ]'/255;
    for k = 1:nblock
        ResultTable(:, flashTid, k) = ResultTable(:, flashTid, k) - T(1,1,k);
        subTbl{k} = ResultTable(:,:,k);
        subTbl{k} =subTbl{k} (validid(k),:);
        
        for thelevel = 1:nlevel
            trials = find(subTbl{k}(:,flashOffsetid)==Offsets.Pix(thelevel));
            lagtrials = find(subTbl{k}(trials,lagid) == 1);
            perctLag(k,thelevel) = length(lagtrials)/ length(trials);
            meanRT(k,thelevel) = mean(subTbl{k}(trials,RTid));
        end
        [fitresult, gof, threshold] = fitLogisticCDF(Offsets.Ang, perctLag(k,:), 0, 1);
                pse(k) = fitresult.c;
        adjrsqr(k) = gof.adjrsquare;
    end
        if Invfirst
        pse = fliplr(pse);
        adjrsqr = fliplr(adjrsqr);
    end
    
    figure('Position',[0 100, 300 300]);
    for i = 1:nblock/2
        plot(Offsets.Ang, perctLag(2*i-Invfirst,:),':o','Color',[0 0 0],'LineWidth',i) %draw the inverted condition
        hold on;
        plot(Offsets.Ang, perctLag(2*i-(1-Invfirst),:),'-o','Color',[.4 .4 .4],'LineWidth',i)
        plot(Offsets.Ang,ones(nlevel,1)*0.5,'--k')
    end
    legend('inverted', 'upright','Location','SouthEast')
    
    ScriptName= {'flash_lag_BM_static'};
    mycode = cell(length(ScriptName),1);
    for i = 1:length(ScriptName)
        fid = fopen([ScriptName{i} '.m'],'r');
        mycode{i} = fscanf(fid,'%300c');
        fclose('all');
    end
    
    dataFile=[subName,'-',FileName];
    if praflag==1; cd Pradata_static; else cd(Datadir);end
    if ~exist(['./' subName],'dir');  mkdir(subName);  end
    cd(subName);
    save(dataFile);
    print( '-dpng', subName);
    
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
