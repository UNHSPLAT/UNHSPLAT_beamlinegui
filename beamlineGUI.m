classdef beamlineGUI < handle
    %BEAMLINEGUI Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        Hardware
        TestSequence double
        TestDate string
        DataDir string
        TestOperator string
        GasType string
        AcquisitionType string
        hFigure
        hStatusGrp
        hFileMenu
        hSequenceText
        hSequenceEdit
        hDateText
        hDateEdit
        hOperatorText
        hOperatorEdit
        OperatorList cell = {'Jonathan Bower','Daniel Abel','Skylar Vogler','Colin van Ysseldyk','Philip Valek','Nathan Schwadron','Zack Smith','David Heirtzler'}
        hGasText
        hGasEdit
        GasList cell = {'Air','Argon','Nitrogen','Helium','Deuterium','Oxygen','Magic gas'}
        hAcquisitionText
        hAcquisitionEdit
        AcquisitionList cell = {'Faraday cup vs ExB sweep'}
        hRunBtn
    end
    
    methods
        function obj = beamlineGUI
            %BEAMLINEGUI Construct an instance of this class
            %   Detailed explanation goes here

            obj.genTestSequence;

%             obj.gatherHardware;

            obj.createGUI;

        end

    end

    methods (Access = private)

        function genTestSequence(obj)

            obj.TestSequence = round(now*1e6);
            obj.TestDate = datestr(obj.TestSequence/1e6,'mmm dd, yyyy HH:MM:SS');
            obj.DataDir = fullfile("C:\data",num2str(obj.TestSequence));
            if ~exist(obj.DataDir,'dir')
                mkdir(obj.DataDir);
            end

        end
        
        function gatherHardware(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            obj.Hardware = initializeInstruments;
        end

        function createGUI(obj)

            obj.hFigure = figure('MenuBar','none',...
                'ToolBar','none',...
                'Resize','off',...
                'Position',[100,100,900,480],...
                'NumberTitle','off',...
                'Name','Beamline GUI');

            obj.hStatusGrp = uipanel(obj.hFigure,...
                'Title','Beamline Status',...
                'FontWeight','bold',...
                'FontSize',12,...
                'Units','pixels',...
                'Position',[40,40,480,420]);

            obj.hFileMenu = uimenu(obj.hFigure,'Text','File');
            set(obj.hFigure,'DockControls','off');

            xmid = 700;
            xgap = 8;
            ystart = 400;
            ypos = ystart;
            ysize = 22;
            ygap = 20;
            xtextsize = 160;
            xeditsize = 180;

            obj.hSequenceText = uicontrol(obj.hFigure,'Style','text',...
                'Position',[xmid-xtextsize-xgap/2,ypos,xtextsize,ysize],...
                'String','Test Sequence:',...
                'FontSize',12,...
                'FontWeight','bold',...
                'HorizontalAlignment','right');

            obj.hSequenceEdit = uicontrol(obj.hFigure,'Style','text',...
                'Position',[xmid+xgap/2,ypos,xeditsize,ysize],...
                'String',num2str(obj.TestSequence),...
                'FontSize',12,...
                'FontWeight','bold',...
                'HorizontalAlignment','left');

            ypos = ypos-ysize-ygap;

            obj.hDateText = uicontrol(obj.hFigure,'Style','text',...
                'Position',[xmid-xtextsize-xgap/2,ypos,xtextsize,ysize],...
                'String','Test Date:',...
                'FontSize',12,...
                'FontWeight','bold',...
                'HorizontalAlignment','right');

            obj.hDateEdit = uicontrol(obj.hFigure,'Style','text',...
                'Position',[xmid+xgap/2,ypos,xeditsize,ysize],...
                'String',obj.TestDate,...
                'FontSize',12,...
                'FontWeight','bold',...
                'HorizontalAlignment','left');
            
            ypos = ypos-ysize-ygap*2;

            obj.hOperatorText = uicontrol(obj.hFigure,'Style','text',...
                'Position',[xmid-xtextsize-xgap/2,ypos,xtextsize,ysize],...
                'String','Test Operator:',...
                'FontSize',12,...
                'FontWeight','bold',...
                'HorizontalAlignment','right');

            obj.hOperatorEdit = uicontrol(obj.hFigure,'Style','popupmenu',...
                'Position',[xmid+xgap/2,ypos,xeditsize,ysize],...
                'String',[{''},obj.OperatorList],...
                'FontSize',11,...
                'HorizontalAlignment','left',...
                'Callback',@obj.operatorCallback);

            ypos = ypos-ysize-ygap;

            obj.hGasText = uicontrol(obj.hFigure,'Style','text',...
                'Position',[xmid-xtextsize-xgap/2,ypos,xtextsize,ysize],...
                'String','Gas Type:',...
                'FontSize',12,...
                'FontWeight','bold',...
                'HorizontalAlignment','right');

            obj.hGasEdit = uicontrol(obj.hFigure,'Style','popupmenu',...
                'Position',[xmid+xgap/2,ypos,xeditsize,ysize],...
                'String',[{''},obj.GasList],...
                'FontSize',11,...
                'HorizontalAlignment','left',...
                'Callback',@obj.gasCallback);

            ypos = ypos-ysize-ygap*2;

            obj.hAcquisitionText = uicontrol(obj.hFigure,'Style','text',...
                'Position',[xmid-xtextsize-xgap/2,ypos,xtextsize,ysize],...
                'String','Acquisition Type:',...
                'FontSize',12,...
                'FontWeight','bold',...
                'HorizontalAlignment','right');

            obj.hAcquisitionEdit = uicontrol(obj.hFigure,'Style','popupmenu',...
                'Position',[xmid+xgap/2,ypos,xeditsize,ysize],...
                'String',[{''},obj.AcquisitionList],...
                'FontSize',11,...
                'HorizontalAlignment','left',...
                'Callback',@obj.acquisitionCallback);
            
            ysize = 66;

            obj.hRunBtn = uicontrol(obj.hFigure,'Style','pushbutton',...
                'Position',[xmid-xtextsize-xgap/2,40,xtextsize+xgap+xeditsize,ysize],...
                'String','RUN TEST',...
                'FontSize',16,...
                'FontWeight','bold',...
                'HorizontalAlignment','center',...
                'Callback',@obj.runTestCallback);


        end

        function operatorCallback(obj,src,~)

            obj.popupBlankDelete(src);
            
            if ~strcmp(src.String{src.Value},"")
                obj.TestOperator = src.String{src.Value};
            end

        end

        function gasCallback(obj,src,~)

            obj.popupBlankDelete(src);

            if ~strcmp(src.String{src.Value},"")
                obj.GasType = src.String{src.Value};
            end

        end

        function acquisitionCallback(obj,src,~)

            obj.popupBlankDelete(src);

            if ~strcmp(src.String{src.Value},"")
                obj.AcquisitionType = src.String{src.Value};
            end

        end

        function runTestCallback(obj,~,~)

            if isempty(obj.TestOperator)
                errordlg('A test operator must be selected before proceeding!','Don''t be lazy!');
                return
            end

            if isempty(obj.GasType)
                errordlg('A gas type must be selected before proceeding!','Don''t be lazy!');
                return
            end

            if isempty(obj.AcquisitionType)
                errordlg('An acquisition type must be selected before proceeding!','Don''t be lazy!');
                return
            end

            obj.genTestSequence;

            set(obj.hSequenceEdit,'String',num2str(obj.TestSequence));
            set(obj.hDateEdit,'String',obj.TestDate);

            acqPath = which(strrep(obj.AcquisitionType,' ',''));
            tokes = regexp(acqPath,'\\','split');
            fcnStr = tokes{end}(1:end-2);
            hFcn = str2func(fcnStr);
            hFcn(obj);
            
        end

    end

    methods (Static, Access = private)

        function popupBlankDelete(src)

            if isempty(src.String{1})
                if src.Value ~= 1
                    oldVal = src.Value;
                    src.String = src.String(2:end);
                    src.Value = oldVal-1;
                else
                    return
                end
            end

        end

    end

end

