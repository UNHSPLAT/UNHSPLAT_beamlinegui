classdef beamlineGUI < handle
    %BEAMLINEGUI - Defines a GUI used to interface with the Peabody Scientific beamline in lab 145
    
    properties
        Hardware % Object handle array to contain all hardware connected to beamline PC
        Monitors % Object handle array to contain all hardware connected to beamline PC
        TestSequence double % Unique test sequence identifier number
        TestDate string % Test date derived from TestSequence
        DataDir string % Data directory derived from TestSequence
        TestOperator string % Test operator string identifier
        GasType string % Gas type string identifier
        AcquisitionType string % Acquisition type string identifier
        hTimer % Handle to timer used to update beamline status read fields
        
        hFigure % Handle to GUI figure
        hStatusGrp % Handle to beamline status uicontrol group
        hTestGrp %
        hHWConnStatusGrp%
        hHWConnBtn%

        hFileMenu % Handle to file top menu dropdown
        hEditMenu % Handle to edit top menu dropdown
        hCopyTS % Handle to copy test sequence menu button
        hSequenceText % Handle to test sequence label
        hSequenceEdit % Handle to test sequence field
        hDateText % Handle to test date label
        hDateEdit % Handle to test date field
        
        hOperatorText % Handle to test operator label
        hOperatorEdit % Handle to test operator popupmenu
        OperatorList cell = {'Jonathan Bower','Daniel Abel','Skylar Vogler','Colin van Ysseldyk','Philip Valek','Nathan Schwadron','Zack Smith','David Heirtzler'} % Test operators available for selection
        
        hGasText % Handle to gas type label
        hGasEdit % Handle to gas type popupmenu
        GasList cell = {'Air','Argon','Nitrogen','Helium','Deuterium','Oxygen','Magic gas'} % Gas types available for selection
        
        hAcquisitionText % Handle to acquisition type label
        hAcquisitionEdit % Handle to acquisition type popupmenu
        AcquisitionList cell = {'Faraday cup sweep','Beamline Monitor'} % Acquisition types available for selection
        
        hRunBtn % Handle to run test button
    end

    properties (SetObservable)
        LastRead struct % Last readings of beamline timer
    end
    
    methods
        function obj = beamlineGUI
            %BEAMLINEGUI Construct an instance of this class

            % Make user confirm control power on
            % uiwait(msgbox('Confirm that control power to high voltage rack is turned on.','Control Power Check'));

            % Generate a test sequence, test date, and data directory
            obj.genTestSequence;

            % Gather and populate required hardware
            obj.gatherHardware;
            % obj.Hardware = struct2cell(setupInstruments)

            % Create GUI components
            obj.createGUI;

            % Create and start beamline status update timer
            obj.createTimer;

        end

        function readings = updateReadings(obj,~,~,fname)
            %UPDATEREADINGS Read and update all beamline status reading fields

            % Gather readings
            if isempty(obj.LastRead)
                obj.LastRead = struct;
            end

            %Read the stuff from the hardware
            readList = structfun(@(x)x.read(),obj.Monitors,'UniformOutput',false);

            %Share the monitor values with the last reading variable 
            fields = fieldnames(obj.Monitors);
            for i = 1:numel(fields)
                lab = fields{i};
                val = obj.Monitors.(fields{i}).lastRead;
                setfield(obj.LastRead,lab,val);
                %
                set(obj.Monitors.(lab).guiHand.statusGrpRead,...
                        'String',sprintf(obj.Monitors.(lab).formatSpec,val));
            end
            obj.LastRead.T = now;

            readings = obj.LastRead;

            if ~exist('fname','var')
                fname = fullfile(obj.DataDir,['readings_',num2str(round(now*1e6)),'.mat']);
            end
            save(fname,'readings');

        end

        function delete(obj)
            %DELETE Handle class destructor to stop timer and close figure when obj is deleted

            % Stop timer if running
            if strcmp(obj.hTimer.Running,'on')
                stop(obj.hTimer);
            end

            % Delete figure
            if isvalid(obj.hFigure)
                delete(obj.hFigure);
            end

        end

    end

    methods (Access = private)

        function genTestSequence(obj)
            %GENTESTSEQUENCE Generates a test sequence, test date, and data directory and populates respective obj properties
            
            obj.TestSequence = round(now*1e6);
            obj.TestDate = datestr(obj.TestSequence/1e6,'mmm dd, yyyy HH:MM:SS');
            if ~isempty(obj.AcquisitionType)
                obj.DataDir = fullfile(getenv("USERPROFILE"),"data",strrep(obj.AcquisitionType,' ',''),num2str(obj.TestSequence));
            else
                obj.DataDir = fullfile(getenv("USERPROFILE"),"data","General",num2str(obj.TestSequence));
            end
            if ~exist(obj.DataDir,'dir')
                mkdir(obj.DataDir);
            end

        end
        
        function gatherHardware(obj)
            obj.Hardware = setupInstruments();
            obj.Monitors = setupMonitors(obj.Hardware);
            %GATHERHARDWARE Detect, instantiate, and configure required hardware objects, set hardware tags, and populate respective obj properties
            
            % Auto-detect hardware
            % obj.Hardware = initializeInstruments;

            % % Connect serial port hardware
            % obj.Hardware(end+1) = leyboldCenter2("ASRL7::INSTR");
            % obj.Hardware(end).Tag = "Gas,Rough";
            % obj.Hardware(end+1) = leyboldGraphix3("ASRL8::INSTR");
            % obj.Hardware(end).Tag = "Beamline,Chamber";

            % % Configure picoammeter
            % hFaraday = obj.Hardware(strcmpi([obj.Hardware.Type],'Picoammeter')&strcmpi([obj.Hardware.ModelNum],'6485'));
            % hFaraday.Tag = "Faraday";
            % hFaraday.devRW(':SYST:ZCH OFF');
            % dataOut = strtrim(hFaraday.devRW(':SYST:ZCH?'));
            % while ~strcmp(dataOut,'0')
            %     warning('beamlineGUI:keithleyNonresponsive','Keithley not listening! Zcheck did not shut off as expected...');
            %     hFaraday.devRW(':SYST:ZCH OFF');
            %     dataOut = strtrim(hFaraday.devRW(':SYST:ZCH?'));
            % end
            % hFaraday.devRW('ARM:COUN 1');
            % dataOut = strtrim(hFaraday.devRW('ARM:COUN?'));
            % while ~strcmp(dataOut,'1')
            %     warning('beamlineGUI:keithleyNonresponsive','Keithley not listening! Arm count did not set to 1 as expected...');
            %     hFaraday.devRW('ARM:COUN 1');
            %     dataOut = strtrim(hFaraday.devRW('ARM:COUN?'));
            % end
            % hFaraday.devRW('FORM:ELEM READ');
            % dataOut = strtrim(hFaraday.devRW('FORM:ELEM?'));
            % while ~strcmp(dataOut,'READ')
            %     warning('beamlineGUI:keithleyNonresponsive','Keithley not listening! Output format not set to ''READ'' as expected...');
            %     hFaraday.devRW('FORM:ELEM READ');
            %     dataOut = strtrim(hFaraday.devRW('FORM:ELEM?'));
            % end
            % hFaraday.devRW(':SYST:LOC');
            
            % % Set Exbn power supply to 0V and set tag
            % hExbn = obj.Hardware(strcmpi([obj.Hardware.ModelNum],'PS350')&strcmpi([obj.Hardware.Address],'GPIB0::14::INSTR'));
            % hExbn.setVSet(0);
            % hExbn.Tag = "Exbn";

            % % Set Exbp power supply to 0V and set tag
            % hExbp = obj.Hardware(strcmpi([obj.Hardware.ModelNum],'PS350')&strcmpi([obj.Hardware.Address],'GPIB0::15::INSTR'));
            % hExbp.setVSet(0);
            % hExbp.Tag = "Exbp";

            % % Set ESA power supply to 0V and set tag
            % hEsa = obj.Hardware(strcmpi([obj.Hardware.ModelNum],'PS350')&strcmpi([obj.Hardware.Address],'GPIB0::16::INSTR'));
            % hEsa.setVSet(0);
            % hEsa.Tag = "Esa";

            % % Set defl power supply to 0V and set tag
            % hDefl = obj.Hardware(strcmpi([obj.Hardware.ModelNum],'PS350')&strcmpi([obj.Hardware.Address],'GPIB0::17::INSTR'));
            % hDefl.setVSet(0);
            % hDefl.Tag = "Defl";

            % % Set y-steer power supply to 0V and set tag
            % hYsteer = obj.Hardware(strcmpi([obj.Hardware.ModelNum],'PS350')&strcmpi([obj.Hardware.Address],'GPIB0::18::INSTR'));
            % hYsteer.setVSet(0);
            % hYsteer.Tag = "Ysteer";

            % % Set mass flow power supply tag
            % hMass = obj.Hardware(strcmpi([obj.Hardware.ModelNum],'E36313A')&strcmpi([obj.Hardware.Address],'GPIB0::5::INSTR'));
            % hMass.Tag = "Mass";

            % % Set multimeter tag and configure route
            % hDMM = obj.Hardware(strcmpi([obj.Hardware.Type],'Multimeter')&strcmpi([obj.Hardware.ModelNum],'DAQ6510'));
            % if length(hDMM)~=1
            %     error('beamlineGUI:deviceNotFound','Device not found! Device with specified properties not found...');
            % end
            % hDMM.Tag = "Extraction,Einzel,Mass";
            % hDMM.devRW('SENS:FUNC "VOLT", (@101:103)');
            % hDMM.devRW('SENS:VOLT:INP MOHM10, (@101:103)');
            % hDMM.devRW('SENS:VOLT:NPLC 1, (@101:103)');
            % hDMM.devRW('ROUT:SCAN:CRE (@101:103)');

        end

        function createGUI(obj)
            %CREATEGUI Create beamline GUI components

            %define relative posiiton so we only need to change one number when adding/removing buttons
            yBorderBuffer = 30 ;
            ypanelBuffer = 20;
            xBorderBuffer = 30;
            xpanelBuffer = 20;

            % Create figure
            obj.hFigure = figure('MenuBar','none',...
                'ToolBar','none',...
                'Resize','off',...
                'Position',[0,0,1200,700],...
                'NumberTitle','off',...
                'Name','Beamline GUI',...
                'DeleteFcn',@obj.closeGUI);

            %===================================================================================
            % Create instrument connection status uicontrol group

            % Set positions for components
            ysize = 22;
            ygap = 6;
            ystart = ypanelBuffer;
            ypos = ystart;
            xgap = 15;
            xstart = 10;
            colSize = [180];

            obj.hHWConnStatusGrp = uipanel(obj.hFigure,...
                'Title','Hardware Conectivity',...
                'FontWeight','bold',...
                'FontSize',12,...
                'Units','pixels',...
                'Position',[xBorderBuffer,yBorderBuffer,sum(colSize)+xgap*numel(colSize),10]);
            
            function x = guiHWConnStatusGrpSet(x)    
                colInd = 1;
                xColStart = xstart;
                button = uicontrol(obj.hHWConnStatusGrp,'Style','radiobutton',...
                'Position',[xColStart,ypos,colSize(colInd),ysize],...
                'String',sprintf('%s',x.Tag),...
                'FontWeight','bold','Value',x.Connected);
                set(button,'enable','off');
                ypos = ypos+ysize+ygap;
            end

            structfun(@guiHWConnStatusGrpSet,obj.Hardware,'UniformOutput',false)

            colInd = 1;
            xColStart = xstart;
            obj.hHWConnBtn = uicontrol(obj.hHWConnStatusGrp,'Style','pushbutton',...
               'Position',[xColStart,ypos,colSize(colInd),ysize],...
               'String','Refresh',...
               'FontSize',12,...
               'FontWeight','bold',...
                'HorizontalAlignment','center',...
                'Callback',@obj.HwRefreshCallback);
            ypos = ypos+ysize+ygap;
            obj.hHWConnStatusGrp.Position(4) = ypos+yBorderBuffer;
            %===================================================================================
            % Create beamline status uicontrol group

            % Set positions for components
            ysize = 22;
            ygap = 6;
            ystart = ypanelBuffer;
            ypos = ystart;
            xgap = 15;
            xstart = 10;

            colSize = [180,140,40,60,60];

            obj.hStatusGrp = uipanel(obj.hFigure,...
                'Title','Beamline Status',...
                'FontWeight','bold',...
                'FontSize',12,...
                'Units','pixels',...
                'Position',[obj.hHWConnStatusGrp.Position(3)+xBorderBuffer*2,yBorderBuffer,sum(colSize)+xgap*numel(colSize),10]);

            function x = guiStatusGrpSet(x)    
                colInd = 1;
                xColStart = xstart;
                x.guiHand.statusGrpText=uicontrol(obj.hStatusGrp,'Style','text',...
                'Position',[xColStart,ypos,colSize(colInd),ysize],...
                'String',sprintf('%s [%s]',x.textLabel,x.unit),...
                'FontWeight','bold',...
                'FontSize',9,...
                'HorizontalAlignment','right');

                xColStart = sum(colSize(1:colInd))+xgap*(colInd);
                colInd = colInd+1;
                x.guiHand.statusGrpRead = uicontrol(obj.hStatusGrp,'Style','edit',...
                'Position',[xColStart,ypos,colSize(colInd),ysize],...
                'Enable','inactive',...
                'FontSize',9,...
                'HorizontalAlignment','right');

                if x.active

                    xColStart = sum(colSize(1:colInd))+xgap*(colInd);
                    colInd = colInd+1;
                    x.guiHand.statusGrpSetText = uicontrol(obj.hStatusGrp,'Style','text',...
                        'Position',[xColStart,ypos,colSize(colInd),ysize],...
                        'String',sprintf('set [%s]: ',x.unit),...
                        'FontSize',9,...
                        'HorizontalAlignment','right');
                
                    xColStart = sum(colSize(1:colInd))+xgap*(colInd);
                    colInd = colInd+1;
                    x.guiHand.statusGrpSetField = uicontrol(obj.hStatusGrp,'Style','edit',...
                        'Position',[xColStart,ypos,colSize(colInd),ysize],...
                        'FontSize',9,...
                        'HorizontalAlignment','right');

                    xColStart = sum(colSize(1:colInd))+xgap*(colInd);
                    colInd = colInd+1;
                    x.guiHand.statusGrpSetBtn = uicontrol(obj.hStatusGrp,'Style','pushbutton',...
                        'Position',[xColStart,ypos,colSize(colInd),ysize],...
                        'String','SET',...
                        'FontWeight','bold',...
                        'FontSize',9,...
                        'HorizontalAlignment','center',...
                        'Callback',@x.guiSetCallback);

                    xColStart = sum(colSize(1:colInd))+xgap*(colInd);
                end
                ypos = ypos+ysize+ygap;
                obj.hStatusGrp.Position(4) = ypos+yBorderBuffer;
            end
            
            structfun(@guiStatusGrpSet,obj.Monitors);

            %====================================================================================

            % Create file menu
            obj.hFileMenu = uimenu(obj.hFigure,'Text','File');

            % Create edit menu
            obj.hEditMenu = uimenu(obj.hFigure,'Text','Edit');

            % Create copy test sequence menu button
            obj.hCopyTS = uimenu(obj.hEditMenu,'Text','Copy Test Sequence',...
                'MenuSelectedFcn',@obj.copyTSCallback);

            % Turn off dock controls (defaults to on when first uimenu created)
            set(obj.hFigure,'DockControls','off');

            %====================================================================================
            %Test Panel group

            % Set positions for right-side GUI components
            ysize = 22;
            ygap = 20;
            ystart = ypanelBuffer;
            ypos = ystart;
            xgap = 15;
            xstart = 10;
            colSize = [160,180];
            
            xtextsize = 160;
            xeditsize = 180;
            
            obj.hTestGrp = uipanel(obj.hFigure,...
                'Title','Testing',...
                'FontWeight','bold',...
                'FontSize',12,...
                'Units','pixels',...
                'Position',[obj.hStatusGrp.Position(1)+obj.hStatusGrp.Position(3)+xBorderBuffer,...
                                yBorderBuffer,sum(colSize)+xgap*numel(colSize),500]);

            % Create remaning GUI components
            %==============================================
            colInd = 1;
            xColStart = xstart;
            obj.hRunBtn = uicontrol(obj.hTestGrp,'Style','pushbutton',...
                'Position',[xColStart,ypos,colSize(colInd),ysize],...
                'String','RUN TEST',...
                'FontSize',16,...
                'FontWeight','bold',...
                'HorizontalAlignment','center',...
                'Callback',@obj.runTestCallback);
            ypos = ypos+ysize+ygap;
            %==============================================
            colInd = 1;
            xColStart = xstart;
            obj.hAcquisitionText = uicontrol(obj.hTestGrp,'Style','text',...
                'Position',[xColStart,ypos,colSize(colInd),ysize],...
                'String','Acquisition Type:',...
                'FontSize',12,...
                'FontWeight','bold',...
                'HorizontalAlignment','right');

            xColStart = sum(colSize(1:colInd))+xgap*(colInd);
            colInd = colInd+1;
            obj.hAcquisitionEdit = uicontrol(obj.hTestGrp,'Style','popupmenu',...
                'Position',[xColStart,ypos,colSize(colInd),ysize],...
                'String',[{''},obj.AcquisitionList],...
                'FontSize',11,...
                'HorizontalAlignment','left',...
                'Callback',@obj.acquisitionCallback);
            ypos = ypos+ysize+ygap;

            %==============================================
            colInd = 1;
            xColStart = xstart;
            obj.hGasText = uicontrol(obj.hTestGrp,'Style','text',...
                'Position',[xColStart,ypos,colSize(colInd),ysize],...
                'String','Gas Type:',...
                'FontSize',12,...
                'FontWeight','bold',...
                'HorizontalAlignment','right');
            xColStart = sum(colSize(1:colInd))+xgap*(colInd);
            colInd = colInd+1;
            obj.hGasEdit = uicontrol(obj.hTestGrp,'Style','popupmenu',...
                'Position',[xColStart,ypos,colSize(colInd),ysize],...
                'String',[{''},obj.GasList],...
                'FontSize',11,...
                'HorizontalAlignment','left',...
                'Callback',@obj.gasCallback);
            ypos = ypos+ysize+ygap;
            %==============================================
            colInd = 1;
            xColStart = xstart;
            obj.hSequenceText = uicontrol(obj.hTestGrp,'Style','text',...
                'Position',[xColStart,ypos,colSize(colInd),ysize],...
                'String','Test Sequence:',...
                'FontSize',12,...
                'FontWeight','bold',...
                'HorizontalAlignment','right');

            xColStart = sum(colSize(1:colInd))+xgap*(colInd);
            colInd = colInd+1;
            obj.hSequenceEdit = uicontrol(obj.hTestGrp,'Style','text',...
                'Position',[xColStart,ypos,colSize(colInd),ysize],...
                'String',num2str(obj.TestSequence),...
                'FontSize',12,...
                'FontWeight','bold',...
                'HorizontalAlignment','left');

            ypos = ypos+ysize+ygap;
            %==============================================
            colInd = 1;
            xColStart = xstart;
            obj.hDateText = uicontrol(obj.hTestGrp,'Style','text',...
                'Position',[xColStart,ypos,colSize(colInd),ysize],...
                'String','Test Date:',...
                'FontSize',12,...
                'FontWeight','bold',...
                'HorizontalAlignment','right');
            xColStart = sum(colSize(1:colInd))+xgap*(colInd);
            colInd = colInd+1;
            obj.hDateEdit = uicontrol(obj.hTestGrp,'Style','text',...
                'Position',[xColStart,ypos,colSize(colInd),ysize],...
                'String',obj.TestDate,...
                'FontSize',12,...
                'FontWeight','bold',...
                'HorizontalAlignment','left');
            ypos = ypos+ysize+ygap;
            %==============================================
            colInd = 1;
            xColStart = xstart;
            obj.hOperatorText = uicontrol(obj.hTestGrp,'Style','text',...
                'Position',[xColStart,ypos,colSize(colInd),ysize],...
                'String','Test Operator:',...
                'FontSize',12,...
                'FontWeight','bold',...
                'HorizontalAlignment','right');

            xColStart = sum(colSize(1:colInd))+xgap*(colInd);
            colInd = colInd+1;
            obj.hOperatorEdit = uicontrol(obj.hTestGrp,'Style','popupmenu',...
                'Position',[xColStart,ypos,colSize(colInd),ysize],...
                'String',[{''},obj.OperatorList],...
                'FontSize',11,...
                'HorizontalAlignment','left',...
                'Callback',@obj.operatorCallback);
            ypos = ypos+ysize+ygap;

            obj.hTestGrp.Position(4) = ypos+yBorderBuffer;
        end

        function createTimer(obj)
            %CREATETIMER Creates timer to periodically update readings from beamline hardware

            % Create timer object and populate respective obj property
            obj.hTimer = timer('Name','readTimer',...
                'Period',5,...
                'ExecutionMode','fixedDelay',...
                'TimerFcn',@obj.updateReadings,...
                'ErrorFcn',@obj.restartTimer);

            % Start timer
            start(obj.hTimer);

        end

        function restartTimer(obj,~,~)
            %RESTARTTIMER Restarts timer if error

            % Stop timer if still running
            if strcmp(obj.hTimer.Running,'on')
                stop(obj.hTimer);
            end

            % Restart timer
            start(obj.hTimer);

        end

        function copyTSCallback(obj,~,~)
            %COPYTSCALLBACK Copies test sequence to clipboard

            clipboard('copy',num2str(obj.TestSequence));

        end

        function operatorCallback(obj,src,~)
            %OPERATORCALLBACK Populate test operator obj property with user selected value
            
            % Delete blank popupmenu option
            obj.popupBlankDelete(src);
            
            % Populate obj property with user selection
            if ~strcmp(src.String{src.Value},"")
                obj.TestOperator = src.String{src.Value};
            end

        end

        function gasCallback(obj,src,~)
            %GASCALLBACK Populate gas type obj property with user selected value

            % Delete blank popupmenu option
            obj.popupBlankDelete(src);

            % Populate obj property with user selection
            if ~strcmp(src.String{src.Value},"")
                obj.GasType = src.String{src.Value};
            end

        end

        function acquisitionCallback(obj,src,~)
            %ACQUISITIONCALLBACK Populate acquisition type obj property with user selected value

            % Delete blank popupmenu option
            obj.popupBlankDelete(src);

            % Populate obj property with user selection
            if ~strcmp(src.String{src.Value},"")
                obj.AcquisitionType = src.String{src.Value};
            end

        end

        function runTestCallback(obj,~,~)
            %RUNTESTCALLBACK Check for required user input, generate new test sequence, and execute selected acquisition type

            % Throw error if test operator not selected
            if isempty(obj.TestOperator)
                errordlg('A test operator must be selected before proceeding!','Don''t be lazy!');
                return
            end

            % Throw error if gas type not selected
            if isempty(obj.GasType)
                errordlg('A gas type must be selected before proceeding!','Don''t be lazy!');
                return
            end

            % Throw error if acquisition type not selected
            if isempty(obj.AcquisitionType)
                errordlg('An acquisition type must be selected before proceeding!','Don''t be lazy!');
                return
            end

            % Generate new test sequence, test date, and data directory
            obj.genTestSequence;

            % Update GUI test sequence and test date fields
            set(obj.hSequenceEdit,'String',num2str(obj.TestSequence));
            set(obj.hDateEdit,'String',obj.TestDate);

            % Find test acquisition class, instantiate, and execute
            acqPath = which(strrep(obj.AcquisitionType,' ',''));
            tokes = regexp(acqPath,'\\','split');
            fcnStr = tokes{end}(1:end-2);
            hFcn = str2func(fcnStr);
            myAcq = hFcn(obj);
            myAcq.runSweep;
            
        end

        function HwRefreshCallback(obj,~,~)
            
            hwStats = obj.hHWConnStatusGrp.Children;
            devices = get_visadevlist();
            tags = fieldnames(obj.Hardware);
            for i = 1:numel(hwStats)
                nam = hwStats(i).String;
                if any(strcmp(tags,nam))
                    obj.Hardware.(nam).resourcelist = devices;
                    obj.Hardware.(nam).connectDevice();
                    set(hwStats(i),'Value',obj.Hardware.(nam).Connected)
                end
            end
        end

        function closeGUI(obj,~,~)
            %CLOSEGUI Stop timer and delete obj when figure is closed

            % Stop timer if running
            if strcmp(obj.hTimer.Running,'on')
                stop(obj.hTimer);
            end

            % Delete obj
            delete(obj);

        end

    end

    methods (Static, Access = private)

        function popupBlankDelete(src)
            %POPUPBLANKDELETE Deletes blank option of popupmenu if user selected another value

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

