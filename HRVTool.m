function HRVTool
%Syntax: HRVTool
%  
% Analyzing Heart Rate Variability
% Licensed under MIT.
% Copyright (c) 2015 Marcus Vollmer (http://marcusvollmer.github.io/HRV/)
%
% Icons licensed under MIT.
% Copyright (c) 2014 Drifty (http://drifty.com/)
%
% Version: 0.98
% Author: Marcus Vollmer
% Date: 30 March 2017

F.fh = figure('Visible','off','Position',[0,0,1280,900],'PaperPositionMode','auto','DeleteFcn',@my_closereq);
set(gcf,'Units','inches'); screenposition = get(gcf,'Position');
set(gcf,'PaperPosition',[0 0 screenposition(3:4)],'PaperSize',screenposition(3:4));

global icons qrs_settings AppPath

%Add path for Matlab App user
   files = matlab.apputil.getInstalledAppInfo;
   AppPath = files(strcmp({files.name},'HRVTool')).location;
   if exist([AppPath filesep 'HRVTool.m'],'file')~=2
       if exist([AppPath filesep 'code' filesep 'HRVTool.m'],'file')==2
           AppPath = [AppPath filesep 'code'];
       elseif  exist([AppPath filesep 'HRVTool' filesep 'HRVTool.m'],'file')==2
           AppPath = [AppPath filesep 'HRVTool'];
       end
   end
   
% % Add path for Matlab source code user
%    AppPath = cd;

addpath(genpath(AppPath))

load('icons.mat')
load('qrs_settings.mat')

%Panels
F.hpSubject    = uipanel('Title','','BackgroundColor',1*[1 1 1],'Position',[0 .975 1 .025],'BorderType','none','Units','normalized','FontUnits','normalized','visible','on');
F.hpIntervals  = uipanel('Title','','BackgroundColor',.8*[1 1 1],'Position',[0 .75 1 .225],'BorderType','none','Units','normalized','FontUnits','normalized','visible','on');
F.hpResults    = uipanel('Title','','BackgroundColor',[.7 1 1],'Position',[.025 .25 .3 .475],'BorderType','none','Units','normalized','FontUnits','normalized','visible','on');
F.hpLocalReturnMap = uipanel('Title','','BackgroundColor',.9*[1 1 1],'Position',[.35 .25 .35 .475],'BorderType','none','Units','normalized','FontUnits','normalized','visible','on');
F.hpSpectrum   = uipanel('Title','','BackgroundColor',.9*[1 1 1],'Position',[.725 .25 .275 .475],'BorderType','none','Units','normalized','FontUnits','normalized','visible','on');
F.hpContinuous = uipanel('Title','','BackgroundColor',.8*[1 1 1],'Position',[0 .025 1 .2],'BorderType','none','Units','normalized','FontUnits','normalized','visible','on');
F.hpFootline   = uipanel('Title','','BackgroundColor',1*[1 1 1],'Position',[0 0 1 .025],'BorderType','none','Units','normalized','FontUnits','normalized','visible','on');

%Text
F.htextFilter=uicontrol('Parent',F.hpIntervals,'Style','text',...
    'String','Filter',...
    'FontSize',9,'Units','normalized','Position',[.9 .425 .075 .1],...
    'FontUnits','normalized','HorizontalAlignment','center',...
    'BackgroundColor',.8*[1 1 1]);
F.htextAuthor=uicontrol('Parent',F.hpFootline,'Style','text',...
    'String','',...
    'FontSize',10,'Units','normalized','Position',[.55 0 .4 .95],...
    'FontUnits','normalized','HorizontalAlignment','right',...
    'FontAngle','italic','BackgroundColor',1*[1 1 1]);
F.htextBusy=uicontrol('Parent',F.hpFootline,'Style','text',...
    'String','','ForegroundColor',[1 1 1],...
    'FontSize',10,'Units','normalized','Position',[.05 0 .45 .95],...
    'FontUnits','normalized','HorizontalAlignment','left',...
    'BackgroundColor',0*[1 1 1]);

bgcolor_results = [.7 1 1];
bgcolor_highlight = [1 .7 .7];

label_column = .05;
global_column = .35;
local_column = .55;
footprint_column = .75;
column_width = .2;
label_column_width = .275;


F.htextHeadline=uicontrol('Parent',F.hpResults,'Style','text',...
    'String','HRV measures','FontWeight','bold',...
    'FontSize',14,'Units','normalized','Position',[.05 .925 .5 .05],...
    'FontUnits','normalized','HorizontalAlignment','left',...
    'BackgroundColor',bgcolor_results);
F.htextGlobal=uicontrol('Parent',F.hpResults,'Style','text',...
    'String','global','FontWeight','bold',...
    'FontSize',11,'Units','normalized','Position',[global_column .85 column_width .05],...
    'FontUnits','normalized','HorizontalAlignment','center',...
    'BackgroundColor',bgcolor_results);
F.htextLocal=uicontrol('Parent',F.hpResults,'Style','text',...
    'String','local','FontWeight','bold',...
    'FontSize',11,'Units','normalized','Position',[local_column .85 column_width .05],...
    'FontUnits','normalized','HorizontalAlignment','center',...
    'BackgroundColor',bgcolor_results);
F.htextFootprint=uicontrol('Parent',F.hpResults,'Style','text',...
    'String','footprint','FontWeight','bold',...
    'FontSize',11,'Units','normalized','Position',[footprint_column .85 column_width .05],...
    'FontUnits','normalized','HorizontalAlignment','center',...
    'BackgroundColor',bgcolor_results,'visible','off');
F.htextLocal_range=uicontrol('Parent',F.hpResults,'Style','text',...
    'String','','FontAngle','italic',...
    'FontSize',8,'Units','normalized','Position',[local_column .9 column_width .03],...
    'FontUnits','normalized','HorizontalAlignment','center',...
    'BackgroundColor',bgcolor_results);
F.htextLocal_label=uicontrol('Parent',F.hpResults,'Style','text',...
    'String','','FontAngle','italic',...
    'FontSize',8,'Units','normalized','Position',[local_column .93 column_width .03],...
    'FontUnits','normalized','HorizontalAlignment','center',...
    'BackgroundColor',bgcolor_results);
F.htextFootprint_range=uicontrol('Parent',F.hpResults,'Style','text',...
    'String','','FontAngle','italic',...
    'FontSize',8,'Units','normalized','Position',[footprint_column .9 column_width .03],...
    'FontUnits','normalized','HorizontalAlignment','center',...
    'BackgroundColor',bgcolor_results);
F.htextFootprint_label=uicontrol('Parent',F.hpResults,'Style','text',...
    'String','','FontAngle','italic',...
    'FontSize',8,'Units','normalized','Position',[footprint_column .93 column_width .03],...
    'FontUnits','normalized','HorizontalAlignment','center',...
    'BackgroundColor',bgcolor_results);



F.htextLabel_rrHRV_median=uicontrol('Parent',F.hpResults,'Style','text',...
    'String','median',...
    'FontSize',10,'Units','normalized','Position',[label_column .775 label_column_width .05],...
    'FontUnits','normalized','HorizontalAlignment','right',...
    'BackgroundColor',bgcolor_highlight);
F.htextLabel_rrHRV_iqr=uicontrol('Parent',F.hpResults,'Style','text',...
    'String','IQR',...
    'FontSize',10,'Units','normalized','Position',[label_column .725 label_column_width .05],...
    'FontUnits','normalized','HorizontalAlignment','right',...
    'BackgroundColor',bgcolor_highlight);
F.htextLabel_rrHRV_shift=uicontrol('Parent',F.hpResults,'Style','text',...
    'String','shift',...
    'FontSize',10,'Units','normalized','Position',[label_column .675 label_column_width .05],...
    'FontUnits','normalized','HorizontalAlignment','right',...
    'BackgroundColor',bgcolor_highlight);
F.htextLabel_rrHRV=uicontrol('Parent',F.hpResults,'Style','text',...
    'String','rrHRV','FontWeight','bold',...
    'FontSize',10,'Units','normalized','Position',[label_column .775 label_column_width/2 .05],...
    'FontUnits','normalized','HorizontalAlignment','right',...
    'BackgroundColor',bgcolor_highlight);

F.htextLabel_meanrr=uicontrol('Parent',F.hpResults,'Style','text',...
    'String','Mean RR | HR',...
    'FontSize',10,'Units','normalized','Position',[label_column .6 label_column_width .05],...
    'FontUnits','normalized','HorizontalAlignment','right',...
    'TooltipString','unit: ms | bpm',...
    'BackgroundColor',bgcolor_results);
F.htextLabel_sdnn=uicontrol('Parent',F.hpResults,'Style','text',...
    'String','SDNN',...
    'FontSize',10,'Units','normalized','Position',[label_column .55 label_column_width .05],...
    'FontUnits','normalized','HorizontalAlignment','right',...
    'TooltipString','unit: ms',...
    'BackgroundColor',bgcolor_results);
F.htextLabel_rmssd=uicontrol('Parent',F.hpResults,'Style','text',...
    'String','RMSSD',...
    'FontSize',10,'Units','normalized','Position',[label_column .5 label_column_width .05],...
    'FontUnits','normalized','HorizontalAlignment','right',...
    'TooltipString','unit: ms',...
    'BackgroundColor',bgcolor_results);
F.htextLabel_pnn50=uicontrol('Parent',F.hpResults,'Style','text',...
    'String','pNN50',...
    'FontSize',10,'Units','normalized','Position',[label_column .45 label_column_width .05],...
    'FontUnits','normalized','HorizontalAlignment','right',...
    'TooltipString','unit: %',...
    'BackgroundColor',bgcolor_results);
F.htextLabel_tri=uicontrol('Parent',F.hpResults,'Style','text',...
    'String','TRI',...
    'FontSize',10,'Units','normalized','Position',[label_column .4 label_column_width .05],...
    'FontUnits','normalized','HorizontalAlignment','right',...
    'BackgroundColor',bgcolor_results);
F.htextLabel_tinn=uicontrol('Parent',F.hpResults,'Style','text',...
    'String','TINN',...
    'FontSize',10,'Units','normalized','Position',[label_column .35 label_column_width .05],...
    'FontUnits','normalized','HorizontalAlignment','right',...
    'TooltipString','unit: ms',...
    'BackgroundColor',bgcolor_results);
F.htextLabel_sd1sd2=uicontrol('Parent',F.hpResults,'Style','text',...
    'String','SD1 | SD2',...
    'FontSize',10,'Units','normalized','Position',[label_column .3 label_column_width .05],...
    'FontUnits','normalized','HorizontalAlignment','right',...
    'TooltipString','units: ms',...
    'BackgroundColor',bgcolor_results);
F.htextLabel_sd1sd2ratio=uicontrol('Parent',F.hpResults,'Style','text',...
    'String','SD1/SD2 ratio',...
    'FontSize',10,'Units','normalized','Position',[label_column .25 label_column_width .05],...
    'FontUnits','normalized','HorizontalAlignment','right',...
    'BackgroundColor',bgcolor_results);
F.htextLabel_lfhf=uicontrol('Parent',F.hpResults,'Style','text',...
    'String','LF | HF',...
    'FontSize',10,'Units','normalized','Position',[label_column .2 label_column_width .05],...
    'FontUnits','normalized','HorizontalAlignment','right',...
    'TooltipString','normalized units: %',...
    'BackgroundColor',bgcolor_results);
F.htextLabel_lfhfratio=uicontrol('Parent',F.hpResults,'Style','text',...
    'String','LF/HF ratio',...
    'FontSize',10,'Units','normalized','Position',[label_column .15 label_column_width .05],...
    'FontUnits','normalized','HorizontalAlignment','right',...
    'BackgroundColor',bgcolor_results);

F.htextGlobal_rrHRV_median  =uicontrol('Parent',F.hpResults,'Style','text','String','','FontSize',10,'Units','normalized','Position',[global_column .775 column_width .05],'FontUnits','normalized','HorizontalAlignment','center','BackgroundColor',bgcolor_highlight);
F.htextGlobal_rrHRV_iqr     =uicontrol('Parent',F.hpResults,'Style','text','String','','FontSize',10,'Units','normalized','Position',[global_column .725 column_width .05],'FontUnits','normalized','HorizontalAlignment','center','BackgroundColor',bgcolor_highlight);
F.htextGlobal_rrHRV_shift   =uicontrol('Parent',F.hpResults,'Style','text','String','','FontSize',9,'Units','normalized','Position',[global_column .675 column_width .05],'FontUnits','normalized','HorizontalAlignment','center','BackgroundColor',bgcolor_highlight);
F.htextGlobal_meanrr        =uicontrol('Parent',F.hpResults,'Style','text','String','','FontSize',10,'Units','normalized','Position',[global_column .6 column_width .05],'FontUnits','normalized','HorizontalAlignment','center','BackgroundColor',bgcolor_results);
F.htextGlobal_sdnn          =uicontrol('Parent',F.hpResults,'Style','text','String','','FontSize',10,'Units','normalized','Position',[global_column .55 column_width .05],'FontUnits','normalized','HorizontalAlignment','center','BackgroundColor',bgcolor_results);
F.htextGlobal_rmssd         =uicontrol('Parent',F.hpResults,'Style','text','String','','FontSize',10,'Units','normalized','Position',[global_column .5 column_width .05],'FontUnits','normalized','HorizontalAlignment','center','BackgroundColor',bgcolor_results);
F.htextGlobal_pnn50         =uicontrol('Parent',F.hpResults,'Style','text','String','','FontSize',10,'Units','normalized','Position',[global_column .45 column_width .05],'FontUnits','normalized','HorizontalAlignment','center','BackgroundColor',bgcolor_results);
F.htextGlobal_tri           =uicontrol('Parent',F.hpResults,'Style','text','String','','FontSize',10,'Units','normalized','Position',[global_column .4 column_width .05],'FontUnits','normalized','HorizontalAlignment','center','BackgroundColor',bgcolor_results);
F.htextGlobal_tinn          =uicontrol('Parent',F.hpResults,'Style','text','String','','FontSize',10,'Units','normalized','Position',[global_column .35 column_width .05],'FontUnits','normalized','HorizontalAlignment','center','BackgroundColor',bgcolor_results);
F.htextGlobal_sd1sd2        =uicontrol('Parent',F.hpResults,'Style','text','String','','FontSize',9,'Units','normalized','Position',[global_column .3 column_width .05],'FontUnits','normalized','HorizontalAlignment','center','BackgroundColor',bgcolor_results);
F.htextGlobal_sd1sd2ratio   =uicontrol('Parent',F.hpResults,'Style','text','String','','FontSize',10,'Units','normalized','Position',[global_column .25 column_width .05],'FontUnits','normalized','HorizontalAlignment','center','BackgroundColor',bgcolor_results);
F.htextGlobal_lfhf          =uicontrol('Parent',F.hpResults,'Style','text','String','','FontSize',9,'Units','normalized','Position',[global_column .2 column_width .05],'FontUnits','normalized','HorizontalAlignment','center','BackgroundColor',bgcolor_results);
F.htextGlobal_lfhfratio     =uicontrol('Parent',F.hpResults,'Style','text','String','','FontSize',10,'Units','normalized','Position',[global_column .15 column_width .05],'FontUnits','normalized','HorizontalAlignment','center','BackgroundColor',bgcolor_results);

F.htextLocal_rrHRV_median  =uicontrol('Parent',F.hpResults,'Style','text','String','','FontSize',10,'Units','normalized','Position',[local_column .775 column_width .05],'FontUnits','normalized','HorizontalAlignment','center','BackgroundColor',bgcolor_highlight);
F.htextLocal_rrHRV_iqr     =uicontrol('Parent',F.hpResults,'Style','text','String','','FontSize',10,'Units','normalized','Position',[local_column .725 column_width .05],'FontUnits','normalized','HorizontalAlignment','center','BackgroundColor',bgcolor_highlight);
F.htextLocal_rrHRV_shift   =uicontrol('Parent',F.hpResults,'Style','text','String','','FontSize',9,'Units','normalized','Position',[local_column .675 column_width .05],'FontUnits','normalized','HorizontalAlignment','center','BackgroundColor',bgcolor_highlight);
F.htextLocal_meanrr        =uicontrol('Parent',F.hpResults,'Style','text','String','','FontSize',10,'Units','normalized','Position',[local_column .6 column_width .05],'FontUnits','normalized','HorizontalAlignment','center','BackgroundColor',bgcolor_results);
F.htextLocal_sdnn          =uicontrol('Parent',F.hpResults,'Style','text','String','','FontSize',10,'Units','normalized','Position',[local_column .55 column_width .05],'FontUnits','normalized','HorizontalAlignment','center','BackgroundColor',bgcolor_results);
F.htextLocal_rmssd         =uicontrol('Parent',F.hpResults,'Style','text','String','','FontSize',10,'Units','normalized','Position',[local_column .5 column_width .05],'FontUnits','normalized','HorizontalAlignment','center','BackgroundColor',bgcolor_results);
F.htextLocal_pnn50         =uicontrol('Parent',F.hpResults,'Style','text','String','','FontSize',10,'Units','normalized','Position',[local_column .45 column_width .05],'FontUnits','normalized','HorizontalAlignment','center','BackgroundColor',bgcolor_results);
F.htextLocal_tri           =uicontrol('Parent',F.hpResults,'Style','text','String','','FontSize',10,'Units','normalized','Position',[local_column .4 column_width .05],'FontUnits','normalized','HorizontalAlignment','center','BackgroundColor',bgcolor_results);
F.htextLocal_tinn          =uicontrol('Parent',F.hpResults,'Style','text','String','','FontSize',10,'Units','normalized','Position',[local_column .35 column_width .05],'FontUnits','normalized','HorizontalAlignment','center','BackgroundColor',bgcolor_results);
F.htextLocal_sd1sd2        =uicontrol('Parent',F.hpResults,'Style','text','String','','FontSize',9,'Units','normalized','Position',[local_column .3 column_width .05],'FontUnits','normalized','HorizontalAlignment','center','BackgroundColor',bgcolor_results);
F.htextLocal_sd1sd2ratio   =uicontrol('Parent',F.hpResults,'Style','text','String','','FontSize',10,'Units','normalized','Position',[local_column .25 column_width .05],'FontUnits','normalized','HorizontalAlignment','center','BackgroundColor',bgcolor_results);
F.htextLocal_lfhf          =uicontrol('Parent',F.hpResults,'Style','text','String','','FontSize',9,'Units','normalized','Position',[local_column .2 column_width .05],'FontUnits','normalized','HorizontalAlignment','center','BackgroundColor',bgcolor_results);
F.htextLocal_lfhfratio     =uicontrol('Parent',F.hpResults,'Style','text','String','','FontSize',10,'Units','normalized','Position',[local_column .15 column_width .05],'FontUnits','normalized','HorizontalAlignment','center','BackgroundColor',bgcolor_results);

F.htextFootprint_rrHRV_median  =uicontrol('Parent',F.hpResults,'Style','text','String','','FontSize',10,'Units','normalized','Position',[footprint_column .775 column_width .05],'FontUnits','normalized','HorizontalAlignment','center','BackgroundColor',bgcolor_highlight,'visible','off');
F.htextFootprint_rrHRV_iqr     =uicontrol('Parent',F.hpResults,'Style','text','String','','FontSize',10,'Units','normalized','Position',[footprint_column .725 column_width .05],'FontUnits','normalized','HorizontalAlignment','center','BackgroundColor',bgcolor_highlight,'visible','off');
F.htextFootprint_rrHRV_shift   =uicontrol('Parent',F.hpResults,'Style','text','String','','FontSize',9,'Units','normalized','Position',[footprint_column .675 column_width .05],'FontUnits','normalized','HorizontalAlignment','center','BackgroundColor',bgcolor_highlight,'visible','off');
F.htextFootprint_meanrr        =uicontrol('Parent',F.hpResults,'Style','text','String','','FontSize',10,'Units','normalized','Position',[footprint_column .6 column_width .05],'FontUnits','normalized','HorizontalAlignment','center','BackgroundColor',bgcolor_results);
F.htextFootprint_sdnn          =uicontrol('Parent',F.hpResults,'Style','text','String','','FontSize',10,'Units','normalized','Position',[footprint_column .55 column_width .05],'FontUnits','normalized','HorizontalAlignment','center','BackgroundColor',bgcolor_results);
F.htextFootprint_rmssd         =uicontrol('Parent',F.hpResults,'Style','text','String','','FontSize',10,'Units','normalized','Position',[footprint_column .5 column_width .05],'FontUnits','normalized','HorizontalAlignment','center','BackgroundColor',bgcolor_results);
F.htextFootprint_pnn50         =uicontrol('Parent',F.hpResults,'Style','text','String','','FontSize',10,'Units','normalized','Position',[footprint_column .45 column_width .05],'FontUnits','normalized','HorizontalAlignment','center','BackgroundColor',bgcolor_results);
F.htextFootprint_tri           =uicontrol('Parent',F.hpResults,'Style','text','String','','FontSize',10,'Units','normalized','Position',[footprint_column .4 column_width .05],'FontUnits','normalized','HorizontalAlignment','center','BackgroundColor',bgcolor_results);
F.htextFootprint_tinn          =uicontrol('Parent',F.hpResults,'Style','text','String','','FontSize',10,'Units','normalized','Position',[footprint_column .35 column_width .05],'FontUnits','normalized','HorizontalAlignment','center','BackgroundColor',bgcolor_results);
F.htextFootprint_sd1sd2        =uicontrol('Parent',F.hpResults,'Style','text','String','','FontSize',9,'Units','normalized','Position',[footprint_column .3 column_width .05],'FontUnits','normalized','HorizontalAlignment','center','BackgroundColor',bgcolor_results);
F.htextFootprint_sd1sd2ratio   =uicontrol('Parent',F.hpResults,'Style','text','String','','FontSize',10,'Units','normalized','Position',[footprint_column .25 column_width .05],'FontUnits','normalized','HorizontalAlignment','center','BackgroundColor',bgcolor_results);
F.htextFootprint_lfhf          =uicontrol('Parent',F.hpResults,'Style','text','String','','FontSize',9,'Units','normalized','Position',[footprint_column .2 column_width .05],'FontUnits','normalized','HorizontalAlignment','center','BackgroundColor',bgcolor_results);
F.htextFootprint_lfhfratio     =uicontrol('Parent',F.hpResults,'Style','text','String','','FontSize',10,'Units','normalized','Position',[footprint_column .15 column_width .05],'FontUnits','normalized','HorizontalAlignment','center','BackgroundColor',bgcolor_results);



%Edit fields
F.heditFolder = uicontrol('Parent',F.hpSubject,'Style','edit',...
    'Units','normalized','Position',[.1 0 .1 1],'FontUnits','normalized',...
    'Tag','Folder','String',[AppPath filesep 'data'],'TooltipString','edit the source folder',...
    'Callback',@editFolder_Callback,'visible','off');
F.heditLimits = uicontrol('Parent',F.hpIntervals,'Style','edit',...
    'Units','normalized','Position',[.725 .81 .1 .1],'FontUnits','normalized',...
    'String','0:10','TooltipString','edit the limits',...
    'Callback',@editLimits_Callback);  
F.heditLabel = uicontrol('Parent',F.hpIntervals,'Style','edit',...
    'Units','normalized','Position',[.655 .81 .065 .1],'FontUnits','normalized',...
    'String','','TooltipString','set up the a label for this particular time window',...
    'Callback',@editLabel_Callback);  
F.heditFilter = uicontrol('Parent',F.hpIntervals,'Style','edit',...
    'Units','normalized','Position',[.925 .35 .025 .1],'FontUnits','normalized',...
    'String','20','TooltipString','the parameter for automated filtering',...
    'Callback',@editFilter_Callback);  
F.heditSpeed = uicontrol('Parent',F.hpLocalReturnMap,'Style','edit',...
    'Units','normalized','Position',[.95 .95 .05 .05],'FontUnits','normalized',...
    'String','1','TooltipString','set up the speed factor for your animation (1 is real time, 2 is double speed)',...
    'Callback',@editSpeed_Callback); 
F.heditMeasuresNum = uicontrol('Parent',F.hpContinuous,'Style','edit',...
    'Units','normalized','Position',[.05 .81 .025 .1],'FontUnits','normalized',...
    'String','60','TooltipString','the number of successive beats for which the HRV parameter will be estimated',...
    'Callback',@editMeasuresNum_Callback);  
F.heditOverlap = uicontrol('Parent',F.hpContinuous,'Style','edit',...
    'Units','normalized','Position',[.075 .81 .025 .1],'FontUnits','normalized',...
    'String','0.75','TooltipString','the overlap parameter',...
    'Callback',@editOverlap_Callback);  

%Popup
F.hpopupSubject = uicontrol('Parent',F.hpSubject,'Style','popup',...
    'Units','normalized','Position',[0 0 .15 1],'FontUnits','normalized',...
    'Tag','Subject','String','','Callback',@popupSubject_Callback);  

%Buttons
F.hbuttonFolder = uicontrol('Parent',F.hpSubject,'String','cd',...
    'FontSize',9,'Units','normalized','Position',[0.075 0 .025 1],...
    'TooltipString','Change directory',...
    'FontUnits','normalized','Callback', @buttonCD_Callback,'visible','off');
F.hbuttonFontChange = uicontrol('Parent',F.hpSubject,'String','font change',...
    'FontSize',9,'Units','normalized','Position',[0 0 .075 1],...
    'TooltipString','Font selection',...
    'FontUnits','normalized','Callback', @buttonFontChange_Callback,'visible','off');
F.hbuttonTitle = uicontrol('Parent',F.hpSubject,'String','T',...
    'FontSize',9,'Units','normalized','Position',[.3 0 .015 1],...
    'FontUnits','normalized','TooltipString','Change title',...
    'Callback', @buttonTitle_Callback,'visible','off');

F.hbuttonIntervalNext2 = uicontrol('Parent',F.hpIntervals,'String','',...
    'FontSize',12,'Units','normalized','Position',[.85 .81 .025 .1],...
    'TooltipString','Move forward','CData',[icons.android_arrow_forward(:,4:12,:) icons.android_arrow_forward(:,5:13,:)],...
    'FontUnits','normalized','Callback', @buttonIntervalNext2_Callback);
F.hbuttonIntervalNext = uicontrol('Parent',F.hpIntervals,'String','',...
    'FontSize',12,'Units','normalized','Position',[.825 .81 .025 .1],...
    'TooltipString','Move forward','CData',icons.android_arrow_forward,...
    'FontUnits','normalized','Callback', @buttonIntervalNext_Callback);
F.hbuttonIntervalPrevious = uicontrol('Parent',F.hpIntervals,'String','',...
    'FontSize',12,'Units','normalized','Position',[.075 .81 .025 .1],...
    'TooltipString','Move backwards','CData',icons.android_arrow_back,...
    'FontUnits','normalized','Callback', @buttonIntervalPrevious_Callback);
F.hbuttonIntervalPrevious2 = uicontrol('Parent',F.hpIntervals,'String','',...
    'FontSize',12,'Units','normalized','Position',[.05 .81 .025 .1],...
    'TooltipString','Move backwards','CData',[icons.android_arrow_back(:,4:12,:) icons.android_arrow_back(:,5:13,:)],...
    'FontUnits','normalized','Callback', @buttonIntervalPrevious2_Callback);
F.hbuttonShowWaveform = uicontrol('Parent',F.hpIntervals,'String','Waveform',...
    'FontSize',9,'Units','normalized','Position',[.9 .8 .075 .1],'visible','off',...
    'FontUnits','normalized','Callback', @buttonShowWaveform_Callback);
F.hbuttonShowIntervals = uicontrol('Parent',F.hpIntervals,'String','Intervals',...
    'FontSize',9,'Units','normalized','Position',[.9 .7 .075 .1],...
    'FontUnits','normalized','Callback', @buttonShowIntervals_Callback);
F.hbuttonShowProportions = uicontrol('Parent',F.hpIntervals,'String','Proportions',...
    'FontSize',9,'Units','normalized','Position',[.9 .6 .075 .1],...
    'FontUnits','normalized','Callback', @buttonShowProportions_Callback);
F.hbuttonFilterDecrease = uicontrol('Parent',F.hpIntervals,'String','',...
    'FontSize',12,'Units','normalized','Position',[.9 .35 .025 .1],...
    'TooltipString','More artifact filtering','CData',icons.minus_round,...
    'FontUnits','normalized','Callback', @buttonFilterDecrease_Callback);
F.hbuttonFilterIncrease = uicontrol('Parent',F.hpIntervals,'String','',...
    'FontSize',12,'Units','normalized','Position',[.95 .35 .025 .1],...
    'TooltipString','Less artifact filtering','CData',icons.plus_round,...
    'FontUnits','normalized','Callback', @buttonFilterIncrease_Callback);
F.hbuttonRemoveArtifact = uicontrol('Parent',F.hpIntervals,'String','Remove artifact',...
    'FontSize',9,'Units','normalized','Position',[.9 .2 .075 .1],...
    'FontUnits','normalized','TooltipString','select multiple beats and confirm with a double click',...
    'Callback', @buttonRemoveArtifact_Callback);
F.hbuttonRemoveArtifact2 = uicontrol('Parent',F.hpContinuous,'String','',...
    'FontSize',12,'Units','normalized','Position',[.9575 .81 .0175 .1],...
    'TooltipString','Remove artifact','CData',icons.ios7_close,...
    'FontUnits','normalized','Callback', @buttonRemoveArtifact2_Callback);
F.hbuttonPicker = uicontrol('Parent',F.hpContinuous,'String','',...
    'FontSize',12,'Units','normalized','Position',[.94 .81 .0175 .1],...
    'FontUnits','normalized','TooltipString','Show corresponding intervals','CData',icons.pin,...
    'Callback', @buttonPicker_Callback);


F.hbuttonReturnMapType = uicontrol('Parent',F.hpLocalReturnMap,'String','RR<>rr',...
    'FontSize',9,'Units','normalized','Position',[0 .95 .125 .05],...
    'FontUnits','normalized','TooltipString','Switch absolute/relative view',...
    'Callback', @buttonReturnMapType_Callback);
F.hbuttonNumbers = uicontrol('Parent',F.hpLocalReturnMap,'String','',...
    'FontSize',9,'Units','normalized','Position',[.125 .95 .05 .05],...
    'FontUnits','normalized','TooltipString','Show coordinate numbers','CData',icons.ios7_information,...
    'Callback', @buttonNumbers_Callback);
F.hbuttonFootprint = uicontrol('Parent',F.hpLocalReturnMap,'String','',...
    'FontSize',9,'Units','normalized','Position',[.175 .95 .05 .05],'CData',icons.ios7_paw,...
    'FontUnits','normalized','Callback', @buttonFootprint_Callback);
F.hbuttonPDF = uicontrol('Parent',F.hpLocalReturnMap,'String','',...
    'FontSize',9,'Units','normalized','Position',[.225 .95 .05 .05],'CData',icons.android_image,...
    'FontUnits','normalized','TooltipString','Show probablity density function of rrHRV',...
    'Callback', @buttonPDF_Callback);
F.hbuttonAnimation = uicontrol('Parent',F.hpLocalReturnMap,'String','',...
    'FontSize',9,'Units','normalized','Position',[.9 .95 .05 .05],'CData',icons.social_youtube,...
    'FontUnits','normalized','TooltipString','Show animation of beat variation',...
    'Callback', @buttonAnimation_Callback);
F.hbuttonMarkerIncrease = uicontrol('Parent',F.hpLocalReturnMap,'String','',...
    'FontSize',9,'Units','normalized','Position',[.275 .95 .05 .05],...
    'FontUnits','normalized','TooltipString','Increase marker size','CData',icons.plus_circled,...
    'Callback', @buttonMarkerIncrease_Callback);
F.hbuttonMarkerDecrease = uicontrol('Parent',F.hpLocalReturnMap,'String','',...
    'FontSize',9,'Units','normalized','Position',[.325 .95 .05 .05],...
    'FontUnits','normalized','TooltipString','Decrease marker size','CData',icons.minus_circled,...
    'Callback', @buttonMarkerDecrease_Callback);
F.hbuttonLineType = uicontrol('Parent',F.hpLocalReturnMap,'String','',...
    'FontSize',9,'Units','normalized','Position',[.375 .95 .05 .05],...
    'FontUnits','normalized','TooltipString','Change line type','CData',icons.android_more,...
    'Callback', @buttonLineType_Callback);
F.hbuttonDetail = uicontrol('Parent',F.hpLocalReturnMap,'String','',...
    'FontSize',9,'Units','normalized','Position',[.425 .95 .05 .05],...
    'FontUnits','normalized','TooltipString','Resize','CData',icons.arrow_resize,...
    'Callback', @buttonDetail_Callback);


F.hbuttonTachogramType = uicontrol('Parent',F.hpSpectrum,'String','global<>local',...
    'FontSize',9,'Units','normalized','Position',[0 .95 .25 .05],...
    'FontUnits','normalized','TooltipString','Change local/global tachogram analysis',...
    'Callback', @buttonTachogramType_Callback);


F.hbuttonContinuousVisibility = uicontrol('Parent',F.hpContinuous,'String','visibility on/off',...
    'FontSize',9,'Units','normalized','Position',[.675 .81 .075 .1],...
    'FontUnits','normalized','TooltipString','Change visibility of continuous HRV paramater',...
    'Callback', @buttonContinuousVisibility_Callback);
F.hbuttonContinuousLFHF = uicontrol('Parent',F.hpContinuous,'String','LFHF',...
    'FontSize',9,'Units','normalized','Position',[.615 .81 .03 .1],...
    'FontUnits','normalized','TooltipString','Compute LF/HF ratio',...
    'Callback', @buttonContinuousLFHF_Callback);
F.hbuttonContinuousTINN = uicontrol('Parent',F.hpContinuous,'String','TINN',...
    'FontSize',9,'Units','normalized','Position',[.645 .81 .03 .1],...
    'FontUnits','normalized','TooltipString','Compute TINN',...
    'Callback', @buttonContinuousTINN_Callback);
F.hbuttonContinuousRecalculation = uicontrol('Parent',F.hpContinuous,...
    'String','Recalculation','FontSize',12,...
    'Units','normalized','Position',[.3 .4 .1 .15],'FontUnits','normalized',...
    'Callback', @editMeasuresNum_Callback,'visible','off');
F.hbuttonPickerSection = uicontrol('Parent',F.hpContinuous,'String','',...
    'FontSize',12,'Units','normalized','Position',[.1 .81 .02 .1],...
    'FontUnits','normalized','TooltipString','Show section','CData',icons.pin,...
    'Callback', @buttonPickerSection_Callback);

F.hbuttonSaveAs = uicontrol('Parent',F.hpResults,'String','save as',...
    'FontSize',9,'Units','normalized','Position',[.85 0 .15 .05],...
    'FontUnits','normalized','TooltipString','save as png, pdf, csv or mat-file',...
    'Callback', @buttonSaveAs_Callback,'visible','off');
F.hbuttonCopy = uicontrol('Parent',F.hpResults,'String','copy',...
    'FontSize',9,'Units','normalized','Position',[.7 0 .15 .05],...
    'FontUnits','normalized','TooltipString','copy to clipboard',...
    'Callback', @buttonCopy_Callback,'visible','off');



%Axes
F.ha1 = axes('Parent',F.hpIntervals,'Position',[.05 .15 .825 .65],...
    'Units','normalized','FontUnits','normalized','Layer','top','visible','off'); 
F.ha2 = axes('Parent',F.hpLocalReturnMap,'Position',[.15 .125 .8 .725],...
    'Units','normalized','FontUnits','normalized','Layer','top','visible','on'); 
F.ha2b = axes('Parent',F.hpLocalReturnMap,'Position',[.025 .025 .4 .15],...
    'Units','normalized','FontUnits','normalized','visible','off'); 
F.ha3 = axes('Parent',F.hpSpectrum,'Position',[.15 .65 .8 .25],...
    'Units','normalized','FontUnits','normalized','Layer','top','visible','on'); 
F.ha4 = axes('Parent',F.hpSpectrum,'Position',[.15 .125 .8 .35],...
    'Units','normalized','FontUnits','normalized','Layer','top','visible','on'); 
F.ha5 = axes('Parent',F.hpContinuous,'Position',[.05 .15 .7 .65],...
    'Units','normalized','FontUnits','normalized','Layer','top','visible','on'); 
F.ha6 = axes('Parent',F.hpContinuous,'Position',[.8 .15 .175 .65],...
    'Units','normalized','FontUnits','normalized','Layer','top','visible','on'); 


% Initialize the GUI.
set(F.fh,'Name','Analysis of Heart Rate Variability')
movegui(F.fh,'center')
set(F.fh,'Visible','on');


% Global Variables
global always LocalRange FootprintRange HRVTool_version HRVTool_version_date Position font_set my_title;
global sig sig_waveform unit name name_org Fs Ann;
global d_fs Beat_min Beat_max wl_tma wl_we;
global RR RRorg RRfilt center relRR relRR_pct RR_loc rr_loc;
global showWaveform showIntervals showProportions RMtype RMnumbers showFootprint showPDF RMmarkersize;
global filter_limit my_artifacts;
global signal_num MeasuresNum HfNum Overlap legendpos hAx hLine1 hLine2 vis showTINN showLFHF;
global HRV_rr_med HRV_rr_iqr HRV_rr_shift HRV_hf HRV_rmssd HRV_sdnn...
    HRV_sdsd HRV_pnn50 HRV_tri HRV_tinn HRV_sd1sd2ratio HRV_lfhfratio;
global HRV_global_rrHRV_median HRV_global_rrHRV_iqr HRV_global_rrHRV_shift HRV_global_meanrr HRV_global_sdnn HRV_global_rmssd HRV_global_pnn50 HRV_global_tri HRV_global_tinn HRV_global_sd1 HRV_global_sd2 HRV_global_sd1sd2ratio HRV_global_lf HRV_global_hf HRV_global_lfhfratio;
global HRV_local_rrHRV_median HRV_local_rrHRV_iqr HRV_local_rrHRV_shift HRV_local_meanrr HRV_local_sdnn HRV_local_rmssd HRV_local_pnn50 HRV_local_tri HRV_local_tinn HRV_local_sd1 HRV_local_sd2 HRV_local_sd1sd2ratio HRV_local_lf HRV_local_hf HRV_local_lfhfratio;
global HRV_footprint_rrHRV_median HRV_footprint_rrHRV_iqr HRV_footprint_rrHRV_shift HRV_footprint_meanrr HRV_footprint_sdnn HRV_footprint_rmssd HRV_footprint_pnn50 HRV_footprint_tri HRV_footprint_tinn HRV_footprint_sd1 HRV_footprint_sd2 HRV_footprint_sd1sd2ratio HRV_footprint_lf HRV_footprint_hf HRV_footprint_lfhfratio;
global speed fp_RR fp_rr;
global S;
global FileName PathName;
global label_lim label_names;

HRVTool_version = 0.98;
HRVTool_version_date = '30 March 2017';
Position = [0,0,40/3,75/8];
set(F.htextAuthor,'String',['HRVTool ' num2str(HRVTool_version,'%1.2f') ' | marcus.vollmer@uni-greifswald.de'])

speed = 1;
fp_RR = []; fp_rr = [];
S = [];
my_title = {''};
showWaveform = false;
showIntervals = false;
showProportions = false;
showFootprint = false;
showPDF = false;
RMtype = false;
RMnumbers = false;
RMmarkersize = 12.5;
RMlinetype = 0;
RMzoomlevel = 1;
Tachogramtype = false;
showTINN = false;
showLFHF = false;
vis = true(1,7);
filter_limit = 20;
MeasuresNum = 60;
HfNum = MeasuresNum;
Overlap = .75;
always = false;

my_artifacts = [];
label_lim =[];
label_names = {};

if exist([cd filesep 'font_setting.mat'],'file')>0
    load('font_setting.mat')
    names = fieldnames(F);
    for i=2:length(names)
        set(F.(names{i}),font_set);
    end
end


%Toolbar
F.fh.MenuBar = 'figure';  % Display the standard toolbar
F.htoolbar = findall(F.fh,'tag','FigureToolBar');
% get(findall(F.htoolbar),'tag') % Tags of standard toolbar

tb_exclusion = {'Standard.NewFigure','Standard.EditPlot','Exploration.Rotate',...
    'Plottools.PlottoolsOn','Plottools.PlottoolsOff','Annotation.InsertLegend',...
    'Annotation.InsertColorbar','DataManager.Linking'};
for i=1:length(tb_exclusion)
    set(findall(F.htoolbar,'tag',tb_exclusion{i}),'visible','off','Separator','off');
end
set(findall(F.htoolbar,'tag','Standard.FileOpen'),'ClickedCallback',@buttonCD_Callback,'CData',icons.android_folder);
set(findall(F.htoolbar,'tag','Standard.SaveFigure'),'ClickedCallback',@save_settings,'TooltipString','Save settings','CData',icons.archive);
set(findall(F.htoolbar,'tag','Standard.PrintFigure'),'CData',icons.android_printer);
set(findall(F.htoolbar,'tag','Exploration.ZoomIn'),'CData',icons.android_search_plus);
set(findall(F.htoolbar,'tag','Exploration.ZoomOut'),'CData',icons.android_search_minus);
set(findall(F.htoolbar,'tag','Exploration.Pan'),'CData',icons.android_hand);
set(findall(F.htoolbar,'tag','Exploration.DataCursor'),'CData',icons.android_locate);
set(findall(F.htoolbar,'tag','Exploration.Brushing'),'CData',icons.wand);

F.htoolbarCopy = uitoggletool(F.htoolbar,'CData',icons.clipboard,...
            'Separator','on','TooltipString','Copy to clipboard','Tag','HRV.Copy',...
            'HandleVisibility','off','ClickedCallback',@buttonCopy_Callback);
F.htoolbarFont = uitoggletool(F.htoolbar,'CData',icons.android_mixer,...
            'Separator','on','TooltipString','Font selection','Tag','HRV.Font',...
            'HandleVisibility','off','ClickedCallback',@buttonFontChange_Callback);
F.htoolbarTitle = uitoggletool(F.htoolbar,'CData',icons.android_promotion,...
            'Separator','on','TooltipString','Change title','Tag','HRV.Title',...
            'HandleVisibility','off','ClickedCallback',@buttonTitle_Callback);
        
%Menubar
F.hmenu = findall(F.fh,'tag','figMenu');
% get(findall(F.fh,'type','uimenu'),'tag')
 
menu_exclusion = {'figMenuWindow','figMenuDesktop','figMenuTools',...
    'figMenuInsert','figMenuView','figMenuEdit','figMenuHelp',...
    'figMenuFileExportSetup','figMenuFilePreferences',...
    'figMenuFileSaveWorkspaceAs','figMenuUpdateFileNew',...
    'figMenuFileImportData','figMenuGenerateCode'};
for i=1:length(menu_exclusion)
    set(findall(F.fh,'tag',menu_exclusion{i}),'visible','off','Separator','off');
end

%     'figMenuFileExitMatlab'
%     'figMenuFilePrintPreview'
%     'figMenuFileClose'     

F.hmenuFile = findall(F.fh,'tag','figMenuFile');
% F.hmenuOpen = uimenu(F.hmenuFile,'Label','Open','Position',3);

F.hmenuSaveAs  = findall(F.hmenuFile,'tag','figMenuFileSaveAs');
set(F.hmenuSaveAs,'Callback',@buttonSaveAs_Callback);
F.hmenuSave  = findall(F.hmenuFile,'tag','figMenuFileSave');
set(F.hmenuSave,'Callback',@save_settings);

F.hmenuCopy = uimenu(F.hmenuFile,'Label','Copy to clipboard','Callback',@buttonCopy_Callback,'Accelerator','C','Position',5);


F.hmenuHelp = uimenu(F.fh,'Label','&Help');
F.hmenuTutorial = uimenu(F.hmenuHelp,'Label','Go to tutorial','Callback',@MenuTutorial);
F.hmenuWebManual = uimenu(F.hmenuHelp,'Label','Get help on website','Callback',@MenuWebsite,'Accelerator','H');
F.hmenuTerms = uimenu(F.hmenuHelp,'Label','Terms of use','Callback',@MenuTerms);
F.hmenuInfo = uimenu(F.hmenuHelp,'Label','Info','Callback',@MenuInfo,'Accelerator','I','Separator','on');

% F.hmenueh1 = uimenu(F.hmenu,'Label','Item 1');
% F.hmenueh2 = uimenu(F.hmenu,'Label','Item 2','Checked','on');
% F.hmenuseh1 = uimenu(F.hmenueh1,'Label','Choice 1','Accelerator','C','Enable','off');
% F.hmenuseh2 = uimenu(F.hmenueh1,'Label','Choice 2','Accelerator','H');
% 



if exist([AppPath filesep 'HRV_settings.m'],'file')<=0
    create_HRV_settings
end
if exist([AppPath filesep 'HRV_settings.m'],'file')>0    
    HRV_settings
    
    set(F.heditFolder,'String',PathName);
    fileextention = FileName(max(strfind(FileName,'.'))+1:end);
    subjects = dir([PathName filesep '*.' fileextention]);
    set(F.hpopupSubject,'String',{subjects.name});
    set(F.hpopupSubject,'Value',find(ismember(get(F.hpopupSubject,'String'),FileName)));
    set(F.fh,'Position',Position)
    
    buttonStart_Callback    
end


%% Button start and main function
function buttonStart_Callback(hObject, eventdata, handles)  
    calc_on
    
    VAL = get(F.hpopupSubject,'Value');
    STR = get(F.hpopupSubject,'String');
    
    FileName = STR{VAL};
    fileextention = FileName(max(strfind(FileName,'.'))+1:end);
    
    delete(get(F.ha1,'Children'));  
    delete(get(F.ha2,'Children'));  
    delete(get(F.ha2b,'Children'));  
    delete(get(F.ha3,'Children'));  
    delete(get(F.ha4,'Children'));  
    delete(get(F.ha5,'Children'));  
    delete(get(F.ha6,'Children'));
    my_title = {''};
    my_artifacts = [];
    label_lim =[];
    label_names = {};
    S = [];
    fp_RR = [];
    fp_rr = [];
    showFootprint = false;
    showTINN = false; set(F.hbuttonContinuousTINN,'visible','on');
    showLFHF = false; set(F.hbuttonContinuousLFHF,'visible','on');
    showWaveform = false; set(F.hbuttonShowWaveform,'visible','off');
    set(F.hbuttonContinuousRecalculation,'visible','off');
    set(F.heditLabel,'String','')
    set(F.heditLimits,'String','0:10')
    StartDelay = 0;
    name =  {FileName};
    
    drawnow
    switch lower(fileextention)
        case 'hrm'
            fileID = fopen([get(F.heditFolder,'String') FileName],'r');
            dataArray = textscan(fileID,'%s%s%[^\n\r]',50,'Delimiter','=','ReturnOnError',false);
            fclose(fileID);
            infos = table(dataArray{1:end-1}, 'VariableNames', {'attribute','val'}); clearvars dataArray;
            StartDate = datetime([infos.val{strcmp(infos.attribute,'Date')} ' ' infos.val{strcmp(infos.attribute,'StartTime')}],'InputFormat','yyyyMMdd HH:mm:ss.S');
            StartDelay = str2double(infos.val{strcmp(infos.attribute,'StartDelay')});

            fileID = fopen([get(F.heditFolder,'String') FileName],'r');
            rawData = textscan(fileID,'%s%[^\n\r]');    
            fclose(fileID);

            rawData = rawData{1};
            rawData = rawData(find(ismember(rawData,'[HRData]'))+1:end);
            RR = cellfun(@str2double, rawData);

            pos = find(RR==3999);
            for i=1:length(pos)
                RR(pos(i)+1) = RR(pos(i)+1)+RR(pos(i));
                RR(pos(i):end-1) = RR(pos(i)+1:end);                
                pos = pos-1;
            end
            RR = RR(1:end-length(pos));
            
            Ann = round(cumsum([StartDelay;RR]));
            RR(RR>4000) = NaN;
            Fs = 1000;
            
            sig = zeros(max(Ann)+1,1);
            sig(Ann+1,1)=1;
            unit = {'Impulse'};
            

        case 'ecg'
            if ~isempty(which('rdann'))
                old_path = cd;
                cd(get(F.heditFolder,'String'))
                Ann = rdann(FileName(1:end-4),'ecg');

                fileID = fopen([get(F.heditFolder,'String') FileName(1:end-4) '.hea'],'r');
                dataArray = textscan(fileID,'%s%s%s%[^\n\r]',1,'Delimiter',' ','ReturnOnError',false);
                Fs = str2double(dataArray{3});
                dataArray = textscan(fileID,'%s%[^\n\r]',1,'ReturnOnError',false);
                name = {[name{1} dataArray{2}]};
                fclose(fileID); clearvars  dataArray;

                cd(old_path) 

                RR = diff(Ann);
                sig = zeros(max(Ann)+1,1);
                sig(Ann+1,1)=1; 
                unit = {'Impulse'}; 
            end
            
            
        case 'mat'
            matObj = matfile([get(F.heditFolder,'String') FileName(1:end-4) '.mat']);
            fn = fieldnames(matObj);
            data_name = [];
            
            % filter fieldnames with numeric type
            for i=1:size(fn,1)
                fn_num(i) = isnumeric(matObj.(fn{i}));
            end
            switch sum(fn_num)
                case 0
                    warndlg('There is no numeric data inside the mat-file.')
                case 1
                    data_name = fn{fn_num};
                    
                otherwise
                    str = fn(fn_num);
                    [s,v] = listdlg('PromptString','Select a file:',...
                        'SelectionMode','single','ListString',str);
                    if v>0
                        data_name = str{s};
                    end
            end
            Ann = [];
            RR = [];
            
            if ~isempty(data_name)
                prompt = {'Enter type of data (waveform (w), RR intervals (RR), Annotations (Ann)):',...
                'Enter sampling frequency (Hz):'};
                dlg_title = 'Input';
                num_lines = 1;
                def = {'RR intervals','1000'};
                answer = inputdlg(prompt,dlg_title,num_lines,def);
                Fs = str2double(answer{2});

                switch answer{1}
                    case {'waveform','w'}
                        button = questdlg('Do you want to load an annotation file?','Annotation file','Yes','No - Start heart beat detection','No - Start heart beat detection');
                        if strcmp(button,'Yes')                            
                            load_annotation
                            sig_waveform = matObj.(data_name);
                            unit = {'Impulse'};
                            set(F.htextBusy,'String','Busy - Loading annotation file.');
                            drawnow
                        else
                            s = listdlg('PromptString','Select the waveform type:','SelectionMode','single','ListString',qrs_settings.Name);
                            if isempty(s)
                                prompt = {'Beat_min (bpm):','Beat_max (bpm):',...
                                        'Window length for TMA-Filtering (sec):',...
                                        'Window length for Extrema (sec)','Downsampling factor (integer)'};
                                    dlg_title = 'Input';
                                    num_lines = 1;
                                    def = {'50','220','0.2','0.33','1'};
                                    answer = inputdlg(prompt,dlg_title,num_lines,def);

                                    Beat_min = str2double(answer{1});
                                    Beat_max = str2double(answer{2});
                                    wl_tma = ceil(str2double(answer{3})*Fs); 
                                    if isempty(strfind(answer{4},' '))
                                        wl_we = ceil(str2double(answer{4})*Fs);
                                    else
                                        pos = strfind(answer{4},' ');
                                        wl_we = [ceil(str2double(answer{4}(1:pos))*Fs) ceil(str2double(answer{4}(pos:end))*Fs)];
                                    end
                                    d_fs = Fs/str2double(answer{5});
                            else
                                Beat_min=qrs_settings.Beat_min(s);
                                Beat_max=qrs_settings.Beat_max(s);
                                wl_tma=ceil(qrs_settings.wl_tma(s)*Fs);
                                wl_we=ceil(qrs_settings.wl_we(s,:).*Fs);
                                if isempty(qrs_settings.d_fs(s)) || qrs_settings.d_fs(s)==0
                                    d_fs=Fs;  
                                else
                                    d_fs=qrs_settings.d_fs(s); 
                                end
                            end
                            
                            sig_waveform = matObj.(data_name);
                            unit = {'Impulse'};
                            set(F.htextBusy,'String','Busy - Beat annotations will be computed.');
                            drawnow
                            qrs_detection                            
                            
                        end
                        
                        q = HRV.nanquantile(sig_waveform',[.05 .5 .95]);
                        sig_waveform = (sig_waveform-q(2))/(4*(q(3)-q(1))) +.4;
                        set(F.htextBusy,'String','');
                        RR = diff(Ann);

                        sig = zeros(max(Ann)+1,1);
                        sig(Ann+1,1)=1; 
                        set(F.hbuttonShowWaveform,'visible','on');
                        
                    case {'RR intervals','rr','RR'}
                        RR = matObj.(data_name);
                        Ann = round(cumsum([0;RR]));
                        sig = zeros(max(Ann)+1,1);
                        sig(Ann+1,1)=1;        
                        unit = {'Impulse'};  
                        
                    case {'Annotation','Annotations','Ann','ann'}                        
                        Ann = matObj.(data_name);
                        RR = diff(Ann);
                        sig = zeros(max(Ann)+1,1);
                        sig(Ann+1,1)=1;        
                        unit = {'Impulse'};
                    otherwise
                        warndlg('This is not a valid type of data. Please specify whether it is a ''waveform'' or a sequence of ''RR intervals''.')
                end
            end 

        case 'wav'
            button = questdlg('Do you want to load an annotation file?','Annotation file','Yes','No - Start heart beat detection','No - Start heart beat detection');
            [sig_waveform, Fs] = audioread([get(F.heditFolder,'String') FileName]);
            unit = {'Impulse'};
                
            if strcmp(button,'Yes')                            
                load_annotation
                set(F.htextBusy,'String','Busy - Loading annotation file.');
                drawnow
            else
                s = listdlg('PromptString','Select the waveform type:','SelectionMode','single','ListString',qrs_settings.Name);
                if isempty(s)
                    prompt = {'Beat_min (bpm):','Beat_max (bpm):',...
                            'Window length for TMA-Filtering (sec):',...
                            'Window length for Extrema (sec)','Downsampling factor (integer)'};
                        dlg_title = 'Input';
                        num_lines = 1;
                        def = {'50','220','0.2','0.33','1'};
                        answer = inputdlg(prompt,dlg_title,num_lines,def);

                        Beat_min = str2double(answer{1});
                        Beat_max = str2double(answer{2});
                        wl_tma = ceil(str2double(answer{3})*Fs); 
                        if isempty(strfind(answer{4},' '))
                            wl_we = ceil(str2double(answer{4})*Fs);
                        else
                            pos = strfind(answer{4},' ');
                            wl_we = [ceil(str2double(answer{4}(1:pos))*Fs) ceil(str2double(answer{4}(pos:end))*Fs)];
                        end
                        d_fs = Fs/str2double(answer{5});
                else
                    Beat_min=qrs_settings.Beat_min(s);
                    Beat_max=qrs_settings.Beat_max(s);
                    wl_tma=ceil(qrs_settings.wl_tma(s)*Fs);
                    wl_we=ceil(qrs_settings.wl_we(s,:).*Fs);
                    if isempty(qrs_settings.d_fs(s)) || qrs_settings.d_fs(s)==0
                        d_fs=Fs;  
                    else
                        d_fs=qrs_settings.d_fs(s); 
                    end
                end

                set(F.htextBusy,'String','Busy - Beat annotations will be computed.');
                drawnow
                qrs_detection                            

            end

            q = HRV.nanquantile(sig_waveform',[.1 .5 .9]);
            sig_waveform = (sig_waveform-q(2))/(4*(q(3)-q(1))) +.4;
            set(F.htextBusy,'String','');
            RR = diff(Ann);

            sig = zeros(max(Ann)+1,1);
            sig(Ann+1,1)=1; 
            set(F.hbuttonShowWaveform,'visible','on');
            
            
        otherwise
            % Open dialog box to load waveform or RR intervals of ordinary
            % text files 
            prompt = {'Enter type of data (waveform (w), RR intervals (RR), Annotations (Ann)):',...
                'Enter sampling frequency (Hz):'};
            dlg_title = 'Input';
            num_lines = 1;
            def = {'RR intervals','1000'};
            answer = inputdlg(prompt,dlg_title,num_lines,def);
            Fs = str2double(answer{2});
            
            switch answer{1}
                case {'waveform','w'}
                    button = questdlg('Do you want to load an annotation file?','Annotation file','Yes','No - Start heart beat detection','No - Start heart beat detection');
                    if strcmp(button,'Yes')
                        set(F.htextBusy,'String','Busy - Loading waveform and annotation file.');
                        load_annotation                        
                        fileID = fopen([get(F.heditFolder,'String') FileName],'r');
                        dataArray = textscan(fileID,'%f%[^\n\r]','Delimiter','','EmptyValue',NaN,'ReturnOnError',false);
                        fclose(fileID);                        
                        sig_waveform = dataArray{:,1}; clearvars dataArray;
                        unit = {'Impulse'};                        
                        drawnow
                    else                        
                        s = listdlg('PromptString','Select the waveform type:','SelectionMode','single','ListString',qrs_settings.Name);
                        if isempty(s)
                            prompt = {'Beat_min (bpm):','Beat_max (bpm):',...
                                    'Window length for TMA-Filtering (sec):',...
                                    'Window length for Extrema (sec)','Downsampling factor (integer)'};
                                dlg_title = 'Input';
                                num_lines = 1;
                                def = {'50','220','0.2','0.33','1'};
                                answer = inputdlg(prompt,dlg_title,num_lines,def);

                                Beat_min = str2double(answer{1});
                                Beat_max = str2double(answer{2});
                                wl_tma = ceil(str2double(answer{3})*Fs); 
                                if isempty(strfind(answer{4},' '))
                                    wl_we = ceil(str2double(answer{4})*Fs);
                                else
                                    pos = strfind(answer{4},' ');
                                    wl_we = [ceil(str2double(answer{4}(1:pos))*Fs) ceil(str2double(answer{4}(pos:end))*Fs)];
                                end
                                d_fs = Fs/str2double(answer{5});
                        else
                            Beat_min=qrs_settings.Beat_min(s);
                            Beat_max=qrs_settings.Beat_max(s);
                            wl_tma=ceil(qrs_settings.wl_tma(s)*Fs);
                            wl_we=ceil(qrs_settings.wl_we(s,:).*Fs);
                            d_fs=Fs;                            
                        end  
                        
                        set(F.htextBusy,'String','Busy - Loading waveform.');
                        fileID = fopen([get(F.heditFolder,'String') FileName],'r');
                        dataArray = textscan(fileID,'%f%[^\n\r]','Delimiter','','EmptyValue',NaN,'ReturnOnError',false);
                        fclose(fileID);
                        if dataArray{2}{1}(1)==','
                            point = questdlg('It seems that your file uses the decimal mark ''comma''. A ''point'' mark is required. Do you want to change the decimal mark from Comma to Point and try again?','Decimal mark question','Yes and replace.','No - Stop please.','Yes and replace.');
                            if strcmp(point,'Yes and replace.')
                                file = memmapfile([get(F.heditFolder,'String') FileName], 'writable', true);
                                file.Data(transpose(file.Data==uint8(','))) = uint8('.');
                                fopen([get(F.heditFolder,'String') FileName],'r');
                                dataArray = textscan(fileID,'%f%[^\n\r]','Delimiter','','EmptyValue',NaN,'ReturnOnError',false);
                                fclose(fileID);
                            end
                        end                        
                        sig_waveform = dataArray{:,1}; clearvars dataArray;

                        set(F.htextBusy,'String','Busy - Beat annotations will be computed.');
                        drawnow
                        qrs_detection
                    end
                    
                    q = HRV.nanquantile(sig_waveform',[.05 .5 .95]);
                    sig_waveform = (sig_waveform-q(2))/(4*(q(3)-q(1))) +.4;
                    set(F.htextBusy,'String','');
                    RR = diff(Ann);
                    
                    sig = zeros(max(Ann)+1,1);
                    sig(Ann+1,1)=1;
                    set(F.hbuttonShowWaveform,'visible','on');

                case {'RR intervals','rr','RR'}
                    fileID = fopen([get(F.heditFolder,'String') FileName],'r');
                    dataArray = textscan(fileID,'%f%[^\n\r]','Delimiter','','EmptyValue',NaN,'ReturnOnError',false);
                    fclose(fileID);
                    RR = dataArray{:,1}; clearvars dataArray;
                    Ann = round(cumsum([0;RR]));
                        
                case {'Annotation','Annotations','Ann','ann'} 
                    fileID = fopen([get(F.heditFolder,'String') FileName],'r');
                    dataArray = textscan(fileID,'%f%[^\n\r]','Delimiter','','EmptyValue',NaN,'ReturnOnError',false);
                    fclose(fileID);
                    Ann = dataArray{:,1}; clearvars dataArray;
                    RR = diff(Ann);
                    sig = zeros(max(Ann)+1,1);
                    sig(Ann+1,1)=1;        
                    unit = {'Impulse'};
                    
                otherwise
                    warndlg('This is not a valid type of data. Please specify whether it is a ''waveform'' or a sequence of ''RR intervals''.')
            end
            if ismember(answer{1},{'waveform','RR intervals'})                    
                    sig = zeros(max(Ann)+1,1);
                    sig(Ann+1,1)=1;        
                    unit = {'Impulse'};   
%                     subjects = dir([PathName filesep '*.' fileextention]);
%                     set(F.hpopupSubject,'String',{subjects.name});
%                     set(F.hpopupSubject,'Value',find(ismember(get(F.hpopupSubject,'String'),FileName)));

                switch lower(fileextention)
                    case {'txt','csv'}
                        % try to load meta-data
                        selection = questdlg('Do you want to load meta-data from corresponding hrm-files?',...
                        'Load meta data','Yes','No','Yes');
                        switch selection 
                            case 'Yes'
                                PathName_metadata = uigetdir(PathName,'Select path for meta data');
                                if PathName_metadata~=0
                                    hrm = dir([PathName_metadata filesep FileName(1:end-4) '*.hrm']);
                                    if ~isempty(hrm)
                                        filename = [PathName_metadata filesep hrm.name];

                                        fileID = fopen(filename,'r');
                                        dataArray = textscan(fileID,'%s%s%[^\n\r]',50,'Delimiter','=','ReturnOnError',false);
                                        fclose(fileID);
                                        infos = table(dataArray{1:end-1}, 'VariableNames', {'attribute','val'});
                                        StartDate = datetime([infos.val{strcmp(infos.attribute,'Date')} ' ' infos.val{strcmp(infos.attribute,'StartTime')}],'InputFormat','yyyyMMdd HH:mm:ss.S');
                                        StartDelay = str2double(infos.val{strcmp(infos.attribute,'StartDelay')});

                                        S = table; warning('off','all');
                                        samples = dir([PathName_metadata filesep FileName(1:end-4) '*.txt']);
                                        for i=1:size(samples,1)
                                            tmp_sn = samples(i).name;

                                            S.name(i,:) = cellstr(tmp_sn(max(strfind(tmp_sn,'_'))+1:end-4));

                                            file2read = [PathName_metadata filesep tmp_sn];
                                            fileID = fopen(file2read,'r');
                                            dataArray = textscan(fileID, '%s%s%*s%s%[^\n\r]', 'Delimiter', {';',',','s'}, 'MultipleDelimsAsOne', true, 'ReturnOnError', false);
                                            fclose(fileID);
                                            Col1 = dataArray{:, 1};
                                            Val1 = dataArray{:, 2};
                                            Val2 = dataArray{:, 3};
                                            clearvars filename delimiter formatSpec fileID dataArray ans;

                                            anfang = find(ismember(strtrim(Col1),'Sample 1'));
                                            S.start(i) = str2double(strtrim(Val1{anfang}));

                                            snum = 0;
                                            while ~isempty(str2num(Val2{anfang+snum}))
                                                snum = snum+1;
                                            end
                                            S.ende(i) = str2double(Val2{anfang+snum-1});
                                        end
                                        S.center = (S.start+S.ende)/2;  
                                    end
                                    Ann = round(cumsum([StartDelay;RR]));
                                    sig = zeros(max(Ann)+1,1);
                                    sig(Ann+1,1)=1;
                                end                                
                            otherwise
                        end
                    otherwise
                end
            end
  
    end
    center = Ann(1:end-1)+RR/2;
    

    % Load File Settings
    if exist([get(F.heditFolder,'String') 'settings_' FileName(1:end-4) '.m'],'file')>0
        settings_file = [get(F.heditFolder,'String') 'settings_' FileName(1:end-4) '.m'];
        copyfile(settings_file,[AppPath filesep 'HRV_file_settings.m'])
        run('HRV_file_settings.m')
        
    elseif ~isempty(S)
        label_lim = S{:,2:3};
        label_names = table2cell(S(:,1))';
    end
    
    name_org = name;
    if ~isempty(my_title)
        name = {[name{1} my_title{1}]};
    end
    
    RRorg = RR/Fs;   
    if isnan(filter_limit)
        RRfilt = RRorg;
    else
        RRfilt = HRV.RRfilter(RRorg,filter_limit); 
    end
    RR = RRfilt;
    RR(my_artifacts) = NaN; 
    RR(min(my_artifacts+1,size(RR,1))) = NaN;
    relRR = HRV.rrx(RR);
    relRR_pct = round(relRR*1000)/10;

    tachogram  
    
    % Load Footprint
    if exist([get(F.heditFolder,'String') 'settings_' FileName(1:end-4) '.m'],'file')>0
        if showFootprint
            set(F.heditLimits,'String',FootprintRange);
            str = FootprintRange;
            pos = strfind(str,'..');
            if isempty(pos)
                pos = strfind(str,':');
                xl = [str2double(str(1:min(pos)-1)) str2double(str(max(pos)+1:end))];   
            else
                xl =  24*60*60*[datenum(datetime(str(1:min(pos)-1)))-floor(now) datenum(datetime(str(max(pos)+2:end)))-floor(now)];
            end
            set(F.ha1,'Xlim',xl);
            
            compute_local
            update_table_local           
            showFootprint = not(showFootprint); 
            buttonFootprint_Callback
        end
        set(F.heditLimits,'String',LocalRange);
        str = LocalRange;
        pos = strfind(str,'..');
        if isempty(pos)
            pos = strfind(str,':');
            xl = [str2double(str(1:min(pos)-1)) str2double(str(max(pos)+1:end))];   
        else
            xl =  24*60*60*[datenum(datetime(str(1:min(pos)-1)))-floor(now) datenum(datetime(str(max(pos)+2:end)))-floor(now)];
        end
        set(F.ha1,'Xlim',xl);
        editLimits  
    end

     
    waveform
    compute_local
    localreturnmap
    poincare
    spectrum_tachogram
    update_table_global
    update_table_local
    drawnow
    
    continuousHRV_compute_hf
    continuousHRV_compute_hrv
    if showTINN
        buttonContinuousTINN_Callback
    end
    if showLFHF
        buttonContinuousLFHF_Callback
    end
    continuousHRV_show
    
    refresh_positionmarker 

    calc_off

end



%% EDITFIELDS
function editFolder_Callback(hObject, eventdata, handles)
% hObject    handle to edit1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    
end


function editLimits_Callback(hObject, eventdata, handles)
    str = get(F.heditLimits,'String');
    pos = strfind(str,'..');
    if isempty(pos)
        pos = strfind(str,':');
        xl = [str2double(str(1:min(pos)-1)) str2double(str(max(pos)+1:end))];   
    else
        xl =  24*60*60*[datenum(datetime(str(1:min(pos)-1)))-floor(now) datenum(datetime(str(max(pos)+2:end)))-floor(now)];
    end
    set(F.ha1,'Xlim',xl);
    editLimits
end

function editLimits
    calc_on    
    xl = get(F.ha1,'Xlim');
    if strfind(get(F.heditLimits,'String'),'..')
        set(F.heditLimits,'String',[datestr(xl(1)/(24*60*60),'HH:MM:SS') '..' datestr(xl(2)/(24*60*60),'HH:MM:SS')])
    else
        set(F.heditLimits,'String',[num2str(xl(1)) ':' num2str(xl(2))])    
    end
    
    refresh_labeling    
    refresh_waveform
    compute_local    
    localreturnmap
    Tachogramstyle  
    spectrum_tachogram_local
    refresh_positionmarker
    update_table_local
    calc_off
end

function editLabel_Callback(hObject, eventdata, handles)

    str = get(F.heditLabel,'String');
    
    xl = get(F.ha1,'Xlim');
    if ~isempty(label_lim)
        pos = find(label_lim(:,1)==xl(1) & label_lim(:,2)==xl(2));  
    else
        pos = [];
    end
    
    if isempty(str)
        %remove label
        if ~isempty(pos)
            ch = get(F.ha5,'Children');
            delete(ch((size(label_lim,1)-pos+1)*2:(size(label_lim,1)-pos+1)*2+1));            
            label_lim(pos,:) = [];
            label_names(pos) = [];
        end
    else
        %add or rename label
        if isempty(pos)
            label_lim = [label_lim; get(F.ha1,'Xlim')];
            label_names = [label_names,str];
        else
            label_names{pos} = str;
        end
    end

    refresh_positionmarker_label
    editLimits
    update_table_local

end

function editFilter_Callback(hObject, eventdata, handles)
    calc_on
    filter_limit = str2double(get(F.heditFilter,'String'));
    if isnan(filter_limit)
        RRfilt = RRorg;
    else
        RRfilt = HRV.RRfilter(RRorg,filter_limit);
    end
    RR = RRfilt;   
    RR(my_artifacts) = NaN; RR(min(my_artifacts+1,size(RR,1))) = NaN;
    relRR = HRV.rrx(RR);
    relRR_pct = round(relRR*1000)/10;
    
    waveform
    compute_local    
    localreturnmap
    Tachogramstyle     
    spectrum_tachogram
    poincare
    
    refresh_positionmarker
    update_table
    set(F.hbuttonContinuousRecalculation,'visible','on');
    calc_off
end

function editSpeed_Callback(hObject, eventdata, handles)
    speed = str2double(get(F.heditSpeed,'String'));
    if isnan(speed)
        speed = 1;
    end
    set(F.heditSpeed,'String',num2str(speed));
end

function editMeasuresNum_Callback(hObject, eventdata, handles)
    calc_on
    MeasuresNum = str2double(get(F.heditMeasuresNum,'String'));
    set(F.hbuttonContinuousLFHF,'visible','on')
    set(F.hbuttonContinuousTINN,'visible','on')
    showTINN = false;
    showLFHF = false;
    vis = true(1,7);
    continuousHRV_compute_hrv
    continuousHRV_show   
    set(F.hbuttonContinuousRecalculation,'visible','off');
    calc_off
end

function editOverlap_Callback(hObject, eventdata, handles)
    calc_on
    Overlap = str2double(get(F.heditOverlap,'String'));
    continuousHRV_compute_hrv
    continuousHRV_show    
    calc_off
end


%% Popups
function popupSubject_Callback(hObject, eventdata, handles) 
    calc_on
    buttonStart_Callback
    calc_off
end

%% BUTTONS
function buttonCD_Callback(hObject, eventdata, handles) 
    [FileName,PathName] = uigetfile({'*.hrm';'*.txt';'*.csv';'*.ecg';'*.hrv';'*.wav';'*.mat'},'Select the ECG data');
    if length(PathName)>1
        set(F.heditFolder,'String',PathName);
        fileextention = FileName(max(strfind(FileName,'.'))+1:end);

        subjects = dir([PathName filesep '*.' fileextention]);
        set(F.hpopupSubject,'String',{subjects.name});
        set(F.hpopupSubject,'Value',find(ismember(get(F.hpopupSubject,'String'),FileName)));
        popupSubject_Callback    
    end
end

function buttonFontChange_Callback(hObject, eventdata, handles) 
    font_set = uisetfont(F.hbuttonFontChange);
%     ch = findall(F.fh,'type','text');
    if isstruct(font_set)
        names = fieldnames(F);
        for i=2:length(names)
            try
                set(F.(names{i}),font_set);
            catch
            end
        end    
        save('font_setting.mat','font_set');
    end
    set(F.htoolbarFont,'State','off')
end

function buttonTitle_Callback(hObject, eventdata, handles) 
    if isempty(my_title)
        my_title = inputdlg('Enter a title for the data:','Set title',1,{'my_title'});
    else
        my_title_new = inputdlg('Enter a title for the data:','Set title',1,my_title);
        if ~isempty(my_title_new)
            my_title = my_title_new;
        end
    end
    if isempty(my_title{1})
        name = name_org;
    else
        name = {[name_org my_title]};
    end
    title(F.ha1,name{signal_num},'Interpreter','none')
    set(F.htoolbarTitle,'State','off')
end


function buttonIntervalNext_Callback(hObject, eventdata, handles)  
    calc_on
    xl = get(F.ha1,'Xlim');
    set(F.ha1,'Xlim',ceil(xl(2))+[0 1]*diff([floor(xl(1)) ceil(xl(2))]));    
    editLimits
    calc_off
end

function buttonIntervalNext2_Callback(hObject, eventdata, handles)  
    calc_on
    xl = get(F.ha1,'Xlim');
    set(F.ha1,'Xlim',ceil(xl(2))+[5 6]*diff([floor(xl(1)) ceil(xl(2))]));
    editLimits
    calc_off
end

function buttonIntervalPrevious_Callback(hObject, eventdata, handles)
    calc_on
    xl = get(F.ha1,'Xlim');
     xl = ceil(xl(1))+[-1 0]*diff([floor(xl(1)) ceil(xl(2))]);
    set(F.ha1,'Xlim',[max([0 xl(1)]) max([10 xl(2)])]);
    editLimits
    calc_off
end

function buttonIntervalPrevious2_Callback(hObject, eventdata, handles)
    calc_on
    xl = get(F.ha1,'Xlim');
    xl = ceil(xl(1))+[-6 -5]*diff([floor(xl(1)) ceil(xl(2))]);
    set(F.ha1,'Xlim',[max([0 xl(1)]) max([10 xl(2)])]); 
    editLimits
    calc_off
end

function buttonShowWaveform_Callback(hObject, eventdata, handles)
    calc_on
    showWaveform = not(showWaveform);
    if showWaveform
        unit = {'Waveform'};
    else
        unit = {'Impulse'};
    end
    waveform
    calc_off
end

function buttonShowIntervals_Callback(hObject, eventdata, handles)
    calc_on
    showIntervals = not(showIntervals);
    refresh_waveform
    calc_off
end

function buttonShowProportions_Callback(hObject, eventdata, handles) 
    calc_on
    showProportions = not(showProportions);
    refresh_waveform
    calc_off
end

function buttonFilterDecrease_Callback(hObject, eventdata, handles) 
    calc_on
    filter_limit = filter_limit-5;
    set(F.heditFilter,'String',num2str(filter_limit));
    if isnan(filter_limit)
        RRfilt = RRorg;
    else
        RRfilt = HRV.RRfilter(RRorg,filter_limit);
    end
    RR = RRfilt;   
    RR(my_artifacts) = NaN; RR(min(my_artifacts+1,size(RR,1))) = NaN;
    relRR = HRV.rrx(RR);
    relRR_pct = round(relRR*1000)/10;

    waveform
    compute_local    
    localreturnmap
    tachogram      
    spectrum_tachogram
    poincare
    
    refresh_positionmarker
    update_table
    set(F.hbuttonContinuousRecalculation,'visible','on');
    calc_off
end

function buttonFilterIncrease_Callback(hObject, eventdata, handles) 
    calc_on
    filter_limit = filter_limit+5;
    set(F.heditFilter,'String',num2str(filter_limit));
    if isnan(filter_limit)
        RRfilt = RRorg;
    else
        RRfilt = HRV.RRfilter(RRorg,filter_limit);
    end
    RR = RRfilt;   
    RR(my_artifacts) = NaN; RR(min(my_artifacts+1,size(RR,1))) = NaN;
    relRR = HRV.rrx(RR);
    relRR_pct = round(relRR*1000)/10;
    
    waveform
    compute_local    
    localreturnmap
    tachogram
    spectrum_tachogram
    poincare
    
    refresh_positionmarker
    update_table
    set(F.hbuttonContinuousRecalculation,'visible','on');
    calc_off
end

function buttonRemoveArtifact_Callback(hObject, eventdata, handles) 

    [x, y] = getpts(F.ha1);
    
    calc_on    
    yl = get(F.ha1,'Ylim');
    x = x(y>yl(1) & y<yl(2));

    for i=1:length(x)
        [~,x(i)] = min(abs((Ann/Fs-x(i))));
        %center
    end
    no_artifacts = intersect(x-1,my_artifacts);

    my_artifacts = unique([my_artifacts; unique(x)-1]);
    my_artifacts = setdiff(my_artifacts,no_artifacts);
    
    RR = RRfilt;   
    RR(max(my_artifacts,1)) = NaN;
    RR(min(my_artifacts+1,size(RR,1))) = NaN;
    
    relRR = HRV.rrx(RR);
    relRR_pct = round(relRR*1000)/10;
    
    waveform
    compute_local    
    localreturnmap
    tachogram  
    spectrum_tachogram
    poincare
    update_table 
    set(F.hbuttonContinuousRecalculation,'visible','on');
    calc_off
end


function buttonRemoveArtifact2_Callback(hObject, eventdata, handles) 

    [x, y] = getpts(F.ha6);
    
    calc_on    
    yl = get(F.ha6,'Ylim');
    xl = get(F.ha6,'Xlim');
    
    cond = y>yl(1) & y<yl(2) & x>xl(1) & x<xl(2);
    x = x(cond);
    y = y(cond);
    
    for i=1:length(x)
        [~,x(i)] = min((RR(1:end-1)-x(i)).^2+(RR(2:end)-y(i)).^2);
    end

    no_artifacts = intersect(x,my_artifacts);
    my_artifacts = unique([my_artifacts; unique(x)]);
    my_artifacts = setdiff(my_artifacts,no_artifacts);
    
    RR = RRfilt;   
    RR(max(my_artifacts,1)) = NaN;
    RR(min(my_artifacts+1,size(RR,1))) = NaN;
    
    relRR = HRV.rrx(RR);
    relRR_pct = round(relRR*1000)/10;
    
    waveform
    compute_local   
    localreturnmap
    tachogram
    spectrum_tachogram
    poincare

    update_table 
    set(F.hbuttonContinuousRecalculation,'visible','on');
    calc_off
end

function buttonPicker_Callback(hObject, eventdata, handles) 

    [x,y] = getpts(F.ha6);
    x = x(end); y = y(end);
    
    calc_on    
    
    for i=1:length(x)
        [~,pos] = min((RRorg(1:end-1)-x(i)).^2+(RRorg(2:end)-y(i)).^2);
    end
    
    xl = get(F.ha1,'Xlim')
    set(F.ha1,'Xlim',[ceil(xl(1)+(center(pos)/Fs-mean(xl)))  ceil(xl(2)+(center(pos)/Fs-mean(xl)))]) 
    get(F.ha1,'Xlim')
    editLimits
    calc_off
end

function buttonReturnMapType_Callback(hObject, eventdata, handles) 
    calc_on  
    RMtype = not(RMtype);
    localreturnmap
    calc_off
end

function buttonNumbers_Callback(hObject, eventdata, handles) 
    calc_on  
    RMnumbers = not(RMnumbers);   
    localreturnmap
    calc_off
end

function buttonFootprint_Callback(hObject, eventdata, handles) 
    calc_on  
    showFootprint = not(showFootprint);
    if showFootprint
        fp_RR = RR_loc;
        fp_rr = rr_loc;
        set(F.htextFootprint,'visible','on')
        set(F.htextFootprint_rrHRV_median,'visible','on')
        set(F.htextFootprint_rrHRV_iqr,'visible','on')
        set(F.htextFootprint_rrHRV_shift,'visible','on')
        set(F.htextFootprint_range,'String',get(F.htextLocal_range,'String')) 
        set(F.htextFootprint_label,'String',get(F.htextLocal_label,'String')) 
    else
        fp_RR = []; fp_rr = [];
        set(F.htextFootprint,'visible','off')
        set(F.htextFootprint_rrHRV_median,'visible','off')
        set(F.htextFootprint_rrHRV_iqr,'visible','off')
        set(F.htextFootprint_rrHRV_shift,'visible','off')
    end
    localreturnmap 
    update_table_footprint
    refresh_positionmarker_label
    calc_off
end

function buttonPDF_Callback(hObject, eventdata, handles) 
    calc_on  
    showPDF = not(showPDF);   
    localreturnmap
    calc_off
end

function buttonMarkerDecrease_Callback(hObject, eventdata, handles) 
    calc_on  
    RMmarkersize = max(RMmarkersize-2.5,2.5);   
    localreturnmap
    calc_off
end

function buttonMarkerIncrease_Callback(hObject, eventdata, handles) 
    calc_on  
    RMmarkersize = RMmarkersize+2.5;   
    localreturnmap
    calc_off
end

function buttonLineType_Callback(hObject, eventdata, handles) 
    calc_on  
    RMlinetype = mod(RMlinetype+1,4); 
    localreturnmap
    calc_off
end

function buttonDetail_Callback(hObject, eventdata, handles) 
    calc_on  
    RMzoomlevel = mod(RMzoomlevel+1,4); 
    localreturnmap
    calc_off
end

function buttonAnimation_Callback(hObject, eventdata, handles) 
    % animation time warning
    if diff(get(F.ha1,'Xlim'))/speed > 30
        choice = questdlg(['The running time of the animation will be ' num2str(diff(get(F.ha1,'Xlim'))/speed,'%i') ' seconds. Do you want to continue or change the animation speed?'], ...
            'Animation speed warning', ...
            'Continue','Abort','Abort');
        switch choice
            case 'Continue'
                animation
            case 'Abort'
        end
    else
        animation
    end
end


function buttonTachogramType_Callback(hObject, eventdata, handles) 
    calc_on  
    Tachogramtype = not(Tachogramtype);
    Tachogramstyle  
    spectrum_tachogram
    calc_off
end

function buttonContinuousVisibility_Callback(hObject, eventdata, handles) 
    [~,y] = getpts(F.ha5);
    
    calc_on    
    yl = get(F.ha5,'YLim');    
    plotpos = get(F.ha5,'Position');

    min_l = yl(1)+diff(yl)*((plotpos(4)-legendpos(4))/plotpos(4));
    max_l = yl(2);
    
    d_l = (max_l-min_l)/(1+size(hLine2,1));
    legend_line_pos = (max_l-d_l/2):-d_l:min_l;
    
    for i=1:length(y)
        [~,y(i)] = min(abs(legend_line_pos-y(i)));
    end
    y = unique(y);
    vis(y) = not(vis(y));

    if vis(1)
        hLine1.Visible = 'on';
    else
        hLine1.Visible = 'off';
    end

    for i=1:length(hLine2)
        if vis(i+1)
            hLine2(i).Visible = 'on';
        else
            hLine2(i).Visible = 'off';
        end
    end
    calc_off
end

function buttonContinuousTINN_Callback(hObject, eventdata, handles) 
    calc_on  
    set(F.htextBusy,'String','Busy - TINN computation takes some time.');
    drawnow
    [HRV_tri,HRV_tinn] = HRV.triangular_val(RR,MeasuresNum,1/128,Overlap);
    
    % Linear Interpolation of continuous measures   
    steps = ceil(MeasuresNum*(1-Overlap));
    HRV_tri = interp1(steps:steps:length(RR),HRV_tri(steps:steps:length(RR)),1:length(RR)); 
    HRV_tinn = interp1(steps:steps:length(RR),HRV_tinn(steps:steps:length(RR)),1:length(RR)); 
    HRV_tri = HRV_tri(:);
    HRV_tinn = HRV_tinn(:);
    
    showTINN = true;
    set(F.htextBusy,'String','');
    set(F.hbuttonContinuousTINN,'visible','off')
    continuousHRV_show
    calc_off
end

function buttonContinuousLFHF_Callback(hObject, eventdata, handles) 
    calc_on  
    set(F.htextBusy,'String','Busy - Computation of LF/HF ratios takes some time.');
    drawnow
    [~,~,HRV_lfhfratio] = HRV.fft_val(RR,MeasuresNum,Fs,'spline',Overlap);
    
    % Linear Interpolation of continuous measures   
    steps = ceil(MeasuresNum*(1-Overlap));
    HRV_lfhfratio = interp1(steps:steps:length(RR),HRV_lfhfratio(steps:steps:length(RR)),1:length(RR));
    HRV_lfhfratio = HRV_lfhfratio(:);
    
    showLFHF = true;
    set(F.htextBusy,'String','');
    set(F.hbuttonContinuousLFHF,'visible','off')
    continuousHRV_show
    calc_off
end

function buttonPickerSection_Callback(hObject, eventdata, handles)
    if size(label_lim,1)>0
        [x,~] = getpts(F.ha5);
        calc_on
        x = x(end)*(24*60*60);     

        [~,x] = min(abs(mean(label_lim,2)-x));
        
        set(F.ha1,'Xlim',label_lim(x,:))
        editLimits
    end
end


%% Measures buttons
function buttonSaveAs_Callback(hObject, eventdata, handles) 
    [file,path] = uiputfile({'*.pdf';'*.png';'*.fig';'*.mat';'*.csv'},...
        'Save as',[get(F.heditFolder,'String') FileName(1:end-4) '_results']);
    if path~=0    
        switch file(end-2:end)
            case 'pdf'
                pos = get(F.fh,'Position');
                set(F.fh,'Position',[0,0,1280,900]);
                print('-painters','-dpdf', [path file])
                set(F.fh,'Position',pos);                
            case 'png'
                print('-dpng', [path file])
            case 'fig'
                savefig(F.fh,[path file],'compact')
            case {'csv','mat'}
                unit_val = [1 1 1 1 1000 60 1000 1000 100 1 1000 1000 1000 1 1 1 1];
                HRVglobal	 = [HRV_global_rrHRV_median HRV_global_rrHRV_iqr HRV_global_rrHRV_shift HRV_global_meanrr 1/HRV_global_meanrr HRV_global_sdnn HRV_global_rmssd HRV_global_pnn50 HRV_global_tri HRV_global_tinn HRV_global_sd1 HRV_global_sd2 HRV_global_sd1sd2ratio HRV_global_lf HRV_global_hf HRV_global_lfhfratio].*unit_val;
                HRVlocal     = [HRV_local_rrHRV_median HRV_local_rrHRV_iqr HRV_local_rrHRV_shift HRV_local_meanrr 1/HRV_local_meanrr HRV_local_sdnn HRV_local_rmssd HRV_local_pnn50 HRV_local_tri HRV_local_tinn HRV_local_sd1 HRV_local_sd2 HRV_local_sd1sd2ratio HRV_local_lf HRV_local_hf HRV_local_lfhfratio].*unit_val;
                HRVfootprint = [HRV_footprint_rrHRV_median HRV_footprint_rrHRV_iqr HRV_footprint_rrHRV_shift HRV_footprint_meanrr 1/HRV_footprint_meanrr HRV_footprint_sdnn HRV_footprint_rmssd HRV_footprint_pnn50 HRV_footprint_tri HRV_footprint_tinn HRV_footprint_sd1 HRV_footprint_sd2 HRV_footprint_sd1sd2ratio HRV_footprint_lf HRV_footprint_hf HRV_footprint_lfhfratio].*unit_val;
                if ~isempty(HRV_footprint_rrHRV_median)
                    HRVfootprint = [HRV_footprint_rrHRV_median HRV_footprint_rrHRV_iqr HRV_footprint_rrHRV_shift HRV_footprint_meanrr 1/HRV_footprint_meanrr HRV_footprint_sdnn HRV_footprint_rmssd HRV_footprint_pnn50 HRV_footprint_tri HRV_footprint_tinn HRV_footprint_sd1 HRV_footprint_sd2 HRV_footprint_sd1sd2ratio HRV_footprint_lf HRV_footprint_hf HRV_footprint_lfhfratio].*unit_val;
                    Results = table(HRVglobal',HRVlocal',HRVfootprint',...
                    'RowNames',{'rrHRV_median','rrHRV_iqr','rrHRV_shift_x','rrHRV_shift_y','meanrr','hr','sdnn','rmssd','pnn50','tri','tinn','sd1','sd2','sd1sd2ratio','lf','hf','lfhfratio'},...
                    'VariableNames',{'Global',matlab.lang.makeValidName(['Local_' get(F.htextLocal_range,'String')]),matlab.lang.makeValidName(['Footprint_' get(F.htextFootprint_range,'String')])});
                    if ~showFootprint
                        Results(:,3) = [];
                    end 
                else
                    Results = table(HRVglobal',HRVlocal',...
                    'RowNames',{'rrHRV_median','rrHRV_iqr','rrHRV_shift_x','rrHRV_shift_y','meanrr','hr','sdnn','rmssd','pnn50','tri','tinn','sd1','sd2','sd1sd2ratio','lf','hf','lfhfratio'},...
                    'VariableNames',{'Global',matlab.lang.makeValidName(['Local_' get(F.htextLocal_range,'String')])});
                end
                               
                if strcmp(file(end-2:end),'csv')
                    writetable(Results,[path file],'WriteRowNames',true,'Delimiter','\t')
                else
                    save([path file],'Results')
                end
                
            otherwise
                msgbox({'Save as mat or csv will be supported soon.'});  
        end
    end
    calc_off
end

function buttonCopy_Callback(hObject, eventdata, handles) 
    unit_val = [1 1 1 1 1000 60 1000 1000 100 1 1000 1000 1000 1 1 1 1];
    HRVglobal	 = [HRV_global_rrHRV_median HRV_global_rrHRV_iqr HRV_global_rrHRV_shift HRV_global_meanrr 1/HRV_global_meanrr HRV_global_sdnn HRV_global_rmssd HRV_global_pnn50 HRV_global_tri HRV_global_tinn HRV_global_sd1 HRV_global_sd2 HRV_global_sd1sd2ratio HRV_global_lf HRV_global_hf HRV_global_lfhfratio].*unit_val;
    HRVlocal     = [HRV_local_rrHRV_median HRV_local_rrHRV_iqr HRV_local_rrHRV_shift HRV_local_meanrr 1/HRV_local_meanrr HRV_local_sdnn HRV_local_rmssd HRV_local_pnn50 HRV_local_tri HRV_local_tinn HRV_local_sd1 HRV_local_sd2 HRV_local_sd1sd2ratio HRV_local_lf HRV_local_hf HRV_local_lfhfratio].*unit_val;
    if ~isempty(HRV_footprint_rrHRV_median)
        HRVfootprint = [HRV_footprint_rrHRV_median HRV_footprint_rrHRV_iqr HRV_footprint_rrHRV_shift HRV_footprint_meanrr 1/HRV_footprint_meanrr HRV_footprint_sdnn HRV_footprint_rmssd HRV_footprint_pnn50 HRV_footprint_tri HRV_footprint_tinn HRV_footprint_sd1 HRV_footprint_sd2 HRV_footprint_sd1sd2ratio HRV_footprint_lf HRV_footprint_hf HRV_footprint_lfhfratio].*unit_val;
        Results = [HRVglobal' HRVlocal' HRVfootprint'];
        if ~showFootprint
            Results(:,3) = [];
        end
    else
        Results = [HRVglobal' HRVlocal'];
    end

    clipboard('copy', mat2str(Results,5))
end

%% Help menu buttons
function MenuTutorial(hObject, eventdata, handles)
    stat = web('http://marcusvollmer.github.io/HRV/','-browser');
    if stat~=0
        web('http://marcusvollmer.github.io/HRV/manual_english.html');
    end   
end

function MenuWebsite(hObject, eventdata, handles)
    stat = web('http://marcusvollmer.github.io/HRV/','-browser');
    if stat~=0
        web('http://marcusvollmer.github.io/HRV/');
    end
end

function MenuTerms(hObject, eventdata, handles)
message = {['HRVTool v' num2str(HRVTool_version,'%01.2f')],'Analyzing Heart Rate Variability','',...
'This work and all supported files and functions are licensed under the terms of the MIT License (MIT).','',...
'Icons licensed under MIT. Copyright (c) 2014 Drifty (http://drifty.com/)','',...
'The MIT License (MIT)','',...
'Copyright (c) 2015 Marcus Vollmer (http://marcusvollmer.github.io/HRV/)','',...
['Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal'...
'in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell'...
'copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:'],'',...
'The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.','',...
'THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.',...
'',HRVTool_version_date};

    msgbox(message,'HRVTool Terms of use','custom',importdata('logo.png'));   
end

function MenuInfo(hObject, eventdata, handles) 
message = {['HRVTool v' num2str(HRVTool_version,'%01.2f')],'Analyzing Heart Rate Variability','',...
'The user interface is made for all people who are interested in HRV, as well as scientists.',...
'HRVTool has been tested on Windows 7 64bit, Linux Ubuntu 14.04 and Mac OS 10.9.','',...
'Bug reports and other issues are welcome. Please correspond to marcus.vollmer@uni-greifswald.de.','',...
'This work and all supported files and functions are licensed under the terms of the MIT License (MIT).',...
'Copyright (c) 2015-2017 Marcus Vollmer','',HRVTool_version_date};

    msgbox(message,'HRVTool Info','custom',importdata('logo.png'));
end

%% CALC ON/OFF
function calc_on
    set(F.hpSubject,'BackgroundColor',[1 0 0])
    set(F.hpFootline,'BackgroundColor',[1 0 0])
    set(F.htextAuthor,'BackgroundColor',[1 0 0])
    set(F.htextBusy,'BackgroundColor',[1 0 0])
    drawnow
end
function calc_off
    set(F.hpSubject,'BackgroundColor',[1 1 1])
    set(F.hpFootline,'BackgroundColor',[1 1 1])
    set(F.htextAuthor,'BackgroundColor',[1 1 1])
    set(F.htextBusy,'BackgroundColor',[1 1 1])
    drawnow
end


%% Main function
function waveform
    % Waveform plot
    signal_num = 1;
    clear F.ha1
    
    if showWaveform
        plot(F.ha1,[1:size(sig_waveform,1)]/Fs,sig_waveform(:,signal_num),'b');
    else
        plot(F.ha1,[1:size(sig,1)]/Fs,sig(:,signal_num),'b');
    end
    hold(F.ha1,'on')
    plot(F.ha1,Ann(my_artifacts+1)/Fs,repmat(.6,length(my_artifacts),1),'xk');
    %mycol = p.Color;

    yl = max(sig(:,signal_num));
    ylm = min(sig(:,signal_num));
     
    str = get(F.heditLimits,'String');
    pos = strfind(str,'..');
    if isempty(pos)
        pos = strfind(str,':');
        xl = [str2double(str(1:min(pos)-1)) str2double(str(max(pos)+1:end))];   
    else
        xl =  24*60*60*[datenum(datetime(str(1:min(pos)-1)))-floor(now) datenum(datetime(str(max(pos)+2:end)))-floor(now)];
    end
        
    axis(F.ha1,[xl(1),xl(2),ylm,(yl-ylm)*.5+yl])

    
    set(F.ha1,'visible','on')

    xl = get(F.ha1,'Xlim');
    tmp = find(Ann/Fs<xl(2) & Ann/Fs>xl(1));
    if size(tmp,1)>30
        rotation = 90;
    else
        rotation = 0;
    end
    if showIntervals
        for j=1:size(tmp,1)
            i = tmp(j);
            if i<size(Ann,1)
                line((Ann(i)/Fs+RR(i)*[.1 .9]),[.6 .6]*(yl-ylm)+ylm,'Color','k','Parent',F.ha1)
                text(center(i)/Fs,.7*(yl-ylm)+ylm,num2str(RR(i),'%.2f'),'HorizontalAlignment','center','Rotation',rotation,'Clipping','on','Parent',F.ha1)    
            end
        end
    end

    if showProportions
        v = sin(0:pi/4:pi);
        cmap = parula;
        c = cmap(min(64,max(1,32+round(32*relRR_pct/20))),:);
        for j=1:size(tmp,1)   
            i = max([tmp(j)-1 1]);
            if i<size(Ann,1)-1
                plot((center(i):diff(center(i:i+1))/4:center(i+1))/Fs,sign(relRR_pct(i+1))*v*(yl-ylm)*.15+(yl-ylm)*.95+ylm,'-','Color',c(i,:),'Parent',F.ha1);    
                text(Ann(i+1)/Fs,1.2*yl,[num2str(relRR_pct(i+1),'%.1f') '%'],'HorizontalAlignment','center','Rotation',rotation,'Clipping','on','Parent',F.ha1)    
            end
        end
    end


    hold(F.ha1,'off')
    ylabel(F.ha1,unit{signal_num})
%     xlabel(F.ha1,'sec')
    title(F.ha1,name{signal_num},'Interpreter','none')
      
end

%% refresh_wavefrom
function refresh_waveform
    hold(F.ha1,'on')
    xl = get(F.ha1,'Xlim');
    yl = get(F.ha1,'Ylim'); ylm = yl(1); yl = (yl(2)+.25*ylm)/1.5;
    
    % clear children
    ch = get(F.ha1,'Children');
    delete(ch(1:end-1));

    plot(F.ha1,Ann(my_artifacts+1)/Fs,repmat(.6,length(my_artifacts),1),'xk');
    
    tmp = find(Ann/Fs<xl(2) & Ann/Fs>xl(1));
    if size(tmp,1)>30
        rotation = 90;
    else
        rotation = 0;
    end
    if showIntervals
        for j=1:size(tmp,1)
            i = tmp(j);
            if i<size(Ann,1)
                line((Ann(i)/Fs+RR(i)*[.1 .9]),[.6 .6]*(yl-ylm)+ylm,'Color','k','Parent',F.ha1)
                text(center(i)/Fs,.7*(yl-ylm)+ylm,num2str(RR(i),'%.2f'),'HorizontalAlignment','center','Rotation',rotation,'Clipping','on','Parent',F.ha1)    
            end
        end
    end

    if showProportions
        v = sin(0:pi/4:pi);
        cmap = parula;
        c = cmap(min(64,max(1,32+round(32*relRR_pct/20))),:);
        for j=1:size(tmp,1)   
            i = max([tmp(j)-1 1]);
            if i<size(Ann,1)-1
                plot((center(i):diff(center(i:i+1))/4:center(i+1))/Fs,sign(relRR_pct(i+1))*v*(yl-ylm)*.15+(yl-ylm)*.95+ylm,'-','Color',c(i,:),'Parent',F.ha1);    
                text(Ann(i+1)/Fs,1.2*yl,[num2str(relRR_pct(i+1),'%.1f') '%'],'HorizontalAlignment','center','Rotation',rotation,'Clipping','on','Parent',F.ha1)    
            end
        end
    end    

    hold(F.ha1,'off')
end

%% Compute QRS-File
function qrs_detection
    Ann = [];

    %Segmentation
    seg = ceil(length(sig_waveform)/(300*Fs));
    if seg>2        
        for i=0:seg-1
            set(F.htextBusy,'String',['Busy - Beat annotations will be computed. Segment ' num2str(i+1,'%i') ' of ' num2str(seg,'%i')]);
            drawnow
            sig_waveform_tmp = sig_waveform(max(300*Fs*i-10*Fs,1):min(300*Fs*(i+1),length(sig_waveform)));
            if sum(isnan(sig_waveform_tmp))~=length(sig_waveform_tmp)
                Ann_tmp = singleqrs(sig_waveform_tmp,Fs,'downsampling',d_fs,'Beat_min',Beat_min,'Beat_max',Beat_max,'wl_tma',wl_tma,'wl_we',wl_we); 
                Ann = [Ann; Ann_tmp+max(300*Fs*i-10*Fs,1)];
            end
        end
        Ann = Ann(Ann>0 & Ann<=length(sig_waveform));
        Ann = unique(sort(Ann));
        Ann(diff(Ann)<.05*Fs)=[];
    else
        Ann = singleqrs(sig_waveform,Fs,'downsampling',d_fs,'Beat_min',Beat_min,'Beat_max',Beat_max,'wl_tma',wl_tma,'wl_we',wl_we);
    end
    
    selection = questdlg('Do you want to save the annotation file?','Save annotation file','Yes','No','Yes');    
    switch selection 
        case 'Yes'
            [filename, pathname] = uiputfile({'*.mat';'*.txt';'*.csv'},'Save annotation file as',[get(F.heditFolder,'String') FileName(1:end-4) '_ann.mat']);
            if pathname~=0
                calc_on
                save([pathname filename],'Ann')
                calc_off
            end
        case 'No'
        otherwise
    end

end

%% Load Annotation file
function load_annotation
    [AnnFileName,AnnPathName] = uigetfile({'*.mat';'*.txt';'*.csv'},'Select the annotation file',[get(F.heditFolder,'String') FileName(1:end-4) '_ann.mat']);
    if length(AnnPathName)>1
        AnnType = AnnFileName(max(strfind(AnnFileName,'.'))+1:end);
        switch AnnType
            case 'mat'
                AnnmatObj = matfile([AnnPathName AnnFileName]);
                Annfn = fieldnames(AnnmatObj);
                % filter fieldnames with numeric type
                for i=1:size(Annfn,1)
                    fn_num(i) = isnumeric(AnnmatObj.(Annfn{i}));
                end
                switch sum(fn_num)
                    case 0
                        warndlg('There is no numeric data inside the mat-file.')
                    case 1
                        Anndata_name = Annfn{fn_num};

                    otherwise
                        str = Annfn(fn_num);
                        [s,v] = listdlg('PromptString','Select a file:',...
                            'SelectionMode','single','ListString',str);
                        if v>0
                            Anndata_name = str{s};
                        end
                end                                        
                Ann = AnnmatObj.(Anndata_name);
                
            otherwise
                fileID = fopen([AnnPathName AnnFileName],'r');
                dataArray = textscan(fileID,'%f%[^\n\r]','Delimiter','','EmptyValue',NaN,'ReturnOnError',false);
                fclose(fileID);
                Ann = dataArray{:,1}; clearvars dataArray;
        end    
    end
end

%% Compute Local
function compute_local
    xl = get(F.ha1,'Xlim');
    tmp = find(Ann/Fs<xl(2) & Ann/Fs>xl(1));
    tmp = setdiff(tmp,size(Ann,1));
    if size(tmp,1)>1
        RR_loc = RR(tmp(1:end-1));
        if tmp(1)==1;
            rr_loc = relRR(tmp(1:end-1))*100;  
        else
            rr_loc = relRR(tmp(2:end-1))*100;
        end
    else
        RR_loc = [NaN;NaN];
        rr_loc = [NaN;NaN];
    end
end

%% Local Return Map
function localreturnmap
    set(F.ha2,'visible','on')
    set(F.ha2b,'visible','off') 
    delete(get(F.ha2b,'Children'));
    
    types = {'-','--',':','none'};
    if RMtype        
        if showFootprint
            plot(fp_RR(1:end-1),fp_RR(2:end),'Parent',F.ha2,'LineStyle',types{RMlinetype+1},...
            'Marker','o','MarkerFaceColor',.8*[1 1 1],'MarkerEdgeColor',.8*[1 1 1],'MarkerSize',RMmarkersize-2,...
            'Color',.8*[1 1 1])
            hold(F.ha2,'on')
        end              
        plot(RR_loc(1:end-1),RR_loc(2:end),'Parent',F.ha2,'LineStyle',types{RMlinetype+1},...
            'Marker','o','MarkerFaceColor',0*[1 1 1],'MarkerEdgeColor',0*[1 1 1],'MarkerSize',RMmarkersize,...
            'Color',0*[1 1 1])
        if RMnumbers
            for j=1:size(RR_loc,1)-1
                text(RR_loc(j),RR_loc(j+1),num2str(j,'%i'),'Parent',F.ha2,'HorizontalAlignment','center','Clipping','on','Color',[1 1 1])         
            end
        end
        RMstyle_RR
        hold(F.ha2,'off')
    else
        if showFootprint
            plot(fp_rr(1:end-1),fp_rr(2:end),'Parent',F.ha2,'LineStyle',types{RMlinetype+1},...
            'Marker','o','MarkerFaceColor',.8*[1 1 1],'MarkerEdgeColor',.8*[1 1 1],'MarkerSize',RMmarkersize-2,...
            'Color',.8*[1 1 1])
            hold(F.ha2,'on')
        end 
        plot(rr_loc(1:end-1),rr_loc(2:end),'Parent',F.ha2,'LineStyle',types{RMlinetype+1},...
            'Marker','o','MarkerFaceColor',0*[1 1 1],'MarkerEdgeColor',0*[1 1 1],'MarkerSize',RMmarkersize,...
            'Color',0*[1 1 1])
        if RMnumbers
            for j=1:size(rr_loc,1)-1
                text(rr_loc(j),rr_loc(j+1),num2str(j,'%i'),'Parent',F.ha2,'HorizontalAlignment','center','Clipping','on','Color',[1 1 1])         
            end
        end
        RMstyle_rr
        hold(F.ha2,'off')
        if showPDF
            rrHRV_pdf(RR_loc,rr_loc)
        end
    end

end

function rrHRV_pdf(RR_loc,rr_loc)
    set(F.ha2b,'visible','on') 
    delete(get(F.ha2b,'Children'));
    
    [med,qr,shift] = HRV.rrHRV(RR_loc,0);
    
	hold(F.ha2,'on')
	plot(shift(1),shift(2),'xb','MarkerSize',20,'Parent',F.ha2)
	hold(F.ha2,'off')
    
    if showFootprint
        [~,~,fp_shift] = HRV.rrHRV(fp_RR,0);
        fp_d = sqrt(sum([fp_rr(1:end-1)-fp_shift(1) fp_rr(2:end)-fp_shift(2)].^2,2));
        if sum(~isnan(fp_d))>1
            [fp_f,fp_xi] = ksdensity(fp_d);
            area(fp_xi,fp_f,'Parent',F.ha2b,'FaceColor',.8*[1 1 1],'EdgeColor',.8*[1 1 1])
            hold(F.ha2b,'on')
        end
    end

    d = sqrt(sum([rr_loc(1:end-1)-shift(1) rr_loc(2:end)-shift(2)].^2,2));    
    if sum(~isnan(d))>1
        [f,xi] = ksdensity(d);
        plot(xi,f,'-k','Parent',F.ha2b,'LineWidth',2)
        hold(F.ha2b,'on')
        text(23,.2,['Median = ' num2str(med,'%.2f')],...
            'HorizontalAlignment','right','Parent',F.ha2b)
        text(23,.14,['IQR = ' num2str(qr,'%.2f')],...
            'HorizontalAlignment','right','Parent',F.ha2b)
        hold(F.ha2b,'off')
        PDFstyle 
    else
        hold(F.ha2b,'on')
        text(23,.2,'Median = NaN',...
            'HorizontalAlignment','right','Parent',F.ha2b)
        text(23,.14,'IQR = NaN',...
            'HorizontalAlignment','right','Parent',F.ha2b)
        hold(F.ha2b,'off')
        PDFstyle 
    end
end


%% Animation
function animation
    
    % animation of LocalReturnMap, waveform and return map
    % clear children
    ch = get(F.ha1,'Children');
    ch2 = get(F.ha2,'Children');
    ch3 = get(F.ha6,'Children');

    if isempty(my_artifacts)
        delete(ch(1:end-1));
        delete(ch3(1:end-2));
    else
        delete(ch(1:end-2));
        delete(ch3(1:end-3));
    end
    delete(ch2);
    
    hold(F.ha1,'on')
    hold(F.ha2,'on')
    hold(F.ha6,'on')
    
    h_white = animatedline('Parent',F.ha1);
    h_white.Color = [1 1 1];
    h_white.LineWidth = 2;

    h = animatedline('Parent',F.ha1);
    h.Color = [0 0 0];
    h.LineWidth = 2;
    
    xl = round(get(F.ha1,'Xlim')*Fs);
    tmp = find(Ann<xl(2) & Ann>xl(1));
    if size(tmp,1)>30
        rotation = 90;
    else
        rotation = 0;
    end
    types = {'-','--',':','none'}; 
    
    yl = max(sig(:,signal_num));
    ylm = min(sig(:,signal_num));

    
    a = tic; % start timer
    ktmp =  max(1,xl(1));
    addpoints(h_white,ktmp/Fs:1/Fs:ktmp/Fs+.5,sig(ktmp:ktmp+.5*Fs,signal_num))
    
    rate = speed/20;
    flag = -min(sum(Ann<xl(1)),2);
    flag2 = 0; num = 1;
    for k=1:ceil(diff(xl)/(rate*Fs)) 

        if k==1
            von = max(xl(1),1);
        else
            von = bis+1;
        end
        bis = xl(1)+floor(k*rate*Fs);
        
        if bis<=size(sig,1) 
            addpoints(h,(von:bis)/Fs,sig(von:bis,signal_num))
            if bis<min(xl(2)-.5*Fs,size(sig,1)-.5*Fs) 
                addpoints(h_white,(von:bis)/Fs+.5,sig((von:bis)+.5*Fs,signal_num))
            end
        end
        
        tmp = find(Ann<=bis & Ann>=von);
        
        for j=1:size(tmp,1)
            i=tmp(j)-1;
            if i>0
                if showIntervals
                    line((Ann(i)/Fs+RR(i)*[.1 .9]),[.6 .6]*(yl-ylm)+ylm,'Color','k','Parent',F.ha1)
                    text(center(i)/Fs,.7*(yl-ylm)+ylm,num2str(RR(i),'%.2f'),'HorizontalAlignment','center','Rotation',rotation,'Clipping','on','Parent',F.ha1)    
                end
                if i>1 && flag>0
                    plot(RR(i-1),RR(i),'Parent',F.ha6,...
                    'Marker','o','MarkerFaceColor',[0 0 0],'MarkerEdgeColor',[1 1 1],'MarkerSize',5);
                end
            end
        end       

        v = sin(0:pi/4:pi);
        cmap = parula;
        c = cmap(min(64,max(1,32+round(32*relRR_pct/20))),:);
        for j=1:size(tmp,1)
            i=tmp(j)-2;
            if i>0

                if showProportions 
                    plot((center(i):diff(center(i:i+1))/4:center(i+1))/Fs,sign(relRR_pct(i+1))*v*(yl-ylm)*.15+(yl-ylm)*.95+ylm,'-','Color',c(i,:),'Parent',F.ha1);    
                    text(Ann(i+1)/Fs,1.2*yl,[num2str(relRR_pct(i+1),'%.1f') '%'],'HorizontalAlignment','center','Rotation',rotation,'Clipping','on','Parent',F.ha1)    
                end
                
                % Local Return Map
                if RMtype
                    if flag>0
                        if flag2>0
                            line(RR(i-1:i),RR(i:i+1),'Parent',F.ha2,'LineStyle',types{RMlinetype+1},'Color',[0 0 0]);
                        else
                            flag2 = 1;
                        end
                        plot(RR(i),RR(i+1),'Parent',F.ha2,...
                            'Marker','o','MarkerFaceColor',[0 0 0],'MarkerEdgeColor',[1 1 1],'MarkerSize',RMmarkersize);                    
                        if RMnumbers
                            text(RR(i),RR(i+1),num2str(num,'%i'),'Parent',F.ha2,...
                                'HorizontalAlignment','center','Clipping','on','Color',[1 1 1]) 
                        end
                        num = num+1;
                    else
                        flag = flag+2;
                    end
                else
                    if flag>0
                        if flag2>0
                            line(relRR_pct(i-1:i),relRR_pct(i:i+1),'Parent',F.ha2,'LineStyle',types{RMlinetype+1},'Color',[0 0 0]);
                        else
                            flag2 = 1;
                        end
                        plot(relRR_pct(i),relRR_pct(i+1),'Parent',F.ha2,...
                            'Marker','o','MarkerFaceColor',[0 0 0],'MarkerEdgeColor',[1 1 1],'MarkerSize',RMmarkersize);                    
                        if RMnumbers
                            text(relRR_pct(i),relRR_pct(i+1),num2str(num,'%i'),'Parent',F.ha2,...
                                'HorizontalAlignment','center','Clipping','on','Color',[1 1 1]) 
                        end
                        num = num+1;
                    else
                        flag = flag+1;
                    end
                end
            end
        end 
       
        
        while toc(a)<k*rate/speed
        end

        drawnow % update screen
    end
    toc(a)
    hold(F.ha2,'off') 
    hold(F.ha6,'off')
    
    ch3 = get(F.ha6,'Children');
    if isempty(my_artifacts)
        delete(ch3(1:end-2));
    else
        delete(ch3(1:end-3));
    end
    
end



%% RR Tachogram
function tachogram
    plot((Ann(2:end)/Fs)/(24*60*60),RR,'-k','Parent',F.ha3)
    refresh_positionmarker_label
    Tachogramstyle 
end

%% Spectrum of RR Tachogram
function spectrum_tachogram
    if Tachogramtype
        spectrum_tachogram_local
    else
        set(F.ha4,'visible','on');
        if sum(isnan(RRorg))==0 && ~isempty(RRorg)
            [pLF,pHF,LFHFratio,~,~,~,f,Y,NFFT] = HRV.fft_val_fun(RRorg,Fs);
            plot(F.ha4,f,2*abs(Y(1:NFFT/2+1)))

            yl = get(F.ha4,'Ylim');
            text(.185,.8*yl(2),['\bfLF/HF ratio = ' num2str(LFHFratio,'%.3f')],'HorizontalAlignment','center','parent',F.ha4)
            text(.095,.5*yl(2),{'LFnu' [num2str(pLF,'%.2f') '%']},'HorizontalAlignment','center','parent',F.ha4)
            text(.275,.5*yl(2),{'HFnu' [num2str(pHF,'%.2f') '%']},'HorizontalAlignment','center','parent',F.ha4)
        
            Spectrumstyle
        else
            delete(get(F.ha4,'Children'));
            set(F.ha4,'visible','off');
        end        
    end    
end

function spectrum_tachogram_local
    if Tachogramtype
        if sum(isnan(RR_loc))==0 && ~isempty(RR_loc)
            set(F.ha4,'visible','on');
            [pLF,pHF,LFHFratio,~,~,~,f,Y,NFFT] = HRV.fft_val_fun(RR_loc,Fs);
            plot(F.ha4,f,2*abs(Y(1:NFFT/2+1)))

            yl = get(F.ha4,'Ylim');
            text(.185,.8*yl(2),['\bfLF/HF ratio = ' num2str(LFHFratio,'%.3f')],'HorizontalAlignment','center','parent',F.ha4)
            text(.095,.5*yl(2),{'LFnu' [num2str(pLF,'%.2f') '%']},'HorizontalAlignment','center','parent',F.ha4)
            text(.275,.5*yl(2),{'HFnu' [num2str(pHF,'%.2f') '%']},'HorizontalAlignment','center','parent',F.ha4)

            Spectrumstyle
        else 
            delete(get(F.ha4,'Children'));
            set(F.ha4,'visible','off');
        end
    end
end

%% Poincare
function poincare
    
    x_nan = find(isnan(RR(1:end-1)));  
    x_nan = unique([max(x_nan-1,1); x_nan]);
    plot(RRorg(x_nan),RRorg(x_nan+1),'.','Parent',F.ha6,'Color',[1 .5 .5])
    
    hold(F.ha6,'on')
    
    x1 = RR(1:end-1);
    x2 = RR(2:end);
    plot(x1,x2,'.','Parent',F.ha6,'Color',[0 .45 .75])
    [SD1,SD2,~] = HRV.returnmap_val(RR,0);
    
    plot(RRorg(my_artifacts(my_artifacts>0 & my_artifacts<size(RRorg,1)-1)),...
        RRorg(my_artifacts(my_artifacts>0 & my_artifacts<size(RRorg,1)-1)+1),...
        'xk','Parent',F.ha6);
    p = calculateEllipse(HRV.nanmean(x1),HRV.nanmean(x2),2*SD1,2*SD2,45);
    plot(F.ha6,p(:,1), p(:,2),'k','linewidth',1.5)
    hold(F.ha6,'off')
  
    Poincarestyle
end

function [X,Y] = calculateEllipse(x, y, a, b, angle, steps)
    %# This functions returns points to draw an ellipse
    %#
    %#  @param x     X coordinate
    %#  @param y     Y coordinate
    %#  @param a     Semimajor axis
    %#  @param b     Semiminor axis
    %#  @param angle Angle of the ellipse (in degrees)
    %#

    narginchk(5, 6);
    if nargin<6, steps = 36; end

    beta = -angle * (pi / 180);
    sinbeta = sin(beta);
    cosbeta = cos(beta);

    alpha = linspace(0, 360, steps)' .* (pi / 180);
    sinalpha = sin(alpha);
    cosalpha = cos(alpha);

    X = x + (a * cosalpha * cosbeta - b * sinalpha * sinbeta);
    Y = y + (a * cosalpha * sinbeta + b * sinalpha * cosbeta);

    if nargout==1, X = [X Y]; end
end

%% Continuous HRV measures
function continuousHRV_compute_hf
    HRV_hf = HRV.HR(RR,MeasuresNum);  
end

function continuousHRV_compute_hrv
    set(F.htextBusy,'String','Busy - Recalculation of HRV parameters.');
    drawnow
  
    tic
    [HRV_rr_med,HRV_rr_iqr,HRV_rr_shift] = HRV.rrHRV(RR,MeasuresNum,'central',Overlap);
    HRV_rmssd = HRV.RMSSD(RR,MeasuresNum,1,Overlap);
    HRV_sdnn = HRV.SDNN(RR,MeasuresNum,1,Overlap);
    HRV_sdsd = HRV.SDSD(RR,MeasuresNum,1,Overlap);
    HRV_pnn50 = HRV.pNN50(RR,MeasuresNum,1,Overlap);
    [~,~,HRV_sd1sd2ratio] = HRV.returnmap_val(RR,MeasuresNum,1,Overlap);
    
    % Linear Interpolation of continuous measures   
    steps = ceil(MeasuresNum*(1-Overlap));
    HRV_rr_med = interp1(steps:steps:length(RR),HRV_rr_med(steps:steps:length(RR)),1:length(RR));
    HRV_rr_iqr = interp1(steps:steps:length(RR),HRV_rr_iqr(steps:steps:length(RR)),1:length(RR));   
    HRV_rmssd = interp1(steps+1:steps:length(RR),HRV_rmssd(steps+1:steps:length(RR)),1:length(RR));
    HRV_sdnn = interp1(steps:steps:length(RR),HRV_sdnn(steps:steps:length(RR)),1:length(RR));   
    HRV_sdsd = interp1(steps+1:steps:length(RR),HRV_sdsd(steps+1:steps:length(RR)),1:length(RR));
    HRV_pnn50 = interp1(steps+1:steps:length(RR),HRV_pnn50(steps+1:steps:length(RR)),1:length(RR));   
    HRV_sd1sd2ratio = interp1(steps+1:steps:length(RR),HRV_sd1sd2ratio(steps+1:steps:length(RR)),1:length(RR));   
    
    HRV_rr_med = HRV_rr_med(:);
    HRV_rr_iqr = HRV_rr_iqr(:);
    HRV_rmssd = HRV_rmssd(:);
    HRV_sdnn = HRV_sdnn(:);
    HRV_sdsd = HRV_sdsd(:);
    HRV_pnn50 = HRV_pnn50(:);
    HRV_sd1sd2ratio = HRV_sd1sd2ratio(:);
    toc

    set(F.htextBusy,'String','');
end



function continuousHRV_show
    clear F.ha5
    x = Ann(2:end)/(Fs*24*60*60);
    
    if showTINN && showLFHF
        [hAx,hLine1,hLine2] = plotyy(x,HRV_hf,...
        [x,x,x,x,x,x],...
        [HRV_rr_med,HRV_rr_iqr,HRV_rmssd/100,HRV_sd1sd2ratio,HRV_tinn,HRV_lfhfratio],...
        'Parent',F.ha5);
    elseif showTINN
        [hAx,hLine1,hLine2] = plotyy(x,HRV_hf,...
        [x,x,x,x,x],...
        [HRV_rr_med,HRV_rr_iqr,HRV_rmssd/100,HRV_sd1sd2ratio,HRV_tinn],...
        'Parent',F.ha5);
    elseif showLFHF
        [hAx,hLine1,hLine2] = plotyy(x,HRV_hf,...
        [x,x,x,x,x],...
        [HRV_rr_med,HRV_rr_iqr,HRV_rmssd/100,HRV_sd1sd2ratio,HRV_lfhfratio],...
        'Parent',F.ha5);        
    else
        [hAx,hLine1,hLine2] = plotyy(x,HRV_hf,...
        [x,x,x,x],[HRV_rr_med,HRV_rr_iqr,HRV_rmssd/100,HRV_sd1sd2ratio],...
        'Parent',F.ha5);
    end

    hLine1.LineWidth = 1; hLine1.Color = [1 0 0];
    hLine2(1).LineWidth = 2; hLine2(2).LineWidth = 2;
    hAx(1).YColor = [1 0 0];
    hAx(1).YLim = [45 195];
    hAx(1).YTick = 75:30:165;
    hAx(2).YLim = [0 10];
    hAx(2).YTick = 2:2:8;
    hAx(2).YGrid = 'on';
    hold(F.ha5,'on') 

    %plot sampletext
    yl = get(F.ha5,'Ylim');
 
    for i=1:size(S,1) 
        plot([S.start(i) S.start(i) S.ende(i) S.ende(i)],...
            [0*diff(yl) .9*diff(yl) .9*diff(yl) 0*diff(yl)]+yl(1),...
            'Parent',F.ha5,'Clipping','on','Color',[1 0 .5])
        text(S.center(i),.8*diff(yl)+yl(1),S.name{i},'Parent',F.ha5,...
            'HorizontalAlignment','center','Clipping','on','Color',[1 0 .5])
    end
    
    Continuousstyle
    refresh_positionmarker_label  

    hold(F.ha5,'off') 
end


%% POSITIONMARKER
function refresh_positionmarker
    
    %Marker in Tachogram (global view)
    hold(F.ha3,'on')
    ch = get(F.ha3,'Children');
    if showFootprint
        delete(ch(1:end-2)); 
    else
        delete(ch(1:end-1)); 
    end
    yl = get(F.ha3,'Ylim');   
    xl = get(F.ha1,'Xlim');
    fill(xl([1 1 2 2])./(60*60*24),[yl yl(2) yl(1)],'w','Parent',F.ha3,'FaceColor',.5*[1 1 .3],'FaceAlpha',.2,'EdgeColor',.5*[1 1 .3])
    hold(F.ha3,'off')   
    
    %Marker in continuous HRV parameter view
    hold(F.ha5,'on')
    ch = get(F.ha5,'Children');
    delete(ch(1)); 
    yl = get(F.ha5,'Ylim');   
    xl = get(F.ha1,'Xlim');
    fill(xl([1 1 2 2])./(60*60*24),[yl yl(2) yl(1)],'w','Parent',F.ha5,'FaceColor',.5*[1 1 .3],'FaceAlpha',.2,'EdgeColor',.5*[1 1 .3])
    hold(F.ha5,'off')
end

function refresh_positionmarker_footprint
    if showFootprint
        str = get(F.htextFootprint_range,'String');
        pos = strfind(str,'..');
        if isempty(pos)
            pos = strfind(str,':');
            xl = [str2double(str(1:min(pos)-1)) str2double(str(max(pos)+1:end))];   
        else
            xl =  24*60*60*[datenum(datetime(str(1:min(pos)-1)))-floor(now) datenum(datetime(str(max(pos)+2:end)))-floor(now)];
        end
        
        %Marker in Tachogram (global view)
        hold(F.ha3,'on')
        ch = get(F.ha3,'Children');
        delete(ch(1:end-1)); 
        yl = get(F.ha3,'Ylim');   
        fill(xl([1 1 2 2])./(60*60*24),[yl yl(2) yl(1)],'w','Parent',F.ha3,'FaceColor',.5*[1 1 1],'FaceAlpha',.2,'EdgeAlpha',0)
        fill(xl([1 1 2 2])./(60*60*24),[yl yl(2) yl(1)],'w','Parent',F.ha3,'FaceColor',.5*[1 1 .3],'FaceAlpha',.2,'EdgeColor',.5*[1 1 .3])
        hold(F.ha3,'off')    
        
        %Marker in continuous HRV parameter view
        hold(F.ha5,'on')
        yl = get(F.ha5,'Ylim'); 
        fill(xl([1 1 2 2])./(60*60*24),[yl yl(2) yl(1)],'w','Parent',F.ha5,'FaceColor',.5*[1 1 1],'FaceAlpha',.2,'EdgeAlpha',0)
        fill(xl([1 1 2 2])./(60*60*24),[yl yl(2) yl(1)],'w','Parent',F.ha5,'FaceColor',.5*[1 1 .3],'FaceAlpha',.2,'EdgeColor',.5*[1 1 .3])
        hold(F.ha5,'off')    
    else 
        xl = get(F.ha1,'Xlim');
        
        hold(F.ha3,'on')
        ch = get(F.ha3,'Children');
        delete(ch(1:end-1)); 
        yl = get(F.ha3,'Ylim');   
        fill(xl([1 1 2 2])./(60*60*24),[yl yl(2) yl(1)],'w','Parent',F.ha3,'FaceColor',.5*[1 1 .3],'FaceAlpha',.2,'EdgeColor',.5*[1 1 .3])
        hold(F.ha3,'off')  
        
        hold(F.ha5,'on')
        yl = get(F.ha5,'Ylim'); 
        fill(xl([1 1 2 2])./(60*60*24),[yl yl(2) yl(1)],'w','Parent',F.ha5,'FaceColor',.5*[1 1 .3],'FaceAlpha',.2,'EdgeColor',.5*[1 1 .3])
        hold(F.ha5,'off') 
    end 
end

function refresh_positionmarker_label
    ch = get(F.ha5,'Children');
    delete(ch(1:end-2)); 

    if ~isempty(label_lim)
        hold(F.ha5,'on')
        yl = get(F.ha5,'Ylim'); yl = yl+[-.2 .2].*diff(yl);
        for i=1:size(label_lim,1)
            fill(label_lim(i,[1 1 2 2])./(60*60*24),[yl yl(2) yl(1)],'w','Parent',F.ha5,'FaceColor',.5*[1 .3 1],'FaceAlpha',.2,'EdgeColor','w','EdgeAlpha',0)
            text(mean(label_lim(i,:))/(60*60*24),180-20*mod(sum(label_lim(:,1)<label_lim(i,1)),2),label_names{i},'Parent',F.ha5,'HorizontalAlignment','center','Clipping','on')  
        end
        hold(F.ha5,'off') 
    end

    refresh_positionmarker_footprint  
end


%% Table of HRV Measures
function update_table
    update_table_global
    update_table_local
    update_table_footprint
end

function update_table_global
    [HRV_global_rrHRV_median,HRV_global_rrHRV_iqr,HRV_global_rrHRV_shift] = HRV.rrHRV(RR,0);
    HRV_global_meanrr = HRV.nanmean(RR);
    HRV_global_sdnn = HRV.SDNN(RR,0);
    HRV_global_rmssd = HRV.RMSSD(RR,0);
    HRV_global_pnn50 = HRV.pNN50(RR,0);        
    [HRV_global_tri,HRV_global_tinn] = HRV.triangular_val(RR,0);
    [HRV_global_sd1,HRV_global_sd2,HRV_global_sd1sd2ratio] = HRV.returnmap_val(RR,0);
    [HRV_global_lf,HRV_global_hf,HRV_global_lfhfratio] = HRV.fft_val(RR,0,Fs);

    set(F.htextGlobal_rrHRV_median,'String',num2str(HRV_global_rrHRV_median,'%1.2f'))
    set(F.htextGlobal_rrHRV_iqr,'String',num2str(HRV_global_rrHRV_iqr,'%1.2f'))
    set(F.htextGlobal_rrHRV_shift,'String',['(' num2str(HRV_global_rrHRV_shift(1),'%+1.2f') ',' num2str(HRV_global_rrHRV_shift(2),'%+1.2f') ')'])
    set(F.htextGlobal_meanrr,'String',[num2str(1000*HRV_global_meanrr,'%1.0f') ' | ' num2str(60/HRV_global_meanrr,'%3.0f')])
    set(F.htextGlobal_sdnn,'String',num2str(1000*HRV_global_sdnn,'%1.1f'))
    set(F.htextGlobal_rmssd,'String',num2str(1000*HRV_global_rmssd,'%1.1f'))
    set(F.htextGlobal_pnn50,'String',num2str(100*HRV_global_pnn50,'%2.1f'))
    set(F.htextGlobal_tri,'String',num2str(HRV_global_tri,'%1.1f'))
    set(F.htextGlobal_tinn,'String',num2str(1000*HRV_global_tinn,'%1.0f'))
    set(F.htextGlobal_sd1sd2,'String',[num2str(1000*HRV_global_sd1,'%1.1f') ' | ' num2str(1000*HRV_global_sd2,'%1.1f')])
    set(F.htextGlobal_sd1sd2ratio,'String',num2str(HRV_global_sd1sd2ratio,'%1.2f'))
    set(F.htextGlobal_lfhf,'String',[num2str(HRV_global_lf,'%2.1f') ' | ' num2str(HRV_global_hf,'%2.1f')])
    set(F.htextGlobal_lfhfratio,'String',num2str(HRV_global_lfhfratio,'%1.2f'))     
end 

function update_table_local
    [HRV_local_rrHRV_median,HRV_local_rrHRV_iqr,HRV_local_rrHRV_shift] = HRV.rrHRV(RR_loc,0);
    HRV_local_meanrr = HRV.nanmean(RR_loc);
    HRV_local_sdnn = HRV.SDNN(RR_loc,0);
    HRV_local_rmssd = HRV.RMSSD(RR_loc,0);
    HRV_local_pnn50 = HRV.pNN50(RR_loc,0);        
    [HRV_local_tri,HRV_local_tinn] = HRV.triangular_val(RR_loc,0);
    [HRV_local_sd1,HRV_local_sd2,HRV_local_sd1sd2ratio] = HRV.returnmap_val(RR_loc,0);
    [HRV_local_lf,HRV_local_hf,HRV_local_lfhfratio] = HRV.fft_val(RR_loc,0,Fs);

    set(F.htextLocal_rrHRV_median,'String',num2str(HRV_local_rrHRV_median,'%1.2f'))
    set(F.htextLocal_rrHRV_iqr,'String',num2str(HRV_local_rrHRV_iqr,'%1.2f'))
    set(F.htextLocal_rrHRV_shift,'String',['(' num2str(HRV_local_rrHRV_shift(1),'%+1.2f') ',' num2str(HRV_local_rrHRV_shift(2),'%+1.2f') ')'])
    set(F.htextLocal_meanrr,'String',[num2str(1000*HRV_local_meanrr,'%1.0f') ' | ' num2str(60/HRV_local_meanrr,'%3.0f')])
    set(F.htextLocal_sdnn,'String',num2str(1000*HRV_local_sdnn,'%1.1f'))
    set(F.htextLocal_rmssd,'String',num2str(1000*HRV_local_rmssd,'%1.1f'))
    set(F.htextLocal_pnn50,'String',num2str(100*HRV_local_pnn50,'%2.1f'))
    set(F.htextLocal_tri,'String',num2str(HRV_local_tri,'%1.1f'))
    set(F.htextLocal_tinn,'String',num2str(1000*HRV_local_tinn,'%1.0f'))
    set(F.htextLocal_sd1sd2,'String',[num2str(1000*HRV_local_sd1,'%1.1f') ' | ' num2str(1000*HRV_local_sd2,'%1.1f')])
    set(F.htextLocal_sd1sd2ratio,'String',num2str(HRV_local_sd1sd2ratio,'%1.2f'))
    set(F.htextLocal_lfhf,'String',[num2str(HRV_local_lf,'%2.1f') ' | ' num2str(HRV_local_hf,'%2.1f')])
    set(F.htextLocal_lfhfratio,'String',num2str(HRV_local_lfhfratio,'%1.2f')) 
    
    set(F.htextLocal_range,'String',get(F.heditLimits,'String'))
    set(F.htextLocal_label,'String',get(F.heditLabel,'String'))
end    
    
function update_table_footprint  
    if showFootprint
        [HRV_footprint_rrHRV_median,HRV_footprint_rrHRV_iqr,HRV_footprint_rrHRV_shift] = HRV.rrHRV(fp_RR,0);
        HRV_footprint_meanrr = HRV.nanmean(fp_RR);
        HRV_footprint_sdnn = HRV.SDNN(fp_RR,0);
        HRV_footprint_rmssd = HRV.RMSSD(fp_RR,0);
        HRV_footprint_pnn50 = HRV.pNN50(fp_RR,0);        
        [HRV_footprint_tri,HRV_footprint_tinn] = HRV.triangular_val(fp_RR,0);
        [HRV_footprint_sd1,HRV_footprint_sd2,HRV_footprint_sd1sd2ratio] = HRV.returnmap_val(fp_RR,0);
        [HRV_footprint_lf,HRV_footprint_hf,HRV_footprint_lfhfratio] = HRV.fft_val(fp_RR,0,Fs);

        set(F.htextFootprint_rrHRV_median,'String',num2str(HRV_footprint_rrHRV_median,'%1.2f'))
        set(F.htextFootprint_rrHRV_iqr,'String',num2str(HRV_footprint_rrHRV_iqr,'%1.2f'))
        set(F.htextFootprint_rrHRV_shift,'String',['(' num2str(HRV_footprint_rrHRV_shift(1),'%+1.2f') ',' num2str(HRV_footprint_rrHRV_shift(2),'%+1.2f') ')'])
        set(F.htextFootprint_meanrr,'String',[num2str(1000*HRV_footprint_meanrr,'%1.0f') ' | ' num2str(60/HRV_footprint_meanrr,'%3.0f')])
        set(F.htextFootprint_sdnn,'String',num2str(1000*HRV_footprint_sdnn,'%1.1f'))
        set(F.htextFootprint_rmssd,'String',num2str(1000*HRV_footprint_rmssd,'%1.1f'))
        set(F.htextFootprint_pnn50,'String',num2str(100*HRV_footprint_pnn50,'%1.1f'))
        set(F.htextFootprint_tri,'String',num2str(HRV_footprint_tri,'%1.1f'))
        set(F.htextFootprint_tinn,'String',num2str(1000*HRV_footprint_tinn,'%1.0f'))
        set(F.htextFootprint_sd1sd2,'String',[num2str(1000*HRV_footprint_sd1,'%1.1f') ' | ' num2str(1000*HRV_footprint_sd2,'%1.1f')])
        set(F.htextFootprint_sd1sd2ratio,'String',num2str(HRV_footprint_sd1sd2ratio,'%1.2f'))
        set(F.htextFootprint_lfhf,'String',[num2str(HRV_footprint_lf,'%2.1f') ' |' num2str(HRV_footprint_hf,'%2.1f')])
        set(F.htextFootprint_lfhfratio,'String',num2str(HRV_footprint_lfhfratio,'%1.2f'))     
    else
        set(F.htextFootprint_rrHRV_median,'String','')
        set(F.htextFootprint_rrHRV_iqr,'String','')
        set(F.htextFootprint_rrHRV_shift,'String','')
        set(F.htextFootprint_meanrr,'String','')
        set(F.htextFootprint_sdnn,'String','')
        set(F.htextFootprint_rmssd,'String','')
        set(F.htextFootprint_pnn50,'String','')
        set(F.htextFootprint_tri,'String','')
        set(F.htextFootprint_tinn,'String','')
        set(F.htextFootprint_sd1sd2,'String','')
        set(F.htextFootprint_sd1sd2ratio,'String','')
        set(F.htextFootprint_lfhf,'String','')
        set(F.htextFootprint_lfhfratio,'String','')
        
        set(F.htextFootprint_range,'String','')
        set(F.htextFootprint_label,'String','')
    end
end

%% Labeling
function refresh_labeling
    xl = get(F.ha1,'Xlim');
    if ~isempty(label_lim)
        pos = find(label_lim(:,1)==xl(1) & label_lim(:,2)==xl(2));
        if isempty(pos)
            set(F.heditLabel,'String','');
        else
            set(F.heditLabel,'String',label_names{pos});
        end
    end
end


%% Style
function RMstyle_rr
    RMzoom = [.125 .225 1 2];
    set(F.ha2,'Box','on','Xgrid','on','Ygrid','on')
    set(F.ha2,'Xlim',100*RMzoom(RMzoomlevel+1)*[-1 1],'Ylim',100*RMzoom(RMzoomlevel+1)*[-1 1])
    ylabel(F.ha2,'rr_{i} in %')
    xlabel(F.ha2,'rr_{i-1} in %')
    title(F.ha2,'Local Return Map')
end

function RMstyle_RR
    set(F.ha2,'Box','on','Xgrid','on','Ygrid','on')

    xl = get(F.ha2,'XLim'); yl = get(F.ha2,'YLim');
    xmin = floor((min(xl(1),yl(1))-.02)/.05)*.05;
    xmax = ceil((max(xl(2),yl(2))+.02)/.05)*.05;
    set(F.ha2,'Xlim',[xmin xmax],'Ylim',[xmin xmax])
    
    ylabel(F.ha2,'RR_{i} in sec')
    xlabel(F.ha2,'RR_{i-1} in sec')
    title(F.ha2,'Local Return Map')
end

function PDFstyle
    set(F.ha2b,'Box','on','Xtick',5:5:20,'XtickLabel',{'','','',''},'Xgrid','on','Ytick',[])
    set(F.ha2b,'Xlim',[0 25],'Ylim',[0 .25])
end

function Tachogramstyle
    set(F.ha3,'Box','on','Xgrid','on','Ygrid','on')
    axis(F.ha3,[0 max(Ann)/Fs .9*min(RR) min([1.1*max(RR) 2.5])])
    ylabel(F.ha3,'sec')
    xlabel(F.ha3,'time')
    title(F.ha3,'RR Tachogram')
    
    if Tachogramtype
        axis(F.ha3,[get(F.ha1,'XLim')/(60*60*24) .9*min(RR) min([1.1*max(RR) 2.5])])        
        xt = get(F.ha1,'XTick')/(60*60*24);
        xtl = get(F.ha1,'XTickLabel');
        set(F.ha3,'XTick',xt(1:2:length(xt)));
        set(F.ha3,'XTickLabel',xtl(1:2:length(xtl)));
    else
        axis(F.ha3,[0 max(Ann)/Fs .9*min(RR) min([1.1*max(RR) 2.5])])
        datetick(F.ha3)
        xt = get(F.ha3,'XTick');
        xtl = get(F.ha3,'XTickLabel'); 
        if size(xt,2)>5
            t_steps = ceil(size(xt,2)/5);
            set(F.ha3,'XTick',xt(t_steps:t_steps:size(xt,2)));
            set(F.ha3,'XTickLabel',xtl(t_steps:t_steps:size(xt,2),:));
        end
    end
end

function Spectrumstyle
    title(F.ha4,'Spectrum of RR Tachogram')
    xlabel(F.ha4,'Frequency (Hz)')
    set(F.ha4,'Box','on','Xgrid','on')
    set(F.ha4,'Xlim',[0 .5],'YTick',[],'XTick',[.04 .15 .4],...
        'XTickLabel',{'','0.15','0.4'})
end

function Continuousstyle
    yl = get(F.ha5,'Ylim');
    set(F.ha5,'Box','on','Ygrid','on')
    title(F.ha5,'Segmentwise HRV analysis')
    %xlabel(F.ha5,'sec')
    ylabel(F.ha5,'bpm')
    
    leg = {'HF','rrMedian','rrIQR','RMSSD','SD1/SD2'};
    if showTINN
        leg = [leg,'TINN'];
    end
    if showLFHF
        leg = [leg,'LF/HF'];
    end
    cont_legend = legend(F.ha5,leg,...
        'Location','northeastoutside','Box','off',...
        'Units','normalized','FontUnits','normalized');
% ,'SDNN','SDSD','pNN50'
    legendpos = get(cont_legend,'Position');
    patch([0 Ann(min(2+MeasuresNum,numel(Ann)))/(Fs*24*60*60) Ann(min(2+MeasuresNum,numel(Ann)))/(Fs*24*60*60) 0],[yl(1) yl yl(2)],...
        'red','FaceColor','interp',...
        'FaceVertexCData',[1 0 0; 1 1 1; 1 1 1; 1 0 0],...
        'EdgeColor','none','FaceAlpha',.5,'Parent',F.ha5) 
    
    linkaxes([hAx(1),hAx(2)],'x')  
    datetick(F.ha5)
    xlim(F.ha5,[0 max(Ann)/(Fs*60*60*24)])    
    xt = get(F.ha5,'XTick');
    xtl = get(F.ha5,'XTickLabel'); 
    if size(xt,2)>5
        t_steps = ceil(size(xt,2)/10);
        set(F.ha5,'XTick',xt(t_steps:t_steps:size(xt,2)));
        set(F.ha5,'XTickLabel',xtl(t_steps:t_steps:size(xt,2),:));
    end
    
%     set(F.ha5,'XTick',get(F.ha3,'XTick'));
%     set(F.ha5,'XTickLabel',get(F.ha3,'XTickLabel'));
    set(F.ha5,'Position',[.05 .15 .59 .65])
end

function Poincarestyle
    set(F.ha6,'Box','on','Xgrid','on','Ygrid','on')
    axis(F.ha6,[.9*min(RR) min([1.1*max(RR) 2.5]) .9*min(RR) min([1.1*max(RR) 2.5])])
    ylabel(F.ha6,'RR_{i}')
    %xlabel(F.ha6,'RR_{i-1}')
    title(F.ha6,'Global Return map')
end


%% Close Request
function my_closereq(hObject, eventdata, handles)
    if fopen([AppPath filesep 'never'])==-1
        if always
            selection = 'Always';
        else
            selection = questdlg('Do you want to save the settings?','Save settings','Yes','No','Always','Yes');
        end

        switch selection 
            case {'Yes','Always'}
                save_settings
                fileID = fopen([AppPath filesep 'HRV_settings.m'],'w');
                fprintf(fileID,['FileName = ''' FileName ''';\n']);
                fprintf(fileID,'PathName = ''');
                fprintf(fileID,'%s',get(F.heditFolder,'String'));
                fprintf(fileID,[filesep ''';\n']);
                if strcmp(selection,'Yes')
                    fprintf(fileID,'always = false;\n'); 
                else
                    fprintf(fileID,'always = true;\n');                
                end
                fprintf(fileID,['Position = ' mat2str(get(F.fh,'Position')) ';\n']);        
                fclose(fileID);
            case 'No'
%             case 'Never'
%                 fileID = fopen([AppPath filesep 'never'],'w');   
%                 fclose(fileID);
            otherwise
        end
    end
    delete(gcf)
end

function save_settings(hObject, eventdata, handles)

    fileID = fopen([get(F.heditFolder,'String') 'settings_' FileName(1:end-4) '.m'],'w');
    fprintf(fileID,['%% HRVTool settings for ' FileName(1:end-4) '\n\n']);
    fprintf(fileID,['% HRVTool_version = ' num2str(HRVTool_version,'%1.2f') ';\n\n']);

    fprintf(fileID,['my_title' '={''' my_title{1} '''};\n']);
    fprintf(fileID,['showIntervals' '=' mat2str(showIntervals) ';\n']);
    fprintf(fileID,['showProportions' '=' mat2str(showProportions) ';\n']);
    fprintf(fileID,['showFootprint' '=' mat2str(showFootprint) ';\n']);
    fprintf(fileID,['showPDF' '=' mat2str(showPDF) ';\n']);
    fprintf(fileID,['RMtype' '=' mat2str(RMtype) ';\n']);
    fprintf(fileID,['RMnumbers' '=' mat2str(RMnumbers) ';\n']);
    fprintf(fileID,['RMmarkersize' '=' mat2str(RMmarkersize) ';\n']);
    fprintf(fileID,['RMlinetype' '=' mat2str(RMlinetype) ';\n']);
    fprintf(fileID,['RMzoomlevel' '=' mat2str(RMzoomlevel) ';\n']);    
    fprintf(fileID,['Tachogramtype' '=' mat2str(Tachogramtype) ';\n']);
    fprintf(fileID,['showTINN' '=' mat2str(showTINN) ';\n']);
    fprintf(fileID,['showLFHF' '=' mat2str(showLFHF) ';\n']);
    fprintf(fileID,['vis' '= ' mat2str(vis) ';\n']);
    fprintf(fileID,['MeasuresNum' '=' mat2str(MeasuresNum) ';\n']);
    fprintf(fileID,['Overlap' '=' mat2str(Overlap) ';\n']);
%     fprintf(fileID,['HfNum' '=' mat2str(HfNum) ';\n']);
    fprintf(fileID,['speed' '=' mat2str(speed) ';\n']);

    fprintf(fileID,['LocalRange' '= ''' get(F.htextLocal_range,'String') ''';\n']);
    fprintf(fileID,['FootprintRange' '= ''' get(F.htextFootprint_range,'String') ''';\n\n']);

    fprintf(fileID,['my_artifacts' '= ' mat2str(my_artifacts) ';\n']);
    
    if size(label_names,1)>0
        fprintf(fileID,['label_lim' '= ' mat2str(label_lim) ';\n']);
        fprintf(fileID,['label_names' '= {''' strjoin(label_names,''',''') '''};\n']);
    end
    
    fclose(fileID);
end
    
function create_HRV_settings

    fileID = fopen([AppPath filesep 'HRV_settings.m'],'w');
    fprintf(fileID,'FileName = ''14121501.hrm'';\n');
    fprintf(fileID,'PathName = ''');
    fprintf(fileID,'%s',[AppPath filesep 'data' filesep]);
    fprintf(fileID,''';\n');
    fprintf(fileID,'always = false;\n');
    fclose(fileID);
    
    message = {['HRVTool v' num2str(HRVTool_version,'%01.2f')],'Analyzing Heart Rate Variability','',...
'The user interface is made for all people who are interested in HRV, as well as scientists.',...
'This is your first use with this version. Please help to improve this application!','',...
'If there is something misunderstanding, not working or missing please correspond to marcus.vollmer@uni-greifswald.de. Your bug reports and issues are welcome.','',...
'This work and all supported files and functions are licensed under the terms of the MIT License (MIT).',...
'Copyright (c) 2015-2017 Marcus Vollmer','',HRVTool_version_date};

    msgbox(message,'HRVTool','custom',importdata('logo.png'));
end

end
