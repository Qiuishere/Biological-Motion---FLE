%%  -----------test if non-biological motin can result in flash lag-------------
% Qiu Han 12/02/2019
%{

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

datadir = 'Data_2cars';
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
    Screen('BlendFunction', w.Number, GL_ONE, GL_ZERO);
    
    
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
    pixpercm = [w.Rect(3)/monitor.size(1) w.Rect(4)/monitor.size(2)];
    
    
    %% ==========create stimuli===========
    
        
    cd ./actions/car/car_pure
    img(1).nFrame =40;
    for h = 1:img(1).nFrame
        filename = ['photo' num2str(h) '.jpg'];
        X = imread(filename);
        imgtex{1,h,1}=Screen('MakeTexture', w.Number ,X);
        imgtex{1,h,2}=Screen('MakeTexture', w.Number ,fliplr(X));
    end
    cd(homeDir);
    
    img(1).W = 537;
    img(1).H = 420;
    img(1).boundary = [-55 77 -129.5 157.5]; % position of car body. from center, to above, below, left, riht
    img(1).UAngle = 2.45; % KEPP CONSISTENT EITH THE PLW
    img(1).Upixel = visAng2xyNew(img(1).UAngle, 0, monitor);
    img(1).factor = img(1).Upixel/abs(img(1).boundary(1));
    img(1).Pos = CenterRectOnPoint([0 0 img(1).factor*img(1).W img(1).factor*img(1).H], w.center(1) , w.center(2));
    
    cd ./actions/car/car_revised
    img(2).nFrame =40;
    for h = 1:img(2).nFrame
        filename = ['photo' num2str(h) '.jpg'];
        X = imread(filename);
        imgtex{2,h,1}=Screen('MakeTexture', w.Number ,X);
        imgtex{2,h,2}=Screen('MakeTexture', w.Number ,fliplr(X));
    end
    cd(homeDir);
    
%     img(2).W = 650;
%     img(2).H = 600;
%     img(2).boundary = [-347 253 -325 325]; % position of bird body. from center, to above, below, left, riht   
%     img(2).W = 684;
%     img(2).H = 480;
%         img(2).boundary = [-115 115 -300 300]; % position of bird body. from center, to above, below, left, riht   
    img(2).W = 537;
    img(2).H = 420;
    img(2).boundary = [-55 77 -129.5 157.5]; % position of car body. from center, to above, below, left, riht
    img(2).UAngle = 2.45; % KEPP CONSISTENT EITH THE PLW
    img(2).Upixel = visAng2xyNew(img(2).UAngle, 0, monitor);
    img(2).factor = img(2).Upixel/abs(img(2).boundary(1));
    img(2).Pos = CenterRectOnPoint([0 0 img(2).factor*img(2).W  img(2).factor*img(2).H], w.center(1) , w.center(2)); % this is because the dot on the bord is not its vertical midpoint.
       
    nsub = length(dir(['.\' datadir]))-2;  % how many subs are there
    static1st = mod(nsub,2);
    
    dot.Ang = 0.2;
    dot.Pix= visAng2xyNew(dot.Ang, 0, monitor);
    dot.Col = [255 255 255];
    
    flash.Ang = 3.4;
    flash.Pos =  -visAng2xyNew(flash.Ang, 0, monitor);
    flash.Col = [255 0 0];
    
    fix.Col = [0 0 0];
    fix.Pix = 6;
        recordRect = CenterRect([0 0 740 abs(2.4*flash.Pos)],w.Rect);

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
    end
    ntrial = ntrialPerlevel* nlevel;
    
    ResultTable = NaN(ntrial, 10, nblock);
    T = zeros(ntrial, 3, nblock);
    trialid = 1; startfrid = 2; LorRid = 3;  fixaTid = 4;  flashOffsetid = 5;  flashFrid = 6; flashTid = 7;  respid = 8;  RTid = 9;  lagid = 10;
    flashrange = 30:60;
    
    for i = 1:nblock
        ResultTable(:,trialid, i) = 1: ntrial;
        ResultTable(:,LorRid, i) = randSamp([-1, 1],ntrial,'n'); % 1: facing left 2:facing right
        ResultTable(:,flashOffsetid, i) = randSamp(Offsets.Pix,ntrial,'n');
        ResultTable(:,flashFrid, i) = randSamp(flashrange,ntrial,'n');
        ResultTable(:,fixaTid, i) = rand(ntrial,1)*0.5+0.5; %ranging from 0.5 to 1
    end
    
    Instruct{1} = {'屏幕上会出现一辆汽车\n\n在某个时刻，屏幕上方会出现一个红点\n\n您需要比较:红点与汽车中央的黑点的水平位置\n\n如果这个红点在黑点的左边，请按左键\n\n红点在黑点右边，请按右键\n\n请尽量又快又准确地做出反应\n\n请保证全程盯紧汽车中央的黑点\n\n\n准备好之后按空格键开始'};
    Instruct{2} = Instruct{1};
    if ~static1st
        Instruct([2 1]) = Instruct([1 2]);
    end
    
    %% ============start a block==============
    for theblock = 1:nblock
        if recordvideo
            movie = Screen('CreateMovie', w.Number, 'asymmetry_car.avi',RectWidth(recordRect),RectHeight(recordRect),60,':CodecSettings= Videoquality=1');
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
            theOffset = -theori.face * ResultTable(thetrial,flashOffsetid, theblock); % originally , positive demotes right offset, now denotes lag behind
            
            thefalshfr = ResultTable(thetrial,flashFrid, theblock);
            startfr = randi(img(theblock).nFrame) ; %the position of the frame to draw in the sequence of MOV file
            ResultTable(thetrial,startfrid, theblock) = startfr;
            
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
                if theblock==1 && static1st==1 ||theblock==2 && static1st==0
                    fr = startfr;
                else
                    fr = startfr+ i;                    
                end
                while fr > img(theblock).nFrame;  fr = fr - img(theblock).nFrame;  end
                while fr < 1;  fr = fr + img(theblock).nFrame;  end
                
                
                %  draw car

                if theori.face == -1
                    Screen('DrawTexture', w.Number, imgtex{theblock,fr,1}, [], img(theblock).Pos);
                elseif theori.face == 1
                    Screen('DrawTexture', w.Number, imgtex{theblock,fr,2}, [], img(theblock).Pos);
                end
%                 img(theblock).Pos = CenterRectOnPoint([0 0 img(theblock).factor*img(theblock).W img(theblock).factor*img(theblock).H], w.center(1) , w.center(2));

                % draw flash
                if i == thefalshfr && ismember(i,flashrange) % to avoid flash agian in the second cycle
                    Screen('DrawDots',w.Number, [theOffset,flash.Pos] ,dot.Pix, flash.Col,w.center, 0);
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
                if recordvideo            
            Screen('FinalizeMovie', movie);
        end
        % ---alarm for end of a block
        PsychPortAudio('DeleteBuffer');
        PsychPortAudio('FillBuffer', pahandle, noise_end);
        PsychPortAudio('Start', pahandle, 1, 0, 0);  WaitSecs(0.2);
        PsychPortAudio('Start', pahandle, 1, 0, 0);  WaitSecs(0.2);
        PsychPortAudio('Start', pahandle, 1, 0, 0);
    end
    if ~praflag
        sca;
        prompt = {'性别(1女，2男)','年龄'};
        SbjInfor = inputdlg(prompt,'被试信息',1);
    end

    %% ===============reprocessing and plot===============
    validid = @(k) find(1-(isnan( ResultTable(:,respid,k)) | ResultTable(:,RTid,k)<0.2 | ResultTable(:,RTid,k)>4));
    if ~static1st
        ResultTable(:,:,[1 2]) = ResultTable(:,:,[2 1]);
    end
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
    end
    
    figure('Position',[0 100, 350 300]);    
    plot(Offsets.Ang, perctLag(1,:),':o','Color',[0 0 0],'LineWidth',2)
    hold on;
    plot(Offsets.Ang, perctLag(2,:),'-o','Color',[0 0 0],'LineWidth',2)
    plot(Offsets.Ang,ones(nlevel,1)*0.5,'--k')
    legend('static','motion','Location','SouthEast')
    
    
    ScriptName= {'flash_lag_Car'};
    mycode = cell(length(ScriptName),1);
    for i = 1:length(ScriptName)
        fid = fopen([ScriptName{i} '.m'],'r');
        mycode{i} = fscanf(fid,'%300c');
        fclose('all');
    end
    
    dataFile=[subName,'-',ScriptName{1}];
    if praflag==1; cd Pradata_car; else cd(datadir); end
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
