classdef beamlineGUI < handle
    % TODO: 1 - Create method to set hardware tags
    %       2 - Develop pushbutton callback methods
    %       3 - Finish timer function that reads and populates all status fields
    %       4 - Comments!
    %BEAMLINEGUI - Defines a GUI used to interface with the Peabody Scientific beamline in lab 145
    
    properties
        Hardware % Object handle array to contain all hardware connected to beamline PC
        hExb % Handle to ExB HV power supply
        hEsa % Handle to ESA HV power supply
        hDefl % Handle to defl HV power supply
        hYsteer % Handle to y-steer HV power supply
        hMass % Handle to mass flow controller power supply
        TestSequence double % Unique test sequence identifier number
        TestDate string % Test date derived from TestSequence
        DataDir string % Data directory derived from TestSequence
        TestOperator string % Test operator string identifier
        GasType string % Gas type string identifier
        AcquisitionType string % Acquisition type string identifier
        hTimer % Handle to timer used to update beamline status read fields
        hFigure % Handle to GUI figure
        hStatusGrp % Handle to beamline status uicontrol group
        hExtractionText % Handle to extraction row label
        hExtractionReadText % Handle to extraction voltage reading label
        hExtractionReadField % Handle to extraction voltage reading field
        hEinzelText % Handle to einzel row label
        hEinzelReadText % Handle to einzel voltage reading label
        hEinzelReadField % Handle to einzel voltage reading field
        hExbText % Handle to ExB row label
        hExbReadText % Handle to ExB voltage reading label
        hExbReadField % Handle to ExB voltage reading field
        hExbSetText % Handle to ExB voltage setting label
        hExbSetField % Handle to ExB voltage setting field
        hExbSetBtn % Handle to ExB voltage setting button
        hEsaText % Handle to ESA row label
        hEsaReadText % Handle to ESA voltage reading label
        hEsaReadField % Handle to ESA voltage reading field
        hEsaSetText % Handle to ESA voltage setting label
        hEsaSetField % Handle to ESA voltage setting field
        hEsaSetBtn % Handle to ESA voltage setting button
        hDeflText % Handle to Defl row label
        hDeflReadText % Handle to Defl voltage reading label
        hDeflReadField % Handle to Defl voltage reading field
        hDeflSetText % Handle to Defl voltage setting label
        hDeflSetField % Handle to Defl voltage setting field
        hDeflSetBtn % Handle to Defl voltage setting button
        hYsteerText % Handle to y-steer row label
        hYsteerReadText % Handle to y-steer voltage reading label
        hYsteerReadField % Handle to y-steer voltage reading field
        hYsteerSetText % Handle to y-steer voltage setting label
        hYsteerSetField % Handle to y-steer voltage setting field
        hYsteerSetBtn % Handle to y-steer voltage setting button
        hFaradayText % Handle to faraday cup row label
        hFaradayReadText % Handle to faraday cup current reading label
        hFaradayReadField % Handle to faraday cup current reading field
        hMassText % Handle to mass flow row label
        hMassReadText % Handle to mass flow reading label
        hMassReadField % Handle to mass flow reading field
        hMassSetText % Handle to mass flow setting label
        hMassSetField % Handle to mass flow setting field
        hMassSetBtn % Handle to mass flow setting button
        hP1Text % Handle to pressure 1 row label
        hP1ReadText % Handle to pressure 1 reading label
        hP1ReadField % Handle to pressure 1 reading field
        hP2Text % Handle to pressure 2 row label
        hP2ReadText % Handle to pressure 2 reading label
        hP2ReadField % Handle to pressure 2 reading field
        hP3Text % Handle to pressure 3 row label
        hP3ReadText % Handle to pressure 3 reading label
        hP3ReadField % Handle to pressure 3 reading field
        hP4Text % Handle to pressure 4 row label
        hP4ReadText % Handle to pressure 4 reading label
        hP4ReadField % Handle to pressure 4 reading field
        hP5Text % Handle to pressure 5 row label
        hP5ReadText % Handle to pressure 5 reading label
        hP5ReadField % Handle to pressure 5 reading field
        hFileMenu % Handle to file top menu dropdown
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
        AcquisitionList cell = {'Faraday cup vs ExB sweep'} % Acquisition types available for selection
        hRunBtn % Handle to run test button
    end
    
    methods
        function obj = beamlineGUI
            %BEAMLINEGUI Construct an instance of this class

            % Generate a test sequence, test date, and data directory
            obj.genTestSequence;

            % Gather and populate required hardware
%             obj.gatherHardware;

            % Create GUI components
            obj.createGUI;

            % Create and start beamline status update timer
            obj.createTimer;

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
            obj.DataDir = fullfile(getenv("USERPROFILE"),"data",num2str(obj.TestSequence));
            if ~exist(obj.DataDir,'dir')
                mkdir(obj.DataDir);
            end

        end
        
        function gatherHardware(obj)
            %GATHERHARDWARE Detect and instantiate required hardware objects, set hardware tags, and populate respective obj properties
            
            % Auto-detect hardware
            obj.Hardware = initializeInstruments;

        end

        function createGUI(obj)
            %CREATEGUI Create beamline GUI components

            % Create figure
            obj.hFigure = figure('MenuBar','none',...
                'ToolBar','none',...
                'Resize','off',...
                'Position',[100,100,900,480],...
                'NumberTitle','off',...
                'Name','Beamline GUI',...
                'DeleteFcn',@obj.closeGUI);
            
            % Create beamline status uicontrol group
            obj.hStatusGrp = uipanel(obj.hFigure,...
                'Title','Beamline Status',...
                'FontWeight','bold',...
                'FontSize',12,...
                'Units','pixels',...
                'Position',[40,40,480,420]);
            
            % Set positions for components
            ysize = 22;
            ygap = 6;
            ystart = 360;
            ypos = ystart;
            xgap = 20;
            xstart = 10;
            xpos = xstart;
            xsize = 80;

            % Create beamline status components
            obj.hExtractionText = uicontrol(obj.hStatusGrp,'Style','text',...
                'Position',[xpos,ypos,xsize,ysize],...
                'String','Extraction',...
                'FontWeight','bold',...
                'FontSize',9,...
                'HorizontalAlignment','right');

            ypos = ypos-ysize-ygap;

            obj.hEinzelText = uicontrol(obj.hStatusGrp,'Style','text',...
                'Position',[xpos,ypos,xsize,ysize],...
                'String','Einzel',...
                'FontWeight','bold',...
                'FontSize',9,...
                'HorizontalAlignment','right');

            ypos = ypos-ysize-ygap;

            obj.hExbText = uicontrol(obj.hStatusGrp,'Style','text',...
                'Position',[xpos,ypos,xsize,ysize],...
                'String','ExB',...
                'FontWeight','bold',...
                'FontSize',9,...
                'HorizontalAlignment','right');

            ypos = ypos-ysize-ygap;

            obj.hEsaText = uicontrol(obj.hStatusGrp,'Style','text',...
                'Position',[xpos,ypos,xsize,ysize],...
                'String','ESA',...
                'FontWeight','bold',...
                'FontSize',9,...
                'HorizontalAlignment','right');

            ypos = ypos-ysize-ygap;

            obj.hDeflText = uicontrol(obj.hStatusGrp,'Style','text',...
                'Position',[xpos,ypos,xsize,ysize],...
                'String','Defl',...
                'FontWeight','bold',...
                'FontSize',9,...
                'HorizontalAlignment','right');

            ypos = ypos-ysize-ygap;

            obj.hYsteerText = uicontrol(obj.hStatusGrp,'Style','text',...
                'Position',[xpos,ypos,xsize,ysize],...
                'String','y-steer',...
                'FontWeight','bold',...
                'FontSize',9,...
                'HorizontalAlignment','right');

            ypos = ypos-ysize-ygap;

            obj.hFaradayText = uicontrol(obj.hStatusGrp,'Style','text',...
                'Position',[xpos,ypos,xsize,ysize],...
                'String','Faraday cup',...
                'FontWeight','bold',...
                'FontSize',9,...
                'HorizontalAlignment','right');

            ypos = ypos-ysize-ygap;

            obj.hMassText = uicontrol(obj.hStatusGrp,'Style','text',...
                'Position',[xpos,ypos,xsize,ysize],...
                'String','Mass flow',...
                'FontWeight','bold',...
                'FontSize',9,...
                'HorizontalAlignment','right');

            ypos = ypos-ysize-ygap;

            obj.hP1Text = uicontrol(obj.hStatusGrp,'Style','text',...
                'Position',[xpos,ypos,xsize,ysize],...
                'String','Pressure 1',...
                'FontWeight','bold',...
                'FontSize',9,...
                'HorizontalAlignment','right');

            ypos = ypos-ysize-ygap;

            obj.hP2Text = uicontrol(obj.hStatusGrp,'Style','text',...
                'Position',[xpos,ypos,xsize,ysize],...
                'String','Pressure 2',...
                'FontWeight','bold',...
                'FontSize',9,...
                'HorizontalAlignment','right');

            ypos = ypos-ysize-ygap;

            obj.hP3Text = uicontrol(obj.hStatusGrp,'Style','text',...
                'Position',[xpos,ypos,xsize,ysize],...
                'String','Pressure 3',...
                'FontWeight','bold',...
                'FontSize',9,...
                'HorizontalAlignment','right');

            ypos = ypos-ysize-ygap;

            obj.hP4Text = uicontrol(obj.hStatusGrp,'Style','text',...
                'Position',[xpos,ypos,xsize,ysize],...
                'String','Pressure 4',...
                'FontWeight','bold',...
                'FontSize',9,...
                'HorizontalAlignment','right');

            ypos = ypos-ysize-ygap;

            obj.hP5Text = uicontrol(obj.hStatusGrp,'Style','text',...
                'Position',[xpos,ypos,xsize,ysize],...
                'String','Pressure 5',...
                'FontWeight','bold',...
                'FontSize',9,...
                'HorizontalAlignment','right');

            ypos = ystart;
            xpos = xpos+xsize+xgap*1.5;
            xsize = 90;

            obj.hExtractionReadText = uicontrol(obj.hStatusGrp,'Style','text',...
                'Position',[xpos,ypos,xsize,ysize],...
                'String','Voltage [V]: ',...
                'FontSize',9,...
                'HorizontalAlignment','right');

            ypos = ypos-ysize-ygap;

            obj.hEinzelReadText = uicontrol(obj.hStatusGrp,'Style','text',...
                'Position',[xpos,ypos,xsize,ysize],...
                'String','Voltage [V]: ',...
                'FontSize',9,...
                'HorizontalAlignment','right');

            ypos = ypos-ysize-ygap;

            obj.hExbReadText = uicontrol(obj.hStatusGrp,'Style','text',...
                'Position',[xpos,ypos,xsize,ysize],...
                'String','Voltage [V]: ',...
                'FontSize',9,...
                'HorizontalAlignment','right');

            ypos = ypos-ysize-ygap;

            obj.hEsaReadText = uicontrol(obj.hStatusGrp,'Style','text',...
                'Position',[xpos,ypos,xsize,ysize],...
                'String','Voltage [V]: ',...
                'FontSize',9,...
                'HorizontalAlignment','right');

            ypos = ypos-ysize-ygap;

            obj.hDeflReadText = uicontrol(obj.hStatusGrp,'Style','text',...
                'Position',[xpos,ypos,xsize,ysize],...
                'String','Voltage [V]: ',...
                'FontSize',9,...
                'HorizontalAlignment','right');

            ypos = ypos-ysize-ygap;

            obj.hYsteerReadText = uicontrol(obj.hStatusGrp,'Style','text',...
                'Position',[xpos,ypos,xsize,ysize],...
                'String','Voltage [V]: ',...
                'FontSize',9,...
                'HorizontalAlignment','right');

            ypos = ypos-ysize-ygap;

            obj.hFaradayReadText = uicontrol(obj.hStatusGrp,'Style','text',...
                'Position',[xpos,ypos,xsize,ysize],...
                'String','Current [A]: ',...
                'FontSize',9,...
                'HorizontalAlignment','right');

            ypos = ypos-ysize-ygap;

            obj.hMassReadText = uicontrol(obj.hStatusGrp,'Style','text',...
                'Position',[xpos,ypos,xsize,ysize],...
                'String','Flow [sccm]: ',...
                'FontSize',9,...
                'HorizontalAlignment','right');

            ypos = ypos-ysize-ygap;

            obj.hP1ReadText = uicontrol(obj.hStatusGrp,'Style','text',...
                'Position',[xpos,ypos,xsize,ysize],...
                'String','Pressure [torr]: ',...
                'FontSize',9,...
                'HorizontalAlignment','right');

            ypos = ypos-ysize-ygap;

            obj.hP2ReadText = uicontrol(obj.hStatusGrp,'Style','text',...
                'Position',[xpos,ypos,xsize,ysize],...
                'String','Pressure [torr]: ',...
                'FontSize',9,...
                'HorizontalAlignment','right');

            ypos = ypos-ysize-ygap;

            obj.hP3ReadText = uicontrol(obj.hStatusGrp,'Style','text',...
                'Position',[xpos,ypos,xsize,ysize],...
                'String','Pressure [torr]: ',...
                'FontSize',9,...
                'HorizontalAlignment','right');

            ypos = ypos-ysize-ygap;

            obj.hP4ReadText = uicontrol(obj.hStatusGrp,'Style','text',...
                'Position',[xpos,ypos,xsize,ysize],...
                'String','Pressure [torr]: ',...
                'FontSize',9,...
                'HorizontalAlignment','right');

            ypos = ypos-ysize-ygap;

            obj.hP5ReadText = uicontrol(obj.hStatusGrp,'Style','text',...
                'Position',[xpos,ypos,xsize,ysize],...
                'String','Pressure [torr]: ',...
                'FontSize',9,...
                'HorizontalAlignment','right');

            ypos = ystart+2;
            xpos = xpos+xsize;
            xsize = 60;

            obj.hExtractionReadField = uicontrol(obj.hStatusGrp,'Style','edit',...
                'Position',[xpos,ypos,xsize,ysize],...
                'Enable','inactive',...
                'FontSize',9,...
                'HorizontalAlignment','right');

            ypos = ypos-ysize-ygap;

            obj.hEinzelReadField = uicontrol(obj.hStatusGrp,'Style','edit',...
                'Position',[xpos,ypos,xsize,ysize],...
                'Enable','inactive',...
                'FontSize',9,...
                'HorizontalAlignment','right');

            ypos = ypos-ysize-ygap;

            obj.hExbReadField = uicontrol(obj.hStatusGrp,'Style','edit',...
                'Position',[xpos,ypos,xsize,ysize],...
                'Enable','inactive',...
                'FontSize',9,...
                'HorizontalAlignment','right');

            ypos = ypos-ysize-ygap;

            obj.hEsaReadField = uicontrol(obj.hStatusGrp,'Style','edit',...
                'Position',[xpos,ypos,xsize,ysize],...
                'Enable','inactive',...
                'FontSize',9,...
                'HorizontalAlignment','right');

            ypos = ypos-ysize-ygap;

            obj.hDeflReadField = uicontrol(obj.hStatusGrp,'Style','edit',...
                'Position',[xpos,ypos,xsize,ysize],...
                'Enable','inactive',...
                'FontSize',9,...
                'HorizontalAlignment','right');

            ypos = ypos-ysize-ygap;

            obj.hYsteerReadField = uicontrol(obj.hStatusGrp,'Style','edit',...
                'Position',[xpos,ypos,xsize,ysize],...
                'Enable','inactive',...
                'FontSize',9,...
                'HorizontalAlignment','right');

            ypos = ypos-ysize-ygap;

            obj.hFaradayReadField = uicontrol(obj.hStatusGrp,'Style','edit',...
                'Position',[xpos,ypos,xsize,ysize],...
                'Enable','inactive',...
                'FontSize',9,...
                'HorizontalAlignment','right');

            ypos = ypos-ysize-ygap;

            obj.hMassReadField = uicontrol(obj.hStatusGrp,'Style','edit',...
                'Position',[xpos,ypos,xsize,ysize],...
                'Enable','inactive',...
                'FontSize',9,...
                'HorizontalAlignment','right');

            ypos = ypos-ysize-ygap;

            obj.hP1ReadField = uicontrol(obj.hStatusGrp,'Style','edit',...
                'Position',[xpos,ypos,xsize,ysize],...
                'Enable','inactive',...
                'FontSize',9,...
                'HorizontalAlignment','right');

            ypos = ypos-ysize-ygap;

            obj.hP2ReadField = uicontrol(obj.hStatusGrp,'Style','edit',...
                'Position',[xpos,ypos,xsize,ysize],...
                'Enable','inactive',...
                'FontSize',9,...
                'HorizontalAlignment','right');

            ypos = ypos-ysize-ygap;

            obj.hP3ReadField = uicontrol(obj.hStatusGrp,'Style','edit',...
                'Position',[xpos,ypos,xsize,ysize],...
                'Enable','inactive',...
                'FontSize',9,...
                'HorizontalAlignment','right');

            ypos = ypos-ysize-ygap;

            obj.hP4ReadField = uicontrol(obj.hStatusGrp,'Style','edit',...
                'Position',[xpos,ypos,xsize,ysize],...
                'Enable','inactive',...
                'FontSize',9,...
                'HorizontalAlignment','right');

            ypos = ypos-ysize-ygap;

            obj.hP5ReadField = uicontrol(obj.hStatusGrp,'Style','edit',...
                'Position',[xpos,ypos,xsize,ysize],...
                'Enable','inactive',...
                'FontSize',9,...
                'HorizontalAlignment','right');

            ypos = ystart-ysize*2-ygap*2;
            xpos = xpos+xsize+xgap;

            obj.hExbSetText = uicontrol(obj.hStatusGrp,'Style','text',...
                'Position',[xpos,ypos,xsize,ysize],...
                'String','Vset [V]: ',...
                'FontSize',9,...
                'HorizontalAlignment','right');

            ypos = ypos-ysize-ygap;

            obj.hEsaSetText = uicontrol(obj.hStatusGrp,'Style','text',...
                'Position',[xpos,ypos,xsize,ysize],...
                'String','Vset [V]: ',...
                'FontSize',9,...
                'HorizontalAlignment','right');

            ypos = ypos-ysize-ygap;

            obj.hDeflSetText = uicontrol(obj.hStatusGrp,'Style','text',...
                'Position',[xpos,ypos,xsize,ysize],...
                'String','Vset [V]: ',...
                'FontSize',9,...
                'HorizontalAlignment','right');

            ypos = ypos-ysize-ygap;

            obj.hYsteerSetText = uicontrol(obj.hStatusGrp,'Style','text',...
                'Position',[xpos,ypos,xsize,ysize],...
                'String','Vset [V]: ',...
                'FontSize',9,...
                'HorizontalAlignment','right');

            ypos = ypos-ysize*2-ygap*2;

            obj.hMassSetText = uicontrol(obj.hStatusGrp,'Style','text',...
                'Position',[xpos,ypos,xsize,ysize],...
                'String','Fset [%]: ',...
                'FontSize',9,...
                'HorizontalAlignment','right');

            ypos = ystart-ysize*2-ygap*2+2;
            xpos = xpos+xsize;

            obj.hExbSetField = uicontrol(obj.hStatusGrp,'Style','edit',...
                'Position',[xpos,ypos,xsize,ysize],...
                'FontSize',9,...
                'HorizontalAlignment','right');

            ypos = ypos-ysize-ygap;

            obj.hEsaSetField = uicontrol(obj.hStatusGrp,'Style','edit',...
                'Position',[xpos,ypos,xsize,ysize],...
                'FontSize',9,...
                'HorizontalAlignment','right');

            ypos = ypos-ysize-ygap;

            obj.hDeflSetField = uicontrol(obj.hStatusGrp,'Style','edit',...
                'Position',[xpos,ypos,xsize,ysize],...
                'FontSize',9,...
                'HorizontalAlignment','right');

            ypos = ypos-ysize-ygap;

            obj.hYsteerSetField = uicontrol(obj.hStatusGrp,'Style','edit',...
                'Position',[xpos,ypos,xsize,ysize],...
                'FontSize',9,...
                'HorizontalAlignment','right');

            ypos = ypos-ysize*2-ygap*2;

            obj.hMassSetField = uicontrol(obj.hStatusGrp,'Style','edit',...
                'Position',[xpos,ypos,xsize,ysize],...
                'FontSize',9,...
                'HorizontalAlignment','right');

            ypos = ystart-ysize*2-ygap*2+2;
            xpos = xpos+xsize+10;
            xsize = 50;

            obj.hExbSetBtn = uicontrol(obj.hStatusGrp,'Style','pushbutton',...
                'Position',[xpos,ypos,xsize,ysize],...
                'String','SET',...
                'FontWeight','bold',...
                'FontSize',9,...
                'HorizontalAlignment','center',...
                'Callback',@obj.exbBtnCallback);

            ypos = ypos-ysize-ygap;

            obj.hEsaSetBtn = uicontrol(obj.hStatusGrp,'Style','pushbutton',...
                'Position',[xpos,ypos,xsize,ysize],...
                'String','SET',...
                'FontWeight','bold',...
                'FontSize',9,...
                'HorizontalAlignment','center',...
                'Callback',@obj.esaBtnCallback);

            ypos = ypos-ysize-ygap;

            obj.hDeflSetBtn = uicontrol(obj.hStatusGrp,'Style','pushbutton',...
                'Position',[xpos,ypos,xsize,ysize],...
                'String','SET',...
                'FontWeight','bold',...
                'FontSize',9,...
                'HorizontalAlignment','center',...
                'Callback',@obj.deflBtnCallback);

            ypos = ypos-ysize-ygap;

            obj.hYsteerSetBtn = uicontrol(obj.hStatusGrp,'Style','pushbutton',...
                'Position',[xpos,ypos,xsize,ysize],...
                'String','SET',...
                'FontWeight','bold',...
                'FontSize',9,...
                'HorizontalAlignment','center',...
                'Callback',@obj.ysteerBtnCallback);

            ypos = ypos-ysize*2-ygap*2;

            obj.hMassSetBtn = uicontrol(obj.hStatusGrp,'Style','pushbutton',...
                'Position',[xpos,ypos,xsize,ysize],...
                'String','SET',...
                'FontWeight','bold',...
                'FontSize',9,...
                'HorizontalAlignment','center',...
                'Callback',@obj.massBtnCallback);

            % Create file menu
            obj.hFileMenu = uimenu(obj.hFigure,'Text','File');

            % Turn off dock controls (defaults to on when first uimenu created)
            set(obj.hFigure,'DockControls','off');

            % Set positions for right-side GUI components
            xmid = 700;
            xgap = 8;
            ystart = 400;
            ypos = ystart;
            ysize = 22;
            ygap = 20;
            xtextsize = 160;
            xeditsize = 180;
            
            % Create remaning GUI components
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
            xbuffer = 40;

            obj.hRunBtn = uicontrol(obj.hFigure,'Style','pushbutton',...
                'Position',[xmid-xtextsize+xbuffer/2,40,xtextsize+xeditsize-xbuffer,ysize],...
                'String','RUN TEST',...
                'FontSize',16,...
                'FontWeight','bold',...
                'HorizontalAlignment','center',...
                'Callback',@obj.runTestCallback);


        end

        function createTimer(obj)
            %CREATETIMER Creates timer to periodically update readings from beamline hardware

            % Create timer object and populate respective obj property
            obj.hTimer = timer('Name','readTimer',...
                'Period',5,...
                'ExecutionMode','fixedRate',...
                'TimerFcn',@obj.updateReadings);

            % Start timer
            start(obj.hTimer);

        end

        function exbBtnCallback(obj,~,~)

            setVal = str2double(obj.hExbSetField.String);

            if isnan(setVal)
                errordlg('A valid voltage value must be entered!','Invalid input!');
                set(obj.hExbSetField,'String','');
                return
            elseif setVal > obj.hExb.VMax || setVal < obj.hExb.VMin
                errordlg(['ExB voltage setpoint must be between ',num2str(obj.hExb.VMin),' and ',num2str(obj.hExb.VMax),' V!'],'Invalid input!');
                set(obj.hExbSetField,'String','');
                return
            end

            obj.hExb.setVSet(setVal);
            set(obj.hExbSetField,'String','');

        end

        function esaBtnCallback(obj,~,~)

            setVal = str2double(obj.hEsaSetField.String);

            if isnan(setVal)
                errordlg('A valid voltage value must be entered!','Invalid input!');
                set(obj.hEsaSetField,'String','');
                return
            elseif setVal > obj.hEsa.VMax || setVal < obj.hEsa.VMin
                errordlg(['ESA voltage setpoint must be between ',num2str(obj.hEsa.VMin),' and ',num2str(obj.hEsa.VMax),' V!'],'Invalid input!');
                set(obj.hEsaSetField,'String','');
                return
            end

            obj.hEsa.setVSet(setVal);
            set(obj.hEsaSetField,'String','');

        end

        function deflBtnCallback(obj,~,~)

            setVal = str2double(obj.hDeflSetField.String);

            if isnan(setVal)
                errordlg('A valid voltage value must be entered!','Invalid input!');
                set(obj.hDeflSetField,'String','');
                return
            elseif setVal > obj.hDefl.VMax || setVal < obj.hDefl.VMin
                errordlg(['Defl voltage setpoint must be between ',num2str(obj.hDefl.VMin),' and ',num2str(obj.hDefl.VMax),' V!'],'Invalid input!');
                set(obj.hDeflSetField,'String','');
                return
            end

            obj.hDefl.setVSet(setVal);
            set(obj.hDeflSetField,'String','');

        end

        function ysteerBtnCallback(obj,~,~)

            setVal = str2double(obj.hYsteerSetField.String);

            if isnan(setVal)
                errordlg('A valid voltage value must be entered!','Invalid input!');
                set(obj.hYsteerSetField,'String','');
                return
            elseif setVal > obj.hYsteer.VMax || setVal < obj.hYsteer.VMin
                errordlg(['y-steer voltage setpoint must be between ',num2str(obj.hYsteer.VMin),' and ',num2str(obj.hYsteer.VMax),' V!'],'Invalid input!');
                set(obj.hYsteerSetField,'String','');
                return
            end

            obj.hYsteer.setVSet(setVal);
            set(obj.hYsteerSetField,'String','');

        end

        function massBtnCallback(obj,~,~)

            setVal = str2double(obj.hMassSetField.String);

            if isnan(setVal)
                errordlg('A valid set value must be entered!','Invalid input!');
                set(obj.hMassSetField,'String','');
                return
            elseif setVal > 100 || setVal < 0
                errordlg('Mass flow setpoint must be between 0 and 100%!','Invalid input!');
                set(obj.hMassSetField,'String','');
                return
            end

            setVoltage = 5*setVal/100;

            obj.hMass.setVSet(setVoltage);
            set(obj.hMassSetField,'String','');

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

        function readings = updateReadings(obj,~,~)
            %UPDATEREADINGS Read and update all beamline status reading fields

            readings.Extraction = randi([0,9]);
            obj.hExtractionReadField.String = num2str(readings.Extraction);

            readings.Einzel = randi([0,9]);
            obj.hEinzelReadField.String = num2str(readings.Einzel);

            readings.Exb = randi([0,9]);
            obj.hExbReadField.String = num2str(readings.Exb);

            readings.Esa = randi([0,9]);
            obj.hEsaReadField.String = num2str(readings.Esa);

            readings.Defl = randi([0,9]);
            obj.hDeflReadField.String = num2str(readings.Defl);

            readings.Ysteer = randi([0,9]);
            obj.hYsteerReadField.String = num2str(readings.Ysteer);

            readings.Faraday = randi([0,9]);
            obj.hFaradayReadField.String = num2str(readings.Faraday);

            readings.Mass = randi([0,9]);
            obj.hMassReadField.String = num2str(readings.Mass);

            readings.P1 = randi([0,9]);
            obj.hP1ReadField.String = num2str(readings.P1);

            readings.P2 = randi([0,9]);
            obj.hP2ReadField.String = num2str(readings.P2);

            readings.P3 = randi([0,9]);
            obj.hP3ReadField.String = num2str(readings.P3);

            readings.P4 = randi([0,9]);
            obj.hP4ReadField.String = num2str(readings.P4);

            readings.P5 = randi([0,9]);
            obj.hP5ReadField.String = num2str(readings.P5);

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

