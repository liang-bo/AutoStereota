function AutoStereota()
%
% Main function
%
% Define global varibles
global currentPositionX  currentPositionY  currentPositionZ
global pausePositionX pausePositionY pausePositionZ
global surgIdx isPause isFinished isStop isAutozlim
global isMotorStop stopMotor
global useEncoderX useEncoderY useEncoderZ
global limMotionX limMotionY limMotionZ
%% Load initial data
% loadphidget21;
loadlibrary('phidget21', @mHeader)
ipath = ('C:\Program Files\AutoStereota\application\'); % change this to the current folder if you want to lauch it in MATLAB
% ipath = ('D:\AutoStereo\');

ifile1 = strcat(ipath,'Para.ini');
ifile2 = strcat(ipath,'Steps.ini');

initData = load(ifile1);
iStepMatrix = load(ifile2);

initDataX = initData(1,:); % velocity limit; Acceleration; Current Limt; Step; Position
initDataY = initData(2,:);
initDataZ = initData(3,:);

initEncoder = initData(4,:);

unitStep = fix(360/0.13*16);% pulses per mm
tolPulseNum = 5;%round(360/0.13*16/10000);
isMotorStop = true;

[stepperHandleX, isopenX] = stepperInit(initDataX);
[stepperHandleY, isopenY] = stepperInit(initDataY);
[stepperHandleZ, isopenZ] = stepperInit(initDataZ);

encoderSerialNumber = initEncoder(1);%298920;

initPosition = [-initDataX(6)*unitStep;-initDataY(6)*unitStep;-initDataZ(6)*unitStep;];

encoderHandle = encoderInit(encoderSerialNumber,initPosition);

stepperHandles.stepperHandleX = stepperHandleX;
stepperHandles.stepperHandleY = stepperHandleY;
stepperHandles.stepperHandleZ = stepperHandleZ;
stepperHandles.encoderHandle = encoderHandle;


currentPositionX = fix(initDataX(6)*unitStep);
currentPositionY = fix(initDataY(6)*unitStep);
currentPositionZ = fix(initDataZ(6)*unitStep);

targetPositionX = currentPositionX;
targetPositionY = currentPositionY;
targetPositionZ = currentPositionZ;

pausePositionX = currentPositionX;
pausePositionY = currentPositionY;
pausePositionZ = currentPositionZ;

bregmaPositionX = nan;
bregmaPositionY = nan;
bregmaPositionZ = nan;
isBregmaOn = false;
bregmaX = 0;
bregmaY = 0;
bregmaZ = 0;

%% Declarition
hview_fig=nan; %initialize the handle for modeview figure
hview_ax = nan; %initialize the handle for modeview figure axis
hview_log = nan;

hf_zStep = nan;
hf_pFinder = nan;

hp_xInputEdt = nan;
hp_yInputEdt = nan;
hp_zInputEdt = nan;

hview_zeroInfoE = nan;
hview_bregInfoE = nan;
hview_statusInfoE = nan;
hview_statusInfoB = nan;
hview_statusInfoZ = nan;
hview_statusInfoS = nan;
hview_curDemInfX = nan;
hview_curDemInfY = nan;
hview_curDemInfZ = nan;
hview_holeDepth = nan;

hzstep_confirm = nan;

h_zoombtn = nan;
h_rotbtn = nan;
h_topviewBtn = nan;
h_sideviewBtn = nan;
h_zAutoBtn = nan;
AZ = 0;
EL = 0;

orient = 1;

isAutozlim = true;
isFirstTime = true;

useEncoderX = initEncoder(2);
useEncoderY = initEncoder(3);
useEncoderZ = initEncoder(4);

stopMotor = false(3,1);
motionGrid = 0;% define the motion grid as an global varible
isPause = false;%flag to mark start or pause
isFinished =false;%flag to mark a procedure finished or not
isStop = false;%flag to mark stop
surgIdx = 1; % tracking where the procedure goes
limMotionX = nan;
limMotionY = nan;
limMotionZ = nan;
stepCheck = zeros(5,1);
stepValue = zeros(5,1);
stepTime  = zeros(5,1);
stepMatrix =iStepMatrix(1:5,:);
surgPos = iStepMatrix(6,:);
mode = 1;%default mode
Ndl_ID = 0.16;%Unit:mm
Ndl_OD = 0.31;
Ndl_D = Ndl_ID/2+Ndl_OD/2;
isModeViewOpen = false;
holeDepth = stepMatrix(:,1).*stepMatrix(:,2).*stepMatrix(:,3) - surgPos(3);
%% Create Main Figure Container
x_offset = 50;
y_offset = 50;
figWidth = 600;
figHeight = 600;
side = 15;
inner = 10;
offset = 30;
ext_Leng = 200;
fpos    = get(0,'DefaultFigurePosition');
fpos(1) = ceil(x_offset); % X position
fpos(2) = ceil(y_offset); % Y position
fpos(3) = ceil(figWidth);
fpos(4) = ceil(figHeight+offset+ext_Leng);
hf_main= figure('unit','pixel',...
    'Position', fpos,...
    'Menubar','none',...
    'color','white',...
    'Name','AutoStereota - Designed for Brain Tissue Aspiration',...
    'numbertitle','off',...
    'resize','off',...
    'CloseRequestFcn',@closeFigRequest);
panelHeight = (figHeight - 2*side -3*inner)/4;
panelWidth = figWidth - 2*side;

iconName = strcat(ipath,'mouseIcon.png');
showIcon(hf_main);
WinOnTop(hf_main,true);

    function showIcon(h)
        % Show ICON for UIcontrol
        warning('off','MATLAB:HandleGraphics:ObsoletedProperty:JavaFrame');
        jframe=get(h,'javaframe');
        jIcon=javax.swing.ImageIcon(iconName);
        jframe.setFigureIcon(jIcon);
    end

% X axis Setting
hp_aX = uipanel('Parent',hf_main,...
    'FontSize',12,...
    'BackgroundColor','white',...
    'unit','pix',...
    'Title', 'X-Axis',...
    'Position',[side figHeight+ext_Leng-side-panelHeight+offset panelWidth panelHeight]);
hp_subX = drawpanel(hp_aX,initDataX,initEncoder(2),stepperHandleX);
set(hp_subX.h_posMov,'String','Lateral')
set(hp_subX.h_negMov,'String','Medial')

% Y axis Setting
hp_aY = uipanel('Parent',hf_main,...
    'FontSize',12,...
    'BackgroundColor','white',...
    'unit','pix',...
    'Title', 'Y-Axis',...
    'Position',[side figHeight+ext_Leng-side-inner-2*panelHeight+offset panelWidth panelHeight]);
hp_subY = drawpanel(hp_aY,initDataY,initEncoder(3),stepperHandleY);
set(hp_subY.h_posMov,'String','Rostral')
set(hp_subY.h_negMov,'String','Caudal')

% Z axis Setting
hp_aZ = uipanel('Parent',hf_main,...
    'FontSize',12,...
    'BackgroundColor','white',...
    'unit','pix',...
    'Title', 'Z-Axis',...
    'Position',[side figHeight+ext_Leng-side-2*inner-3*panelHeight+offset panelWidth panelHeight]);

hp_subZ = drawpanel(hp_aZ,initDataZ,initEncoder(4),stepperHandleZ);
set(hp_subZ.h_posMov,'String','Dorsal')
set(hp_subZ.h_negMov,'String','Ventral')

panelHandles.panelHandleX = hp_subX;
panelHandles.panelHandleY = hp_subY;
panelHandles.panelHandleZ = hp_subZ;

%% Add callback for Encoder and Stop button
set([hp_subX.h_encoder,hp_subY.h_encoder,hp_subZ.h_encoder],'callback',@encoderCallback)
set([hp_subX.h_stop,hp_subY.h_stop,hp_subZ.h_stop],'callback',@stopCallback)

    function encoderCallback(varargin)
        
        handle= varargin{1};
        status = false;
        switch handle
            case hp_subX.h_encoder
                useEncoderX = get(handle,'value');
                status = useEncoderX;
            case hp_subY.h_encoder
                useEncoderY = get(handle,'value');
                status = useEncoderY;
            case hp_subZ.h_encoder
                useEncoderZ = get(handle,'value');
                status = useEncoderZ;
        end
        
        if status
            set(handle, 'BackgroundColor',[0.14,0.64,0.14])
        else
            set(handle, 'BackgroundColor',[0.94,0.94,0.94])
        end
    end

    function stopCallback(varargin)
        
        handle= varargin{1};
        switch handle
            case hp_subX.h_stop
                %                 stopMotor(1) = true;
            case hp_subY.h_stop
                %                 stopMotor(2) = true;
            case hp_subZ.h_stop
                %                 stopMotor(3) = true;
        end
    end

%% Add a listener for the value change of position
jScrollBarX = findjobj(hp_subX.h_slider);
jScrollBarX.AdjustmentValueChangedCallback = {@xpositionChange};

    function xpositionChange(varargin)
        if isMotorStop
            sValue = get(hp_subX.h_slider,'value')/1000;
            set(hp_subX.h_positionEdt,'string',num2str(sValue))
            if sValue > 80
                targetPositionX = fix(80*unitStep);
                currentPositionX = moveToPosition(targetPositionX, stepperHandleX, hp_subX, encoderHandle, 0, useEncoderX);
            elseif sValue < 0
                targetPositionX = fix(0*unitStep);
                currentPositionX = moveToPosition(targetPositionX, stepperHandleX, hp_subX, encoderHandle,0, useEncoderX);
            else
                targetPositionX = fix(sValue*unitStep);
                currentPositionX = moveToPosition(targetPositionX, stepperHandleX, hp_subX, encoderHandle,0, useEncoderX);
            end
        end
    end

jScrollBarY = findjobj(hp_subY.h_slider);
jScrollBarY.AdjustmentValueChangedCallback = {@ypositionChange};

    function ypositionChange(varargin)
%         display(isMotorStop)
        if isMotorStop
            sValue = get(hp_subY.h_slider,'value')/1000;
            set(hp_subY.h_positionEdt,'string',num2str(sValue))
            if sValue > 80
                targetPositionY = fix(80*unitStep);
                currentPositionY = moveToPosition(targetPositionY, stepperHandleY, hp_subY, encoderHandle,1, useEncoderY);
            elseif sValue < 0
                targetPositionY = fix(0*unitStep);
                currentPositionY = moveToPosition(targetPositionY, stepperHandleY, hp_subY, encoderHandle,1, useEncoderY);
            else
                targetPositionY = fix(sValue*unitStep);
                currentPositionY = moveToPosition(targetPositionY, stepperHandleY, hp_subY, encoderHandle,1, useEncoderY);
            end
        end
    end


jScrollBarZ = findjobj(hp_subZ.h_slider);
jScrollBarZ.AdjustmentValueChangedCallback = {@zpositionChange};

    function zpositionChange(varargin)
        if isMotorStop
            sValue = get(hp_subZ.h_slider,'value')/1000;
            set(hp_subZ.h_positionEdt,'string',num2str(sValue))
            if sValue > 80
                targetPositionZ = fix(80*unitStep);
                currentPositionZ = moveToPosition(targetPositionZ, stepperHandleZ, hp_subZ, encoderHandle,2, useEncoderZ);
            elseif sValue < 0
                targetPositionZ = fix(0*unitStep);
                currentPositionZ = moveToPosition(targetPositionZ, stepperHandleZ, hp_subZ, encoderHandle,2, useEncoderZ);
            else
                targetPositionZ = fix(sValue*unitStep);
                currentPositionZ = moveToPosition(targetPositionZ, stepperHandleZ, hp_subZ, encoderHandle,2, useEncoderZ);
            end
        end
    end
%% Callback function for Button: Update Zero + and -
set([hp_subX.h_negMov,hp_subY.h_negMov,hp_subZ.h_negMov],'callback',@negMovCallback)
set([hp_subX.h_posMov,hp_subY.h_posMov,hp_subZ.h_posMov],'callback',@posMovCallback)

    function posMovCallback(varargin)
        handle= varargin{1};
        switch handle
            case hp_subX.h_posMov

                pos_temp = str2double(get(hp_subX.h_positionEdt,'string'));
                step_temp = str2double(get(hp_subX.h_stepEdt,'string'));
                
                if (pos_temp+step_temp) <= 80.00
                    stepX = fix(step_temp*unitStep);
                    targetPositionX = currentPositionX + stepX;
                    currentPositionX = moveToPosition(targetPositionX, stepperHandleX, hp_subX, encoderHandle,0, useEncoderX);
                else
                    h_msg = msgbox('Please Input Value: 0 - 80!','Warning');
                    WinOnTop( h_msg, true);
                end
                
            case hp_subY.h_posMov
                
                pos_temp = str2double(get(hp_subY.h_positionEdt,'string'));
                step_temp = str2double(get(hp_subY.h_stepEdt,'string'));
                
                if (pos_temp+step_temp) <= 80.00
                    stepY = fix(step_temp*unitStep);
                    targetPositionY = currentPositionY + stepY;
                    currentPositionY = moveToPosition(targetPositionY, stepperHandleY, hp_subY, encoderHandle,1, useEncoderY);
                else
                    h_msg = msgbox('Please Input Value: 0 - 80!','Warning');
                    WinOnTop( h_msg, true);
                end
                
            case hp_subZ.h_posMov
                
                pos_temp = str2double(get(hp_subZ.h_positionEdt,'string'));
                step_temp = str2double(get(hp_subZ.h_stepEdt,'string'));
                
                if (pos_temp+step_temp) <= 80.00
                    stepZ = fix(step_temp*unitStep);
                    targetPositionZ = currentPositionZ + stepZ;
                    currentPositionZ = moveToPosition(targetPositionZ, stepperHandleZ, hp_subZ, encoderHandle,2, useEncoderZ);
                else
                    h_msg = msgbox('Please Input Value: 0 - 80!','Warning');
                    WinOnTop( h_msg, true);
                end
                
            otherwise
                display('Do nothing!')
        end
        
    end

    function negMovCallback(varargin)
        handle= varargin{1};
        switch handle
            case hp_subX.h_negMov
                
                pos_temp = str2double(get(hp_subX.h_positionEdt,'string'));
                step_temp = str2double(get(hp_subX.h_stepEdt,'string'));
                
                if (pos_temp-step_temp) >= 0.00
                    stepX = fix(step_temp*unitStep);
                    targetPositionX = currentPositionX - stepX;
                    currentPositionX = moveToPosition(targetPositionX, stepperHandleX, hp_subX, encoderHandle,0, useEncoderX);
                else
                    h_msg = msgbox('Please Input Value: 0 - 80!','Warning');
                    WinOnTop( h_msg, true);
                end
                
            case hp_subY.h_negMov
                
                pos_temp = str2double(get(hp_subY.h_positionEdt,'string'));
                step_temp = str2double(get(hp_subY.h_stepEdt,'string'));
                
                if (pos_temp-step_temp) >= 0.00
                    stepY = fix(step_temp*unitStep);
                    targetPositionY = currentPositionY - stepY;
                    currentPositionY = moveToPosition(targetPositionY, stepperHandleY, hp_subY, encoderHandle,1, useEncoderY);
                else
                    h_msg = msgbox('Please Input Value: 0 - 80!','Warning');
                    WinOnTop( h_msg, true);
                end
                
            case hp_subZ.h_negMov
                
                pos_temp = str2double(get(hp_subZ.h_positionEdt,'string'));
                step_temp = str2double(get(hp_subZ.h_stepEdt,'string'));
                
                if (pos_temp-step_temp) >= 0.00
                    stepZ = fix(step_temp*unitStep);
                    targetPositionZ = currentPositionZ - stepZ;
                    currentPositionZ = moveToPosition(targetPositionZ, stepperHandleZ, hp_subZ, encoderHandle,2, useEncoderZ);
                else
                    h_msg = msgbox('Please Input Value: 0 - 80!','Warning');
                    WinOnTop( h_msg, true);
                end
                
            otherwise
                display('Do nothing!')
        end
    end
%% Mode Setting
hp_mode = uipanel('Parent',hf_main,...
    'FontSize',12,...
    'BackgroundColor','white',...
    'unit','pix',...
    'Title', 'Mode',...
    'Position',[side+220 side+offset+ext_Leng panelWidth/2+65 panelHeight]);
hp_subMode.modeTxt =   uicontrol('Parent',hp_mode,...   % mode Label
    'Style','text',...
    'unit','pixel',...
    'Position',[5 75 100 20],...
    'Backgroundcolor',get(hp_mode,'Backgroundcolor'),...
    'HorizontalAlignment','right',...
    'FontSize',12,...
    'String','Select Mode:');
hp_subMode.modeList =   uicontrol('Parent',hp_mode,...   % mode
    'Style','popupmenu',...
    'unit','pixel',...
    'Position',[115 80 150 20],...
    'FontSize',12,...
    'String',{'Cylinder','Flat Circle','Triangular prism','Cube'},...
    'callback',@setMode);
hp_subMode.needleTxt =   uicontrol('Parent',hp_mode,...   % needle Label
    'Style','text',...
    'unit','pixel',...
    'Position',[5 45 100 20],...
    'Backgroundcolor',get(hp_mode,'Backgroundcolor'),...
    'HorizontalAlignment','right',...
    'FontSize',12,...
    'String','Needle Size:');
hp_subMode.needleList =   uicontrol('Parent',hp_mode,...   % needle list
    'Style','popupmenu',...
    'unit','pixel',...
    'Position',[115 50 100 20],...
    'FontSize',12,...
    'String',{'30 Gauge','29 Gauge','28 Gauge','27 Gauge'},...
    'callback',@setNeedle);
hp_subMode.needleEdt =   uicontrol('Parent',hp_mode,...   % needle samling number
    'Style','edit',...
    'unit','pixel',...
    'Position',[220 45 45 20],...
    'FontSize',12,...
    'String','2');

hp_subMode.holeDiameterTxt =   uicontrol('Parent',hp_mode,...   % needle samling number
    'Style','text',...
    'unit','pixel',...
    'HorizontalAlignment','left',...
    'Backgroundcolor',get(hp_mode,'Backgroundcolor'),...
    'Position',[10 15 50 20],...
    'FontSize',12,...
    'String','Dims:');

hp_subMode.holeDiameterEdt =   uicontrol('Parent',hp_mode,...   % needle samling number
    'Style','edit',...
    'unit','pixel',...
    'Position',[65 15 50 20],...
    'FontSize',12,...
    'String','1.0');
hp_subMode.orientationTxt =   uicontrol('Parent',hp_mode,...   % needle samling number
    'Style','text',...
    'unit','pixel',...
    'Position',[140 15 40 20],...
    'Backgroundcolor',get(hp_mode,'Backgroundcolor'),...
    'FontSize',12,...
    'String','Orin:');
hp_subMode.orientationList =   uicontrol('Parent',hp_mode,...   % needle list
    'Style','popupmenu',...
    'unit','pixel',...
    'Position',[185 20 80 20],...
    'FontSize',12,...
    'String',{'Rostral','Caudal','Lateral','Medial'},...
    'callback',@setOrientation);
hp_subMode.modeview = uicontrol('Parent',hp_mode,...   % Start
    'Style','togglebutton',...
    'unit','pixel',...
    'Position',[275 15 60 80],...
    'FontSize',12,...
    'String','View',...
    'value',true,...
    'callback',@modeView);

modeView();

    function setMode(source,~)
        modenums = source.Value;
        mode  = modenums;
        modeViewUpdate();
        
    end

    function setNeedle(source,~)
        needlenum = source.Value;
        switch needlenum
            case 1 % 30 Gauge
                Ndl_ID=0.16;%Unit:mm
                Ndl_OD=0.31;
            case 2 % 29 Gauge
                Ndl_ID=0.18;%Unit:mm
                Ndl_OD=0.34;
                
            case 3 % 28 Gauge
                Ndl_ID=0.18;%Unit:mm
                Ndl_OD=0.36;
            case 4 % 27 Gauge
                Ndl_ID=0.21;%Unit:mm
                Ndl_OD=0.41;
            otherwise %  Gauge
                Ndl_ID=0.26;%Unit:mm
                Ndl_OD=0.46;
        end
        Ndl_D = (Ndl_ID+Ndl_OD)/2;
        modeViewUpdate();
        
    end

    function setOrientation(source,~)
        orient = source.Value;
        modeViewUpdate();
    end
%% Control button START - PAUSE - STOP
hp_control = uipanel('Parent',hf_main,...
    'FontSize',12,...
    'BackgroundColor','white',...
    'Title', 'Control',...
    'unit','pix',...
    'Position',[side+440 side+offset 130 panelHeight+50]);
ctrlBtnWidth = 130-2*side;
ctrlBtnHeight = ( panelHeight+50-3*inner)/6;

hp_subControl.start = uicontrol('Parent',hp_control,...   % Pause
    'Style','push',...
    'unit','pixel',...
    'Position',[side ctrlBtnHeight+side+inner ctrlBtnWidth ctrlBtnHeight],...
    'FontSize',12,...
    'String','Start',...
    'callback',@startSurg);
hp_subControl.stop = uicontrol('Parent',hp_control,...   % Stop
    'Style','push',...
    'unit','pixel',...
    'Position',[side side ctrlBtnWidth ctrlBtnHeight],...
    'FontSize',12,...
    'String','Stop2Zero',...
    'callback',@stopSurg);

%% Zero position and back to zero position
zeroPositionX = currentPositionX;
zeroPositionY = currentPositionY;
zeroPositionZ = currentPositionZ;
isZeroSet = false;
zeroX = str2double(get(hp_subX.h_positionEdt,'string'));
zeroY = str2double(get(hp_subY.h_positionEdt,'string'));
zeroZ = str2double(get(hp_subZ.h_positionEdt,'string'));
% stepBtnHeight = (panelHeight-2*side-3*inner-5)/3;
hp_subControl.hp_kzero = uicontrol('Parent',hp_control,...
    'FontSize',12,...
    'Style','pushbutton',...
    'unit','pix',...
    'Position',[side 3*ctrlBtnHeight+side+3*inner ctrlBtnWidth ctrlBtnHeight],...
    'String','KeepZero',...
    'Callback',@keepZero);

    function keepZero(varargin)
        zeroPositionX = currentPositionX;
        zeroPositionY = currentPositionY;
        zeroPositionZ = currentPositionZ;
        
        pausePositionX = currentPositionX;
        pausePositionY = currentPositionY;
        pausePositionZ = currentPositionZ;
        
        isZeroSet = true;
        zeroX = str2double(get(hp_subX.h_positionEdt,'string'));
        zeroY = str2double(get(hp_subY.h_positionEdt,'string'));
        zeroZ = str2double(get(hp_subZ.h_positionEdt,'string'));
        
        zeroPos = [' [X]  ', num2str(zeroX),...
            ';  [Y]  ', num2str(zeroY),...
            ';  [Z]  ', num2str(zeroZ),...
            ';'];
        
        set(hview_zeroInfoE,'String',zeroPos)
        set(hp_subControl.hp_kzero,'BackgroundColor',[0.14,0.64,0.14])
        
        if iszStepSet
            set(hview_statusInfoE,'String','Ready')
            set(hview_statusInfoE,'ForegroundColor','r')
            holeDepth = sum(stepCheck.*stepValue.*stepTime) - zeroZ + bregmaZ;
            set(hview_holeDepth,'String',num2str(holeDepth));
        end
        set(hview_statusInfoZ,'ForegroundColor','r')
    end

uicontrol('Parent',hp_control,...
    'FontSize',12,...
    'Style','pushbutton',...
    'unit','pix',...
    'Position',[side 2*ctrlBtnHeight+side+2*inner ctrlBtnWidth ctrlBtnHeight],...
    'String','BackZero',...
    'Callback',@backZero);

    function backZero(varargin)
        
        isZeroSet = false;
        currentPositionX = moveToPosition(zeroPositionX, stepperHandleX, hp_subX, encoderHandle,0, useEncoderX);
        currentPositionY = moveToPosition(zeroPositionY, stepperHandleY, hp_subY, encoderHandle,1, useEncoderY);
        currentPositionZ = moveToPosition(zeroPositionZ, stepperHandleZ, hp_subZ, encoderHandle,2, useEncoderZ);
        
        set(hp_subControl.hp_kzero,'BackgroundColor',[0.94,0.94,0.94])%set to default color
        set(hview_statusInfoE,'ForegroundColor','k')
        set(hview_statusInfoZ,'ForegroundColor','k')
        
    end


%% Mode view
    function modeView(varargin)
        isModeViewOpen = get(hp_subMode.modeview,'value');
        if isModeViewOpen
            % set the new panel
            fpos0    = get(hf_main,'Position');
            set(hf_main,'position',[fpos0(1) fpos0(2) fpos(3)+420 fpos(4)])
            
            hview_fig= uipanel('Parent',hf_main,...
                'unit','pixel',...
                'Position', [fpos(3) 0 420 fpos(4)]);
            
            sampleFactor = str2double(get(hp_subMode.needleEdt,'String'));
            holeDia = str2double(get(hp_subMode.holeDiameterEdt,'String')); %% Unit:mm
            holeDia_hf = holeDia/2;
            
            sampleStep=Ndl_ID/sampleFactor;
            sampleNum=fix(holeDia_hf/sampleStep)*2;
            sampleStep = holeDia/sampleNum;
            
            %             motionGrid = gridGenerator(sampleNum,sampleStep,mode);
            motionGrid = stepGenerator(sampleNum,sampleStep,mode,stepMatrix,orient,holeDepth);
            
            
            
            %Define the axes
            hview_ax = axes('unit','pixel','Position',[50 225 350 350],'parent',hview_fig);
            
            if isAutozlim
                limMotionZ = [-max(motionGrid(:,3))*1.1 -min(motionGrid(:,3))*0.9];
            else
                limMotionZ = [-max(motionGrid(:,3))*1.1 0];
            end
            
            switch mode
                case 1
                    limMotionX = [-1.1*(holeDia/2) 1.1*(holeDia/2)];
                    limMotionY = [-1.1*(holeDia/2) 1.1*(holeDia/2)];
                    
                case 2
                    limMotionX = [-1.1*(holeDia/2) 1.1*(holeDia/2)];
                    limMotionY = [-1.1*(holeDia/2) 1.1*(holeDia/2)];
                    limMotionZ = [-1 1];
                case 3
                    limMotionX = [-max(abs(motionGrid(:,1))) max(abs(motionGrid(:,1)))];
                    limMotionY = [-max(abs(motionGrid(:,2))) max(abs(motionGrid(:,2)))];
                case 4
                    limMotionX = [-max(abs(motionGrid(:,1))) max(abs(motionGrid(:,1)))];
                    limMotionY = [-max(abs(motionGrid(:,2))) max(abs(motionGrid(:,2)))];
            end
            
            hold off;
            plot3(hview_ax,motionGrid(:,1),motionGrid(:,2),-motionGrid(:,3),'o--','color',[0.1 0.1 0.1])
            hold on;
            [AZ,EL] = view;%Get the default view angles
            set(hview_ax,'xLim',limMotionX,'yLim',limMotionY,'zLim',limMotionZ,...
                'XGrid','on','YGrid','on','ZGrid','on',...
                'xTick',[-holeDia/2:holeDia/10:holeDia/2],'yTick',[-holeDia/2:holeDia/10:holeDia/2])
            
            % Define button to zoom and rotate
            h_zoombtn = uicontrol('Parent',hview_fig,...
                'style','togglebutton',...
                'unit','pixel',...
                'String','Zoom',...
                'Position',[30 165 50 30],...
                'Callback',@zoomcallback);
            h_rotbtn = uicontrol('Parent',hview_fig,...
                'style','togglebutton',...
                'unit','pixel',...
                'String','Rotate',...
                'Position',[85 165 50 30],...
                'Callback',@rotatecallback);
            
            h_topviewBtn = uicontrol('Parent',hview_fig,...
                'style','togglebutton',...
                'unit','pixel',...
                'String','Top',...
                'Position',[300 165 50 30],...
                'Callback',@topviewcallback);
            
            h_sideviewBtn = uicontrol('Parent',hview_fig,...
                'style','togglebutton',...
                'unit','pixel',...
                'String','Side',...
                'Position',[360 165 50 30],...
                'Callback',@sideviewcallback);
            
            h_zAutoBtn = uicontrol('Parent',hview_fig,...
                'style','togglebutton',...
                'unit','pixel',...
                'String','Auto',...
                'Position',[175 165 75 30],...
                'value',true,...
                'BackgroundColor',[0.14,0.64,0.14],...
                'Callback',@autoZLim);
            
            %Define the info text
            hposition = 790;
            bgcolor = [0.94,0.94,0.94];
            uicontrol('Parent',hview_fig,...
                'style','text',...
                'unit','pixel',...
                'FontSize',12,...
                'HorizontalAlignment','Right',...
                'BackgroundColor',bgcolor,...
                'Position',[30 hposition 65 20],...
                'String','Status:');
            
            hview_statusInfoE = uicontrol('Parent',hview_fig,...
                'style','text',...
                'unit','pixel',...
                'FontSize',12,...
                'BackgroundColor',bgcolor,...
                'HorizontalAlignment','Left',...
                'Position',[110 hposition 80 20],...
                'String','Ready');
            hview_statusInfoB = uicontrol('Parent',hview_fig,...
                'style','text',...
                'unit','pixel',...
                'FontSize',12,...
                'BackgroundColor',bgcolor,...
                'HorizontalAlignment','Left',...
                'Position',[180 hposition 80 20],...
                'String','Bregma');
            hview_statusInfoZ = uicontrol('Parent',hview_fig,...
                'style','text',...
                'unit','pixel',...
                'FontSize',12,...
                'BackgroundColor',bgcolor,...
                'HorizontalAlignment','Left',...
                'Position',[260 hposition 80 20],...
                'String','ZERO');
            hview_statusInfoS = uicontrol('Parent',hview_fig,...
                'style','text',...
                'unit','pixel',...
                'FontSize',12,...
                'BackgroundColor',bgcolor,...
                'HorizontalAlignment','Left',...
                'Position',[330 hposition 80 20],...
                'String','STEP');
            
            uicontrol('Parent',hview_fig,...
                'style','text',...
                'unit','pixel',...
                'FontSize',12,...
                'BackgroundColor',bgcolor,...
                'HorizontalAlignment','Right',...
                'Position',[30 hposition-30 65 20],...
                'String','Bregma:');
            
            bregmaPos = [' [X]  ',get(hp_subX.h_positionEdt,'string'),...
                ';  [Y]  ',get(hp_subY.h_positionEdt,'string'),...
                ';  [Z]  ',get(hp_subZ.h_positionEdt,'string'),...
                ';'];
            hview_bregInfoE = uicontrol('Parent',hview_fig,...
                'style','text',...
                'unit','pixel',...
                'FontSize',12,...
                'BackgroundColor',bgcolor,...
                'HorizontalAlignment','Left',...
                'Position',[95 hposition-30 300 20],...
                'String',bregmaPos);
            
            uicontrol('Parent',hview_fig,...
                'style','text',...
                'unit','pixel',...
                'FontSize',12,...
                'BackgroundColor',bgcolor,...
                'HorizontalAlignment','Right',...
                'Position',[30 hposition-60 65 20],...
                'String','Zero:');
            
            hview_zeroInfoE = uicontrol('Parent',hview_fig,...
                'style','text',...
                'Backgroundcolor','white',...
                'unit','pixel',...
                'FontSize',12,...
                'BackgroundColor',bgcolor,...
                'HorizontalAlignment','Left',...
                'Position',[95 hposition-60 300 20],...
                'String',bregmaPos);
            
            uicontrol('Parent',hview_fig,...
                'style','text',...
                'ForegroundColor','blue',...
                'unit','pixel',...
                'FontSize',12,...
                'BackgroundColor',bgcolor,...
                'HorizontalAlignment','Right',...
                'Position',[30 hposition-90 175 20],...
                'String','Hole Depth [Bregma]:');
            
            hview_holeDepth = uicontrol('Parent',hview_fig,...
                'style','text',...
                'ForegroundColor','blue',...
                'unit','pixel',...
                'FontSize',12,...
                'BackgroundColor',bgcolor,...
                'HorizontalAlignment','Left',...
                'Position',[250 hposition-90 50 20],...
                'String','NaN');
            uicontrol('Parent',hview_fig,...
                'style','text',...
                'ForegroundColor','blue',...
                'unit','pixel',...
                'FontSize',12,...
                'BackgroundColor',bgcolor,...
                'HorizontalAlignment','Left',...
                'Position',[300 hposition-90 30 20],...
                'String','mm');
            
            
            uicontrol('Parent',hview_fig,...
                'style','text',...
                'ForegroundColor','red',...
                'unit','pixel',...
                'FontSize',12,...
                'BackgroundColor',bgcolor,...
                'HorizontalAlignment','Right',...
                'Position',[30 hposition-120 200 20],...
                'String','Needle Tip to Bregma:  [X]');
            hview_curDemInfX = uicontrol('Parent',hview_fig,...
                'style','text',...
                'ForegroundColor','red',...
                'unit','pixel',...
                'FontSize',12,...
                'BackgroundColor',bgcolor,...
                'HorizontalAlignment','Left',...
                'Position',[250 hposition-120 50 20],...
                'String','NaN');
            uicontrol('Parent',hview_fig,...
                'style','text',...
                'ForegroundColor','red',...
                'unit','pixel',...
                'FontSize',12,...
                'BackgroundColor',bgcolor,...
                'HorizontalAlignment','Left',...
                'Position',[300 hposition-120 30 20],...
                'String','mm');
            
            uicontrol('Parent',hview_fig,...
                'style','text',...
                'ForegroundColor','red',...
                'unit','pixel',...
                'FontSize',12,...
                'BackgroundColor',bgcolor,...
                'HorizontalAlignment','Right',...
                'Position',[30 hposition-150 200 20],...
                'String','[Y]');
            hview_curDemInfY = uicontrol('Parent',hview_fig,...
                'style','text',...
                'ForegroundColor','red',...
                'unit','pixel',...
                'FontSize',12,...
                'BackgroundColor',bgcolor,...
                'HorizontalAlignment','Left',...
                'Position',[250 hposition-150 50 20],...
                'String','NaN');
            uicontrol('Parent',hview_fig,...
                'style','text',...
                'ForegroundColor','red',...
                'unit','pixel',...
                'FontSize',12,...
                'BackgroundColor',bgcolor,...
                'HorizontalAlignment','Left',...
                'Position',[300 hposition-150 30 20],...
                'String','mm');
            
            uicontrol('Parent',hview_fig,...
                'style','text',...
                'ForegroundColor','red',...
                'unit','pixel',...
                'FontSize',12,...
                'BackgroundColor',bgcolor,...
                'HorizontalAlignment','Right',...
                'Position',[30 hposition-180 200 20],...
                'String','[Z]');
            hview_curDemInfZ = uicontrol('Parent',hview_fig,...
                'style','text',...
                'ForegroundColor','red',...
                'unit','pixel',...
                'FontSize',12,...
                'BackgroundColor',bgcolor,...
                'HorizontalAlignment','Left',...
                'Position',[250 hposition-180 50 20],...
                'String','NaN');
            uicontrol('Parent',hview_fig,...
                'style','text',...
                'ForegroundColor','red',...
                'unit','pixel',...
                'FontSize',12,...
                'BackgroundColor',bgcolor,...
                'HorizontalAlignment','Left',...
                'Position',[300 hposition-180 30 20],...
                'String','mm');
            %Define the Log input Box
            hview_log = uicontrol('Parent',hview_fig,...
                'style','edit',...
                'unit','pixel',...
                'HorizontalAlignment','Left',...
                'MAX',2,...
                'Position',[30 10 320 125]);
            uicontrol('Parent',hview_fig,...
                'style','push',...
                'unit','pixel',...
                'String','Save',...
                'Position',[360 80 50 50],...
                'Callback',@saveLog);
            panelHandles.hview_fig = hview_fig;
            panelHandles.hview_ax = hview_ax;
            set(hp_subMode.modeview,'BackgroundColor',[0.14,0.64,0.14])%set to default color
        else
            fpos0 = get(hf_main,'Position');
            set(hf_main,'position',[fpos0(1) fpos0(2) fpos(3) fpos(4)])
            set(hp_subMode.modeview,'BackgroundColor',[0.94,0.94,0.94])%set to default color
%             delete(hview_fig)
        end
    end

%% Add a listener for the value change of position
addlistener(hp_subZ.h_positionEdt, 'String', 'PostSet', @upDateDisToBreg);
addlistener(hp_subX.h_positionEdt, 'String', 'PostSet', @upDateDisToBreg);
addlistener(hp_subY.h_positionEdt, 'String', 'PostSet', @upDateDisToBreg);

    function upDateDisToBreg(varargin)
        if isBregmaOn
            dis2BragZ = num2str(str2double(get(hp_subZ.h_positionEdt,'string')) - bregmaZ,6);
            set(hview_curDemInfZ,'String',dis2BragZ)
            
            dis2BragX = num2str(str2double(get(hp_subX.h_positionEdt,'string')) - bregmaX,6);
            set(hview_curDemInfX,'String',dis2BragX)
            
            dis2BragY = num2str(str2double(get(hp_subY.h_positionEdt,'string')) - bregmaY,6);
            set(hview_curDemInfY,'String',dis2BragY)
        end
    end

    function autoZLim(varargin)
        isAutozlim = get(h_zAutoBtn,'value');
        if isAutozlim
            if mode == 2
                limMotionZ = [-1 1];
            else
                limMotionZ = [-max(motionGrid(:,3))*1.1 -min(motionGrid(:,3))*0.9];
            end
            set(hview_ax,'zLim',limMotionZ)
            set(h_zAutoBtn,'BackgroundColor',[0.14,0.64,0.14])
        else
            if mode == 2
                limMotionZ = [-1 1];
            else
                limMotionZ = [-max(motionGrid(:,3))*1.1 0];
            end
           
            set(hview_ax,'zLim',limMotionZ)
            set(h_zAutoBtn,'BackgroundColor',[0.94,0.94,0.94])
        end
    end

    function zoomcallback(varargin)
        if get(h_zoombtn,'value')
            set(h_rotbtn,'value',false)
            set(h_rotbtn,'BackgroundColor',[0.94,0.94,0.94])
            
            rotate3d off;zoom on;
            set(h_zoombtn,'BackgroundColor',[0.14,0.64,0.14])
            
        else
            zoom out;zoom off;
            set(h_zoombtn,'BackgroundColor',[0.94,0.94,0.94])
        end
    end

    function rotatecallback(varargin)
        if get(h_rotbtn,'value')
            set(h_zoombtn,'value',false)
            set(h_zoombtn,'BackgroundColor',[0.94,0.94,0.94])
            
            rotate3d on;zoom off;
            set(h_rotbtn,'BackgroundColor',[0.14,0.64,0.14])
        else
            rotate3d off;
            view(AZ,EL)
            set(h_rotbtn,'BackgroundColor',[0.94,0.94,0.94])
        end
    end

    function topviewcallback(varargin)
        
        if get(h_topviewBtn,'value')
            view(0,90);
            set(h_topviewBtn,'BackgroundColor',[0.14,0.64,0.14])
            
            set(h_sideviewBtn,'value',false)
            set(h_sideviewBtn,'BackgroundColor',[0.94,0.94,0.94])
            
        else
            view(AZ,EL)
            set(h_topviewBtn,'BackgroundColor',[0.94,0.94,0.94])
        end
        
    end

    function sideviewcallback(varargin)
        
        if get(h_sideviewBtn,'value')
            view(0,0);
            set(h_sideviewBtn,'BackgroundColor',[0.14,0.64,0.14])
            
            set(h_topviewBtn,'value',false)
            set(h_topviewBtn,'BackgroundColor',[0.94,0.94,0.94])
        else
            view(AZ,EL)
            set(h_sideviewBtn,'BackgroundColor',[0.94,0.94,0.94])
        end
        
    end

    function saveLog(varargin)
        currClock = fix(clock);
        logFileName = [ipath,num2str(currClock(1)),num2str(currClock(2)),...
            num2str(currClock(3)),num2str(currClock(4)),...
            num2str(currClock(5)),num2str(currClock(6)),'.txt'];
        logData = get(hview_log,'String');
        fileID = fopen(logFileName,'w');
        fprintf(fileID,'%s',logData');
        fclose(fileID);
        
    end


%% Add a listener for the value change of mode
addlistener(hp_subMode.needleEdt, 'String', 'PostSet', @modeViewUpdate);
addlistener(hp_subMode.holeDiameterEdt, 'String', 'PostSet', @modeViewUpdate);

    function modeViewUpdate(varargin)
        
        sampleFactor = str2double(get(hp_subMode.needleEdt,'String'));
        holeDia = str2double(get(hp_subMode.holeDiameterEdt,'String')); %% Unit:mm
        holeDia_hf = holeDia/2;
        sampleStep=Ndl_ID/sampleFactor;
        sampleNum=fix(holeDia_hf/sampleStep)*2;
        sampleStep = holeDia/sampleNum;
        %         motionGrid = gridGenerator(sampleNum,sampleStep,mode);
        motionGrid = stepGenerator(sampleNum,sampleStep,mode,stepMatrix,orient,holeDepth);
        
        if isAutozlim
            limMotionZ = [-max(motionGrid(:,3))*1.1 -min(motionGrid(:,3))*0.9];
        else
            limMotionZ = [-max(motionGrid(:,3))*1.1 0];
        end
        
        switch mode
            case 1
                limMotionX = [-1.1*(holeDia/2) 1.1*(holeDia/2)];
                limMotionY = [-1.1*(holeDia/2) 1.1*(holeDia/2)];
            case 2
                limMotionX = [-1.1*(holeDia/2) 1.1*(holeDia/2)];
                limMotionY = [-1.1*(holeDia/2) 1.1*(holeDia/2)];
                limMotionZ = [-1 1];
            case 3
                limMotionX = [-max(abs(motionGrid(:,1))) max(abs(motionGrid(:,1)))];
                limMotionY = [-max(abs(motionGrid(:,2))) max(abs(motionGrid(:,2)))];
            case 4
                limMotionX = [-max(abs(motionGrid(:,1))) max(abs(motionGrid(:,1)))];
                limMotionY = [-max(abs(motionGrid(:,2))) max(abs(motionGrid(:,2)))];
        end
        
        if isModeViewOpen
            cla(hview_ax)
            plot3(hview_ax,motionGrid(:,1),motionGrid(:,2),-motionGrid(:,3),'o--','color',[0.15 0.15 0.15])
            set(hview_ax,'xLim',limMotionX,'yLim',limMotionY,'zLim',limMotionZ,'XGrid','on','YGrid','on','ZGrid','on')
        end
        
    end


%% Start
    function startSurg(varargin)
        isStop = false;
        if isFirstTime
            isFirstTime = false;
            if (~isZeroSet)||(~iszStepSet)
                h_msg = msgbox('Please click KeepZero button first!');
                WinOnTop(h_msg, true);
                return;
            end
        end
        
        if ~isPause
            set(hp_subControl.start,'String','Pause')
            set(hview_statusInfoE,'String','Started!')
            isPause = true;
            
            if pausePositionX ~= currentPositionX
                currentPositionX = moveToPosition(pausePositionX, stepperHandleX, hp_subX, encoderHandle,0, useEncoderX);
            end
            if pausePositionY ~= currentPositionY
                currentPositionY = moveToPosition(pausePositionY, stepperHandleY, hp_subY, encoderHandle,1, useEncoderY);
            end
            if pausePositionZ ~= currentPositionZ
                currentPositionZ = moveToPosition(pausePositionZ, stepperHandleZ, hp_subZ, encoderHandle,2, useEncoderZ);
            end
            
            mStatus = startMotion(surgIdx, motionGrid, stepperHandles, panelHandles);
            
            switch mStatus
                case 0
                    set(hview_statusInfoE,'String','Finished!')
                    set(hp_subControl.start,'String','Start')
                    surgIdx = 1;
                    isPause = false;
                    backZero();
                    modeViewUpdate();
                    
                    set(hview_statusInfoS,'ForegroundColor','k')
                    iszStepSet = false;
                    set(hzstep_confirm,'BackgroundColor',[0.94,0.94,0.94])
                case 1
                    set(hview_statusInfoE,'String','Paused!')
            end           
        else
            isPause = false;
            set(hp_subControl.start,'String','Resume')
            set(hview_statusInfoE,'String','Paused!')
        end
    end

    function stopSurg(varargin)
        isStop = true;
        isPause = false;
        surgIdx = 1;
        java.lang.Thread.sleep(2);
        set(hp_subControl.start,'String','Start')
        set(hview_statusInfoE,'String','Stoped!')
        modeViewUpdate();
        backZero();
        set(hview_statusInfoS,'ForegroundColor','k')
        iszStepSet = false;
        set(hzstep_confirm,'BackgroundColor',[0.94,0.94,0.94])
        
    end

%% z step setting
iszStepSet = false;
hf_zStep = uipanel('Parent',hf_main,...
    'FontSize',12,...
    'BackgroundColor','white',...
    'unit','pix',...
    'Title', 'zStep',...
    'Position',[side side+offset+70 200 panelHeight+130]);

panelHandles.hf_zStep = hf_zStep;

hzstep_chk = zeros(5,1);
hzstep_edt = zeros(5,1);
hzstep_time = zeros(5,1);

for s = 1:5
    
    hzstep_chk(s) = uicontrol('Parent',hf_zStep,...
        'Style','checkbox',...
        'unit','pixel',...
        'BackgroundColor','white',...
        'Position',[10 (1-s)*40+210 45 30],...
        'FontSize',12,...
        'value',stepMatrix(s,1),...
        'String',num2str(s));

    hzstep_edt(s) = uicontrol('Parent',hf_zStep,...
        'Style','edit',...
        'unit','pixel',...
        'BackgroundColor','white',...
        'Position',[60 (1-s)*40+210 75 30],...
        'FontSize',12,...
        'String',num2str(stepMatrix(s,2)));
    
    hzstep_time(s) = uicontrol('Parent',hf_zStep,...
        'Style','edit',...
        'unit','pixel',...
        'BackgroundColor','white',...
        'Position',[150 (1-s)*40+210 40 30],...
        'FontSize',12,...
        'String',num2str(stepMatrix(s,3)));
    
end

% 
hzstep_confirm = uicontrol('Parent',hf_zStep,...
    'Style','push',...
    'unit','pixel',...
    'Position',[20 10 70 30],...
    'FontSize',12,...
    'String','NotSet',...
    'Callback',@stepConfirm);
uicontrol('Parent',hf_zStep,...
    'Style','push',...
    'unit','pixel',...
    'Position',[110 10 70 30],...
    'FontSize',12,...
    'String','Reset',...
    'Callback',@resetStepValue);

    function stepConfirm(varargin)
        
        for ss=1:5
            stepCheck(ss) = get(hzstep_chk(ss),'value');
            stepValue(ss) = str2double(get(hzstep_edt(ss),'String'));
            stepTime(ss) = str2double(get(hzstep_time(ss),'String'));
        end
        
        if stepCheck(1)
            stepMatrix = [stepCheck,stepValue,stepTime];
            set(hzstep_confirm,'string','Set')
            iszStepSet = true;
            set(hview_statusInfoS,'ForegroundColor','r')
            if isZeroSet
                set(hview_statusInfoE,'String','Ready')
                set(hview_statusInfoE,'ForegroundColor','r')
                holeDepth = sum(stepCheck.*stepValue.*stepTime) - zeroZ + bregmaZ;
                set(hview_holeDepth,'String',num2str(holeDepth));
            end
            
            set(hzstep_confirm,'BackgroundColor',[0.14,0.64,0.14])
        else
            h_msg = msgbox('Please at lease input one step!');
            WinOnTop(h_msg, true)
        end
       
        modeViewUpdate();
    end

    function resetStepValue(varargin)
        for ss= 1:5
            set(hzstep_chk(ss),'value',iStepMatrix(ss,1));
            set(hzstep_edt(ss),'String',num2str(iStepMatrix(ss,2)));
            set(hzstep_time(ss),'String',num2str(iStepMatrix(ss,3)));
        end
        stepConfirm();
    end

%% This section is for direct insertion of the grin lenses

hf_dirIn = uipanel('Parent',hf_main,...
    'FontSize',12,...
    'BackgroundColor','white',...
    'unit','pix',...
    'Title', 'Direct',...
    'Position',[side side+offset 200 panelHeight/2]);

hdirIn_edt1 = uicontrol('Parent',hf_dirIn,...
    'Style','edit',...
    'unit','pixel',...
    'BackgroundColor','white',...
    'Position',[5 10 45 30],...
    'FontSize',12,...
    'String','1.00');

hdirIn_edt2 = uicontrol('Parent',hf_dirIn,...
    'Style','edit',...
    'unit','pixel',...
    'BackgroundColor','white',...
    'Position',[55 10 45 30],...
    'FontSize',12,...
    'String','0.10');

uicontrol('Parent',hf_dirIn,...
    'Style','push',...
    'unit','pixel',...
    'Position',[110 10 40 30],...
    'FontSize',12,...
    'String','ST',...
    'Callback',@instart,...
    'Enable','inactive');

uicontrol('Parent',hf_dirIn,...
    'Style','push',...
    'unit','pixel',...
    'Position',[155 10 40 30],...
    'FontSize',12,...
    'String','SP',...
    'Callback',@instop,...
    'Enable','inactive');

InDepth = fix(str2double(get(hdirIn_edt1,'String'))*unitStep);%unit: mm
InStep = fix((str2double(get(hdirIn_edt2,'String'))/60)*unitStep); %unit: mm


addlistener(hdirIn_edt1, 'String', 'PostSet', @depthUpdate);
addlistener(hdirIn_edt2, 'String', 'PostSet', @stepUpdate);

inStop = false;
% inStart = true;

nextPositionZ = bregmaPositionZ;
tPosition = bregmaPositionZ - InDepth;

tDelay = 1000;

    function instart(varargin)
        
        nextPositionZ = bregmaPositionZ;
        currentPositionZ = moveToPosition(nextPositionZ, stepperHandleZ, hp_subZ, encoderHandle,2, useEncoderZ);
        
        while ~inStop
            
            currentPositionZ = moveToPosition(nextPositionZ, stepperHandleZ, hp_subZ, encoderHandle,2, useEncoderZ);
            java.lang.Thread.sleep(tDelay);
            
            nextPositionZ = currentPositionZ - InStep;
            
            if nextPositionZ < tPosition
                
                nextPositionZ = tPosition; inStop = true;
                currentPositionZ = moveToPosition(nextPositionZ, stepperHandleZ, hp_subZ, encoderHandle,2, useEncoderZ);
                java.lang.Thread.sleep(tDelay);
                
            end

        end
        
    end

    function instop(varargin)
        
        inStop = true;
        java.lang.Thread.sleep(tDelay/4);
        currentPositionZ = moveToPosition(bregmaPositionZ, stepperHandleZ, hp_subZ, encoderHandle,2, useEncoderZ);
        
    end

    function depthUpdate(varargin)
        
        InDepth = str2double(get(hdirIn_edt1,'String'));%unit: mm
        tPosition = bregmaPositionZ - InDepth;
        
    end

    function stepUpdate(varargin)
        
        InStep = str2double(get(hdirIn_edt2,'String'))/60;%unit: mm
        
    end

hintInfo1 = '<html>Depth Relative to Bragma in mm <br> Not work yet';
set(hdirIn_edt1, 'tooltip',hintInfo1);

hintInfo2 = '<html> mm per min  <br> Not work yet';
set(hdirIn_edt2, 'tooltip',hintInfo2);

%% Position Finder


% hintpfinder = '<html>Use Click me to input the coordinates relative to Bregma.';
% set(hp_pfinder, 'tooltip',hintpfinder);

hf_pFinder = uipanel('Parent',hf_main,...
    'FontSize',12,...
    'BackgroundColor','white',...
    'unit','pix',...
    'Title', 'pFinder',...
    'Position',[side+220 side+offset 200 panelHeight+50]);



uicontrol('Parent',hf_pFinder,...
    'Style','text',...
    'unit','pixel',...
    'BackgroundColor','white',...
    'Position',[10 45 65 30],...
    'FontSize',12,...
    'String',' Input Z:');

hp_zInputEdt = uicontrol('Parent',hf_pFinder,...
    'Style','edit',...
    'unit','pixel',...
    'Position',[90 45 100 30],...
    'FontSize',12,...
    'String',num2str(surgPos(1)));
uicontrol('Parent',hf_pFinder,...
    'Style','text',...
    'unit','pixel',...
    'BackgroundColor','white',...
    'Position',[10 80 65 30],...
    'FontSize',12,...
    'String',' Input Y:');

hp_yInputEdt = uicontrol('Parent',hf_pFinder,...
    'Style','edit',...
    'unit','pixel',...
    'Position',[90 80 100 30],...
    'FontSize',12,...
    'String',num2str(surgPos(2)));
uicontrol('Parent',hf_pFinder,...
    'Style','text',...
    'unit','pixel',...
    'BackgroundColor','white',...
    'Position',[10 115 65 30],...
    'FontSize',12,...
    'String',' Input X:');

hp_xInputEdt = uicontrol('Parent',hf_pFinder,...
    'Style','edit',...
    'unit','pixel',...
    'Position',[90 115 100 30],...
    'FontSize',12,...
    'String',num2str(surgPos(3)));

uicontrol('Parent',hf_pFinder,...
    'Style','push',...
    'unit','pixel',...
    'Position',[10 10 80 25],...
    'FontSize',12,...
    'String','Find',...
    'Callback',@pFinderGo);

hp_pfinderBregma = uicontrol('Parent',hf_pFinder,...
    'Style','push',...
    'unit','pixel',...
    'Position',[100 10 90 25],...
    'FontSize',12,...
    'String','Bregma',...
    'Callback',@Bregma);


    function Bregma(varargin)
        if ~isBregmaOn
            bregmaPositionX = currentPositionX;
            bregmaPositionY = currentPositionY;
            bregmaPositionZ = currentPositionZ;
            
            set(hp_pfinderBregma,'BackgroundColor',[0.14,0.64,0.14])%set to green color
            set(hp_pfinderBregma,'String','BackBreg')
            bregmaX = str2double(get(hp_subX.h_positionEdt,'string'));
            bregmaY = str2double(get(hp_subY.h_positionEdt,'string'));
            bregmaZ = str2double(get(hp_subZ.h_positionEdt,'string'));
            
            bregmaPos = [' [X]  ',get(hp_subX.h_positionEdt,'string'),...
                ';  [Y]  ',get(hp_subY.h_positionEdt,'string'),...
                ';  [Z]  ',get(hp_subZ.h_positionEdt,'string'),...
                ';'];
            set(hview_bregInfoE,'String',bregmaPos)
            set(hview_curDemInfX,'String','0.0000')
            set(hview_curDemInfY,'String','0.0000')
            set(hview_curDemInfZ,'String','0.0000')
            set(hview_statusInfoB,'ForegroundColor','r')
        else
            if abs(bregmaPositionX - currentPositionX) > tolPulseNum
                currentPositionX = moveToPosition(bregmaPositionX, stepperHandleX, hp_subX, encoderHandle,0, useEncoderX);
                
            end
            if abs(bregmaPositionY - currentPositionY) > tolPulseNum
                currentPositionY = moveToPosition(bregmaPositionY, stepperHandleY, hp_subY, encoderHandle,1, useEncoderY);
            end
            
            if abs(bregmaPositionZ - currentPositionZ) > tolPulseNum
                currentPositionZ = moveToPosition(bregmaPositionZ, stepperHandleZ, hp_subZ, encoderHandle,2, useEncoderZ);
            end
            
            set(hp_pfinderBregma,'BackgroundColor',[0.94,0.94,0.94])%set to default color
            set(hp_pfinderBregma,'String','Bregma')
            set(hview_statusInfoB,'ForegroundColor','k')
        end
        isBregmaOn = ~isBregmaOn;
    end

    function pFinderGo(varargin)
        if isBregmaOn
            targetPositionX = bregmaPositionX + fix(str2double(get(hp_xInputEdt,'string'))*unitStep);
            targetPositionY = bregmaPositionY + fix(str2double(get(hp_yInputEdt,'string'))*unitStep);
            targetPositionZ = bregmaPositionZ + fix(str2double(get(hp_zInputEdt,'string'))*unitStep);
            
            % Move z -axis first, Let the needle go up
            currentPositionZ = moveToPosition(targetPositionZ, stepperHandleZ, hp_subZ, encoderHandle,2, useEncoderZ);
            % And there move the xy positions
            currentPositionX = moveToPosition(targetPositionX, stepperHandleX, hp_subX, encoderHandle,0, useEncoderX);
            currentPositionY = moveToPosition(targetPositionY, stepperHandleY, hp_subY, encoderHandle,1, useEncoderY);
            
        else
            h_msg = msgbox('Please Click Bregma First!');
            WinOnTop(h_msg, true);
        end
    end

%% Information
hp_info = uicontrol('Parent',hf_main,...
    'Style','text',...
    'FontSize',8,...
    'Unit','pix',...
    'Backgroundcolor',get(hf_main,'color'),...
    'String','- © By Bo Liang (bo.liang2@nih.gov), Lin Lab(da-ting.lin@nih.gov), IRP/NIDA/NIH - ',...
    'Position',[0 10 figWidth 20]);

hintInfo = '<html>Have A Problem? <br> Email Me for Support.';
set(hp_info, 'tooltip',hintInfo);

%% INITIATE ALL STEPPER MOTOR
if isopenX % x Axis done
    activeSignal(hp_subX.h_active,'ready')
end

if isopenY
    activeSignal(hp_subY.h_active,'ready')
end

if isopenZ
    activeSignal(hp_subZ.h_active,'ready')
end

    function activeSignal(handle,type)
        switch type
            case 'ready'
                set(handle,'BackgroundColor','green')
            case 'active'
                set(handle,'BackgroundColor','red')
            otherwise
                % do nothing
        end
    end
%% close request
    function closeFigRequest(varargin)
        % Close request function
        % to display a question dialog box
        
        if ishandle(hf_main)
            WinOnTop(hf_main,false);
        end
        
        selection = questdlg('Quit?',...
            'Close Request',...
            'Yes','No','Yes');
        switch selection
            case 'Yes'
                % get the postion value
                initData(1,6) = str2double(get(hp_subX.h_positionEdt,'String'));
                initData(2,6) = str2double(get(hp_subY.h_positionEdt,'String'));
                initData(3,6) = str2double(get(hp_subZ.h_positionEdt,'String'));
                
                % get the Velocity limit value
                initData(1,1) = str2double(get(hp_subX.h_veloLimEdt,'String'));
                initData(2,1) = str2double(get(hp_subY.h_veloLimEdt,'String'));
                initData(3,1) = str2double(get(hp_subZ.h_veloLimEdt,'String'));
                
                % get the Acceleration limit value
                initData(1,2) = str2double(get(hp_subX.h_acceEdt,'String'));
                initData(2,2) = str2double(get(hp_subY.h_acceEdt,'String'));
                initData(3,2) = str2double(get(hp_subZ.h_acceEdt,'String'));
                
                % get the Current limit value
                initData(1,3) = str2double(get(hp_subX.h_currLimEdt,'String'));
                initData(2,3) = str2double(get(hp_subY.h_currLimEdt,'String'));
                initData(3,3) = str2double(get(hp_subZ.h_currLimEdt,'String'));
                
                % get the Current limit value
                initData(1,5) = str2double(get(hp_subX.h_stepEdt,'String'));
                initData(2,5) = str2double(get(hp_subY.h_stepEdt,'String'));
                initData(3,5) = str2double(get(hp_subZ.h_stepEdt,'String'));
                
                % get the encoder status value
                initData(4,2) = get(hp_subX.h_encoder,'value');
                initData(4,3) = get(hp_subY.h_encoder,'value');
                initData(4,4) = get(hp_subZ.h_encoder,'value');
                
                save(ifile1,'initData', '-ascii')
                
                surgPos(1) = str2double(get(hp_zInputEdt,'String'));
                surgPos(2) = str2double(get(hp_yInputEdt,'String'));
                surgPos(3) = str2double(get(hp_xInputEdt,'String'));
                stepMatrixplus = [stepMatrix;surgPos];
                save(ifile2,'stepMatrixplus', '-ascii')
                
                % Save all the parameter
                delete(hf_main)
                if ishandle(hf_pFinder)
                    delete(hf_pFinder)
                end
                if ishandle(hview_fig)
                    delete(hview_fig)
                end
                if ishandle(hf_zStep)
                    delete(hf_zStep)
                end
                
                phidgetClose(stepperHandleX);
                phidgetClose(stepperHandleY);
                phidgetClose(stepperHandleZ);
                phidgetClose(encoderHandle);
            case 'No'
                return
        end
    end
end