classdef beamlineGUI < handle
    %BEAMLINEGUI - Defines a GUI used to interface with the Peabody Scientific beamline in lab 145
    
    properties
        Hardware % Object handle array to contain all hardware connected to beamline PC
        TestSequence double % Unique test sequence identifier number
        TestDate string % Test date derived from TestSequence
        DataDir string % Data directory derived from TestSequence
        TestOperator string % Test operator string identifier
        GasType string % Gas type string identifier
        AcquisitionType string % Acquisition type string identifier
        hTimer % Handle to timer used to update beamline status read fields
        hFigure % Handle to GUI figure
        hAxes % Handle to bkg image axes
        hImage % Handle to bkg image
        hStatusGrp % Handle to beamline status uicontrol group
        hVset % Handle to voltage set group
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
        hEditMenu % Handle to edit top menu dropdown
        hCopyTS % Handle to copy test sequence menu button
        hSequenceText % Handle to test sequence label
        hSequenceEdit % Handle to test sequence field
        hDateText % Handle to test date label
        hDateEdit % Handle to test date field
        hOperatorText % Handle to test operator label
        hOperatorEdit % Handle to test operator popupmenu
        OperatorList cell = {'Jonathan Bower','Daniel Abel',...
            'Skylar Vogler','Colin van Ysseldyk',...
            'Philip Valek','Nathan Schwadron',...
            'Zack Smith','David Heirtzler',...
            'Ryan Murphy','Amanda Wester',...
            'Isabella Householder'} % Test operators available for selection
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
            uiwait(msgbox('Confirm that control power to high voltage rack is turned on.','Control Power Check'));

            % Generate a test sequence, test date, and data directory
            obj.genTestSequence;

            % Gather and populate required hardware
            %obj.gatherHardware;

            % Create GUI components
            obj.createGUI;

            % Create and start beamline status update timer
            %obj.createTimer;

        end

        function readings = updateReadings(obj,~,~,fname)
            %UPDATEREADINGS Read and update all beamline status reading fields

            % Gather readings
            if isempty(obj.LastRead)
                obj.LastRead = struct;
            end
            [extraction,einzel,mass] = obj.readDMM;
            obj.LastRead.VExtraction = extraction*4000;
            obj.LastRead.VEinzel = einzel*1000;
            obj.LastRead.VMass = mass;
            obj.LastRead.VExb = obj.readHVPS('Exb');
            obj.LastRead.VEsa = obj.readHVPS('Esa');
            obj.LastRead.VDefl = obj.readHVPS('Defl');
            obj.LastRead.VYsteer = obj.readHVPS('Ysteer');
            obj.LastRead.IFaraday = obj.readFaraday;
            obj.LastRead.PBeamline = obj.readPressureSensor('Beamline');
            obj.LastRead.PChamber = obj.readPressureSensor('Chamber');
            obj.LastRead.PGas = obj.readPressureSensor('Gas');
            obj.LastRead.PRough = obj.readPressureSensor('Rough');
            obj.LastRead.T = now;

            obj.hExtractionReadField.String = num2str(obj.LastRead.VExtraction,'%.1f');

            obj.hEinzelReadField.String = num2str(obj.LastRead.VEinzel,'%.1f');

            obj.hExbReadField.String = num2str(obj.LastRead.VExb,'%.1f');

            obj.hEsaReadField.String = num2str(obj.LastRead.VEsa,'%.1f');

            obj.hDeflReadField.String = num2str(obj.LastRead.VDefl,'%.1f');

            obj.hYsteerReadField.String = num2str(obj.LastRead.VYsteer,'%.1f');

            obj.hFaradayReadField.String = num2str(obj.LastRead.IFaraday,'%.2e');

            obj.hMassReadField.String = num2str(obj.LastRead.VMass,'%.3f');

            obj.hP1ReadField.String = num2str(obj.LastRead.PBeamline,'%.2e');

            obj.hP2ReadField.String = num2str(obj.LastRead.PChamber,'%.2e');

            obj.hP4ReadField.String = num2str(obj.LastRead.PGas,'%.2e');

            obj.hP5ReadField.String = num2str(obj.LastRead.PRough,'%.2e');

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
            %GATHERHARDWARE Detect, instantiate, and configure required hardware objects, set hardware tags, and populate respective obj properties
            
            % Auto-detect hardware
            obj.Hardware = initializeInstruments;

            % Connect serial port hardware
            obj.Hardware(end+1) = leyboldCenter2("ASRL7::INSTR");
            obj.Hardware(end).Tag = "Gas,Rough";
            obj.Hardware(end+1) = leyboldGraphix3("ASRL8::INSTR");
            obj.Hardware(end).Tag = "Beamline,Chamber";

            % Configure picoammeter
            hFaraday = obj.Hardware(strcmpi([obj.Hardware.Type],'Picoammeter')&strcmpi([obj.Hardware.ModelNum],'6485'));
            hFaraday.Tag = "Faraday";
            hFaraday.devRW(':SYST:ZCH OFF');
            dataOut = strtrim(hFaraday.devRW(':SYST:ZCH?'));
            while ~strcmp(dataOut,'0')
                warning('beamlineGUI:keithleyNonresponsive','Keithley not listening! Zcheck did not shut off as expected...');
                hFaraday.devRW(':SYST:ZCH OFF');
                dataOut = strtrim(hFaraday.devRW(':SYST:ZCH?'));
            end
            hFaraday.devRW('ARM:COUN 1');
            dataOut = strtrim(hFaraday.devRW('ARM:COUN?'));
            while ~strcmp(dataOut,'1')
                warning('beamlineGUI:keithleyNonresponsive','Keithley not listening! Arm count did not set to 1 as expected...');
                hFaraday.devRW('ARM:COUN 1');
                dataOut = strtrim(hFaraday.devRW('ARM:COUN?'));
            end
            hFaraday.devRW('FORM:ELEM READ');
            dataOut = strtrim(hFaraday.devRW('FORM:ELEM?'));
            while ~strcmp(dataOut,'READ')
                warning('beamlineGUI:keithleyNonresponsive','Keithley not listening! Output format not set to ''READ'' as expected...');
                hFaraday.devRW('FORM:ELEM READ');
                dataOut = strtrim(hFaraday.devRW('FORM:ELEM?'));
            end
            hFaraday.devRW(':SYST:LOC');
            
            % Set ExB power supply to 0V and set tag
            hExb = obj.Hardware(strcmpi([obj.Hardware.ModelNum],'PS350')&strcmpi([obj.Hardware.Address],'GPIB0::15::INSTR'));
            hExb.setVSet(0);
            hExb.Tag = "Exb";

            % Set ESA power supply to 0V and set tag
            hEsa = obj.Hardware(strcmpi([obj.Hardware.ModelNum],'PS350')&strcmpi([obj.Hardware.Address],'GPIB0::16::INSTR'));
            hEsa.setVSet(0);
            hEsa.Tag = "Esa";

            % Set defl power supply to 0V and set tag
            hDefl = obj.Hardware(strcmpi([obj.Hardware.ModelNum],'PS350')&strcmpi([obj.Hardware.Address],'GPIB0::17::INSTR'));
            hDefl.setVSet(0);
            hDefl.Tag = "Defl";

            % Set y-steer power supply to 0V and set tag
            hYsteer = obj.Hardware(strcmpi([obj.Hardware.ModelNum],'PS350')&strcmpi([obj.Hardware.Address],'GPIB0::18::INSTR'));
            hYsteer.setVSet(0);
            hYsteer.Tag = "Ysteer";

            % Set mass flow power supply tag
            hMass = obj.Hardware(strcmpi([obj.Hardware.ModelNum],'E36313A')&strcmpi([obj.Hardware.Address],'GPIB0::5::INSTR'));
            hMass.Tag = "Mass";

            % Set multimeter tag and configure route
            hDMM = obj.Hardware(strcmpi([obj.Hardware.Type],'Multimeter')&strcmpi([obj.Hardware.ModelNum],'DAQ6510'));
            if length(hDMM)~=1
                error('beamlineGUI:deviceNotFound','Device not found! Device with specified properties not found...');
            end
            hDMM.Tag = "Extraction,Einzel,Mass";
            hDMM.devRW('SENS:FUNC "VOLT", (@101:103)');
            hDMM.devRW('SENS:VOLT:INP MOHM10, (@101:103)');
            hDMM.devRW('SENS:VOLT:NPLC 1, (@101:103)');
            hDMM.devRW('ROUT:SCAN:CRE (@101:103)');

        end

        function createGUI(obj)
            %CREATEGUI Create beamline GUI components

            % GUI Background Image and Dimensions
            gui_bkg = imread('gui_bkg.png');
            gui_bkg_width = size(gui_bkg,1);
            gui_bkg_height = size(gui_bkg,2);   

            % GUI Dimensions
            gui_width = 1100;
            gui_height = 622;
            % Create figure
            obj.hFigure = figure('MenuBar','none',...
                'ToolBar','none',...
                'Resize','off',...
                'Position',[40,40,gui_width,gui_height],...
                'NumberTitle','off',...
                'Color','#f5f5f5',...
                'Name','Beamline GUI',...
                'DeleteFcn',@obj.closeGUI);

            % Sets bkg image to beamline + chamber layout
            % axes function, [left bottom width height]
% %             obj.hAxes = axes('units', 'normalized',...
% %                 'position', [0 0 1 1]);
% %             uistack(obj.hAxes, 'bottom');
% %             obj.hImage = imagesc(gui_bkg);
% %             colormap gray
% %             set(obj.hAxes,'handlevisibility','off', ...
% %                'visible','off')
            obj.hAxes = axes('units','pixels',...
                'position',[320,190,gui_width-320,gui_height-190]);
            uistack(obj.hAxes,'bottom');
            system_layout = imread('system_layout.png');
            obj.hImage = imagesc(system_layout);
            colormap gray;
            set(obj.hAxes,'handlevisibility','off',...
                'visible','off');
            
            % Create beamline status uicontrol group
            obj.hStatusGrp = uipanel(obj.hFigure,...
                'Title','Beamline Status',...
                'FontWeight','bold',...
                'BackgroundColor','#f5f5f5',...
                'FontSize',12,...
                'Units','pixels',...
                'Position',[20,200,300,355]);
            
            % Set positions for components
            ysize = 22;
            ygap = 16;
            ystart = 290;
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
                'BackgroundColor','#f5f5f5',...
                'FontSize',9,...
                'HorizontalAlignment','right');

            ypos = ypos-ysize-ygap;

            % Text label positions

            obj.hEinzelText = uicontrol(obj.hStatusGrp,'Style','text',...
                'Position',[xpos,ypos,xsize,ysize],...
                'String','Einzel',...
                'FontWeight','bold',...
                'FontSize',9,...
                'BackgroundColor','#f5f5f5',...
                'HorizontalAlignment','right');

            ypos = ypos-ysize-ygap;

            obj.hFaradayText = uicontrol(obj.hStatusGrp,'Style','text',...
                'Position',[xpos,ypos,xsize,ysize],...
                'String','Faraday cup',...
                'FontWeight','bold',...
                'BackgroundColor','#f5f5f5',...
                'FontSize',9,...
                'HorizontalAlignment','right');

            ypos = ypos-ysize-ygap;

            obj.hP1Text = uicontrol(obj.hStatusGrp,'Style','text',...
                'Position',[xpos,ypos,xsize,ysize],...
                'String','Beamline',...
                'BackgroundColor','#f5f5f5',...
                'FontWeight','bold',...
                'FontSize',9,...
                'HorizontalAlignment','right');

            ypos = ypos-ysize-ygap;

            obj.hP2Text = uicontrol(obj.hStatusGrp,'Style','text',...
                'Position',[xpos,ypos,xsize,ysize],...
                'String','Chamber',...
                'FontWeight','bold',...
                'FontSize',9,...
                'BackgroundColor','#f5f5f5',...
                'HorizontalAlignment','right');

            ypos = ypos-ysize-ygap;

            obj.hP3Text = uicontrol(obj.hStatusGrp,'Style','text',...
                'Position',[xpos,ypos,xsize,ysize],...
                'String','Pressure 3',...
                'FontWeight','bold',...
                'BackgroundColor','#f5f5f5',...
                'FontSize',9,...
                'HorizontalAlignment','right');

            ypos = ypos-ysize-ygap;

            obj.hP4Text = uicontrol(obj.hStatusGrp,'Style','text',...
                'Position',[xpos,ypos,xsize,ysize],...
                'String','Gas Line',...
                'FontWeight','bold',...
                'BackgroundColor','#f5f5f5',...
                'FontSize',9,...
                'HorizontalAlignment','right');

            ypos = ypos-ysize-ygap;

            obj.hP5Text = uicontrol(obj.hStatusGrp,'Style','text',...
                'Position',[xpos,ypos,xsize,ysize],...
                'String','Rough Vac',...
                'BackgroundColor','#f5f5f5',...
                'FontWeight','bold',...
                'FontSize',9,...
                'HorizontalAlignment','right');

            ypos = ystart;
            xpos = xpos+xsize+xgap*1.5;
            xsize = 90;

            % Read text positions

            obj.hExtractionReadText = uicontrol(obj.hStatusGrp,'Style','text',...
                'Position',[xpos,ypos,xsize,ysize],...
                'String','Voltage [V]: ',...
                'FontSize',9,...
                'BackgroundColor','#f5f5f5',...
                'HorizontalAlignment','right');

            ypos = ypos-ysize-ygap;

            obj.hEinzelReadText = uicontrol(obj.hStatusGrp,'Style','text',...
                'Position',[xpos,ypos,xsize,ysize],...
                'String','Voltage [V]: ',...
                'FontSize',9,...
                'BackgroundColor','#f5f5f5',...
                'HorizontalAlignment','right');

            ypos = ypos-ysize-ygap;

            obj.hFaradayReadText = uicontrol(obj.hStatusGrp,'Style','text',...
                'Position',[xpos,ypos,xsize,ysize],...
                'String','Current [A]: ',...
                'FontSize',9,...
                'BackgroundColor','#f5f5f5',...
                'HorizontalAlignment','right');

            ypos = ypos-ysize-ygap;

            obj.hP1ReadText = uicontrol(obj.hStatusGrp,'Style','text',...
                'Position',[xpos,ypos,xsize,ysize],...
                'String','Pressure [torr]: ',...
                'FontSize',9,...
                'BackgroundColor','#f5f5f5',...
                'HorizontalAlignment','right');

            ypos = ypos-ysize-ygap;

            obj.hP2ReadText = uicontrol(obj.hStatusGrp,'Style','text',...
                'Position',[xpos,ypos,xsize,ysize],...
                'String','Pressure [torr]: ',...
                'FontSize',9,...
                'BackgroundColor','#f5f5f5',...
                'HorizontalAlignment','right');

            ypos = ypos-ysize-ygap;

            obj.hP3ReadText = uicontrol(obj.hStatusGrp,'Style','text',...
                'Position',[xpos,ypos,xsize,ysize],...
                'String','Pressure [torr]: ',...
                'FontSize',9,...
                'BackgroundColor','#f5f5f5',...
                'HorizontalAlignment','right');

            ypos = ypos-ysize-ygap;

            obj.hP4ReadText = uicontrol(obj.hStatusGrp,'Style','text',...
                'Position',[xpos,ypos,xsize,ysize],...
                'String','Pressure [torr]: ',...
                'FontSize',9,...
                'BackgroundColor','#f5f5f5',...
                'HorizontalAlignment','right');

            ypos = ypos-ysize-ygap;

            obj.hP5ReadText = uicontrol(obj.hStatusGrp,'Style','text',...
                'Position',[xpos,ypos,xsize,ysize],...
                'String','Pressure [torr]: ',...
                'FontSize',9,...
                'BackgroundColor','#f5f5f5',...
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
            
            obj.hFaradayReadField = uicontrol(obj.hStatusGrp,'Style','edit',...
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

            % Pressures on diagram

            % Beamline
            obj.hP1Text = uicontrol(obj.hFigure,'Style','text',...
                'Position',[614,522,70,15],...
                'String','Beamline',...
                'FontWeight','bold',...
                'BackgroundColor','#f5f5f5',...
                'FontSize',11,...
                'HorizontalAlignment','right');
            obj.hP1Text = uicontrol(obj.hFigure,'Style','text',...
                'Position',[650,500,xsize,15],...
                'BackgroundColor','#f5f5f5',...
                'String','[torr]',...
                'FontWeight','normal',...
                'FontSize',9,...
                'HorizontalAlignment','right');
            obj.hP1ReadField = uicontrol(obj.hFigure,'Style','edit',...
                'Position',[622,495,xsize,ysize],...
                'Enable','inactive',...
                'FontSize',9,...
                'HorizontalAlignment','right');

            % Chamber
            obj.hP2Text = uicontrol(obj.hFigure,'Style','text',...
                'Position',[915,532,70,15],...
                'String','Chamber',...
                'FontWeight','bold',...
                'FontSize',11,...
                'BackgroundColor','#f5f5f5',...
                'HorizontalAlignment','right');
            obj.hP2Text = uicontrol(obj.hFigure,'Style','text',...
                'Position',[951,510,xsize,15],...
                'String','[torr]',...
                'FontWeight','normal',...
                'BackgroundColor','#f5f5f5',...
                'FontSize',9,...
                'HorizontalAlignment','right');
            obj.hP2ReadField = uicontrol(obj.hFigure,'Style','edit',...
                'Position',[923,505,xsize,ysize],...
                'Enable','inactive',...
                'FontSize',9,...
                'HorizontalAlignment','right');

            % Roughline
            obj.hP5Text = uicontrol(obj.hFigure,'Style','text',...
                'Position',[585,320,80,19],...
                'String','Rough Vac',...
                'FontWeight','bold',...
                'FontSize',11,...
                'BackgroundColor','#f5f5f5',...
                'HorizontalAlignment','right');
            obj.hP5Text = uicontrol(obj.hFigure,'Style','text',...
                'Position',[614,300,70,15],...
                'String','[torr]',...
                'FontWeight','normal',...
                'BackgroundColor','#f5f5f5',...
                'FontSize',9,...
                'HorizontalAlignment','right');
            obj.hP5ReadField = uicontrol(obj.hFigure,'Style','edit',...
                'Position',[596,295,xsize,ysize],...
                'Enable','inactive',...
                'FontSize',9,...
                'HorizontalAlignment','right');
            

            % Set initial position components for hVset
            xstart_vset = 0;
            ystart_vset = 130;
            xpos_vset = xstart_vset;
            ypos_vset = ystart_vset;
            xstep_vset = 0;
            ystep_vset = 0;
            xsize_vset = 80;
            ysize_vset = 22;

            % Create Voltage Set uicontrol group
            obj.hVset = uipanel(obj.hFigure,...
                'Title', 'Voltage Set',...
                'FontWeight','bold',...
                'BackgroundColor','#f5f5f5',...
                'FontSize',12,...
                'Units', 'pixels',...
                'Position',[20,5,520,185]);

            % Set label positions
            ystep_vset = 30;

            obj.hDeflText = uicontrol(obj.hVset,'Style','text',...
                'Position',[xpos_vset,ypos_vset,xsize_vset,ysize_vset],...
                'String','Defl',...
                'FontWeight','bold',...
                'BackgroundColor','#f5f5f5',...
                'FontSize',9,...
                'HorizontalAlignment','right');

            ypos_vset = ypos_vset-ystep_vset;

            obj.hExbText = uicontrol(obj.hVset,'Style','text',...
                'Position',[xpos_vset,ypos_vset,xsize_vset,ysize_vset],...
                'String','ExB',...
                'FontWeight','bold',...
                'BackgroundColor','#f5f5f5',...
                'FontSize',9,...
                'HorizontalAlignment','right');

            ypos_vset = ypos_vset-ystep_vset;

            obj.hYsteerText = uicontrol(obj.hVset,'Style','text',...
                'Position',[xpos_vset,ypos_vset,xsize_vset,ysize_vset],...
                'String','y-steer',...
                'FontWeight','bold',...
                'BackgroundColor','#f5f5f5',...
                'FontSize',9,...
                'HorizontalAlignment','right');

            ypos_vset = ypos_vset-ystep_vset;

            obj.hEsaText = uicontrol(obj.hVset,'Style','text',...
                'Position',[xpos_vset,ypos_vset,xsize_vset,ysize_vset],...
                'String','ESA',...
                'FontWeight','bold',...
                'BackgroundColor','#f5f5f5',...
                'FontSize',9,...
                'HorizontalAlignment','right');

            ypos_vset = ypos_vset-ystep_vset;

            obj.hMassText = uicontrol(obj.hVset,'Style','text',...
                'Position',[xpos_vset,ypos_vset,xsize_vset,ysize_vset],...
                'String','Mass flow',...
                'FontWeight','bold',...
                'BackgroundColor','#f5f5f5',...
                'FontSize',9,...
                'HorizontalAlignment','right');

            % Set read text position
            xstep_vset = 100;
            xpos_vset = xstart_vset+xstep_vset;
            ystep_vset = 30;
            ypos_vset = ystart_vset;

            obj.hDeflReadText = uicontrol(obj.hVset,'Style','text',...
                'Position',[xpos_vset,ypos_vset,xsize_vset,ysize_vset],...
                'String','Voltage [V]: ',...
                'FontSize',9,...
                'BackgroundColor','#f5f5f5',...
                'HorizontalAlignment','right');

            ypos_vset = ypos_vset-ystep_vset;

            obj.hExbReadText = uicontrol(obj.hVset,'Style','text',...
                'Position',[xpos_vset,ypos_vset,xsize_vset,ysize_vset],...
                'String','Voltage [V]: ',...
                'FontSize',9,...
                'BackgroundColor','#f5f5f5',...
                'HorizontalAlignment','right');

            ypos_vset = ypos_vset-ystep_vset;

            obj.hYsteerReadText = uicontrol(obj.hVset,'Style','text',...
                'Position',[xpos_vset,ypos_vset,xsize_vset,ysize_vset],...
                'String','Voltage [V]: ',...
                'FontSize',9,...
                'BackgroundColor','#f5f5f5',...
                'HorizontalAlignment','right');

            ypos_vset = ypos_vset-ystep_vset;

            obj.hEsaReadText = uicontrol(obj.hVset,'Style','text',...
                'Position',[xpos_vset,ypos_vset,xsize_vset,ysize_vset],...
                'String','Voltage [V]: ',...
                'FontSize',9,...
                'BackgroundColor','#f5f5f5',...
                'HorizontalAlignment','right');

            ypos_vset = ypos_vset-ystep_vset;

            obj.hMassReadText = uicontrol(obj.hVset,'Style','text',...
                'Position',[xpos_vset,ypos_vset,xsize_vset,ysize_vset],...
                'String','Voltage [V]: ',...
                'FontSize',9,...
                'BackgroundColor','#f5f5f5',...
                'HorizontalAlignment','right');

            % Set read field position
            xstep_vset = 180;
            xpos_vset = xstart_vset+xstep_vset;
            ystep_vset = 30;
            ypos_vset = ystart_vset;

            obj.hDeflReadField = uicontrol(obj.hVset,'Style','edit',...
                'Position',[xpos_vset,ypos_vset,xsize_vset,ysize_vset],...
                'Enable','inactive',...
                'FontSize',9,...
                'HorizontalAlignment','right');

            ypos_vset = ypos_vset-ystep_vset;

            obj.hExbReadField = uicontrol(obj.hVset,'Style','edit',...
                'Position',[xpos_vset,ypos_vset,xsize_vset,ysize_vset],...
                'Enable','inactive',...
                'FontSize',9,...
                'HorizontalAlignment','right');

            ypos_vset = ypos_vset-ystep_vset;

            obj.hYsteerReadField = uicontrol(obj.hVset,'Style','edit',...
                'Position',[xpos_vset,ypos_vset,xsize_vset,ysize_vset],...
                'Enable','inactive',...
                'FontSize',9,...
                'HorizontalAlignment','right');

            ypos_vset = ypos_vset-ystep_vset;

            obj.hEsaReadField = uicontrol(obj.hVset,'Style','edit',...
                'Position',[xpos_vset,ypos_vset,xsize_vset,ysize_vset],...
                'Enable','inactive',...
                'FontSize',9,...
                'HorizontalAlignment','right');

            ypos_vset = ypos_vset-ystep_vset;

            obj.hMassReadField = uicontrol(obj.hVset,'Style','edit',...
                'Position',[xpos_vset,ypos_vset,xsize_vset,ysize_vset],...
                'Enable','inactive',...
                'FontSize',9,...
                'HorizontalAlignment','right');

            % Set "set" text position
            xstep_vset = 280;
            xpos_vset = xstart_vset+xstep_vset;
            xsize_vset = 60;
            ystep_vset = 30;
            ypos_vset = ystart_vset;

            obj.hDeflSetText = uicontrol(obj.hVset,'Style','text',...
                'Position',[xpos_vset,ypos_vset,xsize_vset,ysize_vset],...
                'String','Vset [V]: ',...
                'FontSize',9,...
                'BackgroundColor','#f5f5f5',...
                'HorizontalAlignment','right');

            ypos_vset = ypos_vset-ystep_vset;

            obj.hExbSetText = uicontrol(obj.hVset,'Style','text',...
                'Position',[xpos_vset,ypos_vset,xsize_vset,ysize_vset],...
                'String','Vset [V]: ',...
                'FontSize',9,...
                'BackgroundColor','#f5f5f5',...
                'HorizontalAlignment','right');

            ypos_vset = ypos_vset-ystep_vset;

            obj.hYsteerSetText = uicontrol(obj.hVset,'Style','text',...
                'Position',[xpos_vset,ypos_vset,xsize_vset,ysize_vset],...
                'String','Vset [V]: ',...
                'FontSize',9,...
                'BackgroundColor','#f5f5f5',...
                'HorizontalAlignment','right');

            ypos_vset = ypos_vset-ystep_vset;

            obj.hEsaSetText = uicontrol(obj.hVset,'Style','text',...
                'Position',[xpos_vset,ypos_vset,xsize_vset,ysize_vset],...
                'String','Vset [V]: ',...
                'FontSize',9,...
                'BackgroundColor','#f5f5f5',...
                'HorizontalAlignment','right');

            ypos_vset = ypos_vset-ystep_vset;

            obj.hMassSetText = uicontrol(obj.hVset,'Style','text',...
                'Position',[xpos_vset,ypos_vset,xsize_vset,ysize_vset],...
                'String','Vset [V]: ',...
                'FontSize',9,...
                'BackgroundColor','#f5f5f5',...
                'HorizontalAlignment','right');

            % Set "set" field position
            xstep_vset = 340;
            xpos_vset = xstart_vset+xstep_vset;
            xsize_vset = 80;
            ystep_vset = 30;
            ypos_vset = ystart_vset;

            obj.hDeflSetField = uicontrol(obj.hVset,'Style','edit',...
                'Position',[xpos_vset,ypos_vset,xsize_vset,ysize_vset],...
                'FontSize',9,...
                'HorizontalAlignment','right');

            ypos_vset = ypos_vset-ystep_vset;

            obj.hExbSetField = uicontrol(obj.hVset,'Style','edit',...
                'Position',[xpos_vset,ypos_vset,xsize_vset,ysize_vset],...
                'FontSize',9,...
                'HorizontalAlignment','right');

            ypos_vset = ypos_vset-ystep_vset;

            obj.hYsteerSetField = uicontrol(obj.hVset,'Style','edit',...
                'Position',[xpos_vset,ypos_vset,xsize_vset,ysize_vset],...
                'FontSize',9,...
                'HorizontalAlignment','right');

            ypos_vset = ypos_vset-ystep_vset;

            obj.hEsaSetField = uicontrol(obj.hVset,'Style','edit',...
                'Position',[xpos_vset,ypos_vset,xsize_vset,ysize_vset],...
                'FontSize',9,...
                'HorizontalAlignment','right');

            ypos_vset = ypos_vset-ystep_vset;

            obj.hMassSetField = uicontrol(obj.hVset,'Style','edit',...
                'Position',[xpos_vset,ypos_vset,xsize_vset,ysize_vset],...
                'FontSize',9,...
                'HorizontalAlignment','right');

            % Set "set" button position
            xstep_vset = 430;
            xpos_vset = xstart_vset+xstep_vset;
            xsize_vset = 80;
            ypos_vset = ystart_vset;

            obj.hDeflSetBtn = uicontrol(obj.hVset,'Style','pushbutton',...
                'Position',[xpos_vset,ypos_vset,xsize_vset,ysize_vset],...
                'String','SET',...
                'FontWeight','bold',...
                'FontSize',9,...
                'HorizontalAlignment','center',...
                'Callback',@obj.deflBtnCallback);

            ypos_vset = ypos_vset-ystep_vset;

            obj.hExbSetBtn = uicontrol(obj.hVset,'Style','pushbutton',...
                'Position',[xpos_vset,ypos_vset,xsize_vset,ysize_vset],...
                'String','SET',...
                'FontWeight','bold',...
                'FontSize',9,...
                'HorizontalAlignment','center',...
                'Callback',@obj.exbBtnCallback);

            ypos_vset = ypos_vset-ystep_vset;

            obj.hYsteerSetBtn = uicontrol(obj.hVset,'Style','pushbutton',...
                'Position',[xpos_vset,ypos_vset,xsize_vset,ysize_vset],...
                'String','SET',...
                'FontWeight','bold',...
                'FontSize',9,...
                'HorizontalAlignment','center',...
                'Callback',@obj.ysteerBtnCallback);

            ypos_vset = ypos_vset-ystep_vset;

            obj.hEsaSetBtn = uicontrol(obj.hVset,'Style','pushbutton',...
                'Position',[xpos_vset,ypos_vset,xsize_vset,ysize_vset],...
                'String','SET',...
                'FontWeight','bold',...
                'FontSize',9,...
                'HorizontalAlignment','center',...
                'Callback',@obj.esaBtnCallback);

            ypos_vset = ypos_vset-ystep_vset;

            obj.hMassSetBtn = uicontrol(obj.hVset,'Style','pushbutton',...
                'Position',[xpos_vset,ypos_vset,xsize_vset,ysize_vset],...
                'String','SET',...
                'FontWeight','bold',...
                'FontSize',9,...
                'HorizontalAlignment','center',...
                'Callback',@obj.massBtnCallback);

            

            % Create file menu
            obj.hFileMenu = uimenu(obj.hFigure,'Text','File');

            % Create edit menu
            obj.hEditMenu = uimenu(obj.hFigure,'Text','Edit');

            % Create copy test sequence menu button
            obj.hCopyTS = uimenu(obj.hEditMenu,'Text','Copy Test Sequence',...
                'MenuSelectedFcn',@obj.copyTSCallback);

            % Turn off dock controls (defaults to on when first uimenu created)
            set(obj.hFigure,'DockControls','off');

            % Set positions for right-side GUI components
            xmid = 700;
            xgap = 8;
            ystart = 400;
            ypos = ystart;
            ysize = 22;
            ygap = 20;
            xtextsize = 140;
            xeditsize = 160;
            
            % Create remaning GUI components
            obj.hSequenceText = uicontrol(obj.hFigure,'Style','text',...
                'Position',[0,590,150,30],...
                'String','Test Sequence:',...
                'BackgroundColor','#f5f5f5',...
                'FontSize',14,...
                'FontWeight','bold',...
                'HorizontalAlignment','right');

            obj.hSequenceEdit = uicontrol(obj.hFigure,'Style','text',...
                'Position',[190,590,170,30],...
                'String',num2str(obj.TestSequence),...
                'BackgroundColor','#f5f5f5',...
                'FontSize',14,...
                'FontWeight','bold',...
                'HorizontalAlignment','left');

            ypos = ypos-ysize-ygap;

            obj.hDateText = uicontrol(obj.hFigure,'Style','text',...
                'Position',[0,565,150,30],...
                'String','Test Date:',...
                'BackgroundColor','#f5f5f5',...
                'FontSize',14,...
                'FontWeight','bold',...
                'HorizontalAlignment','right');

            obj.hDateEdit = uicontrol(obj.hFigure,'Style','text',...
                'Position',[190,565,230,30],...
                'BackgroundColor','#f5f5f5',...
                'String',obj.TestDate,...
                'FontSize',14,...
                'FontWeight','bold',...
                'HorizontalAlignment','left');
            
            ypos = 130;
            ygap = 29;

            obj.hOperatorText = uicontrol(obj.hFigure,'Style','text',...
                'Position',[xmid-xtextsize-xgap/2,ypos,xtextsize,ysize],...
                'String','Test Operator:',...
                'FontSize',12,...
                'BackgroundColor','#f5f5f5',...
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
                'BackgroundColor','#f5f5f5',...
                'FontWeight','bold',...
                'HorizontalAlignment','right');

            obj.hGasEdit = uicontrol(obj.hFigure,'Style','popupmenu',...
                'Position',[xmid+xgap/2,ypos,xeditsize,ysize],...
                'String',[{''},obj.GasList],...
                'FontSize',11,...
                'HorizontalAlignment','left',...
                'Callback',@obj.gasCallback);

            ypos = ypos-ysize-ygap;

            obj.hAcquisitionText = uicontrol(obj.hFigure,'Style','text',...
                'Position',[xmid-xtextsize-xgap/2,ypos,xtextsize,ysize],...
                'String','Acquisition Type:',...
                'FontSize',12,...
                'BackgroundColor','#f5f5f5',...
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
                'Position',[880,25,200,127],...
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

        function exbBtnCallback(obj,~,~)
            %EXBBTNCALLBACK Sets ExB HVPS voltage based on user input

            setVal = str2double(obj.hExbSetField.String);

            % Find ExB power supply
            hExb = obj.Hardware(contains([obj.Hardware.Tag],'ExB','IgnoreCase',true)&strcmpi([obj.Hardware.Type],'Power Supply'));
            if length(hExb)~=1
                error('beamlineGUI:invalidTags','Invalid tags! Must be exactly one power supply available with tag containing ''ExB''...');
            end

            if isnan(setVal)
                errordlg('A valid voltage value must be entered!','Invalid input!');
                set(obj.hExbSetField,'String','');
                return
            elseif setVal > hExb.VMax || setVal < hExb.VMin
                errordlg(['ExB voltage setpoint must be between ',num2str(hExb.VMin),' and ',num2str(hExb.VMax),' V!'],'Invalid input!');
                set(obj.hExbSetField,'String','');
                return
            end

            hExb.setVSet(setVal);
            set(obj.hExbSetField,'String','');

        end

        function esaBtnCallback(obj,~,~)
            %ESABTNCALLBACK Sets ESA HVPS voltage based on user input

            setVal = str2double(obj.hEsaSetField.String);

            % Find ESA power supply
            hEsa = obj.Hardware(contains([obj.Hardware.Tag],'ESA','IgnoreCase',true)&strcmpi([obj.Hardware.Type],'Power Supply'));
            if length(hEsa)~=1
                error('beamlineGUI:invalidTags','Invalid tags! Must be exactly one power supply available with tag containing ''ESA''...');
            end

            if isnan(setVal)
                errordlg('A valid voltage value must be entered!','Invalid input!');
                set(obj.hEsaSetField,'String','');
                return
            elseif setVal > hEsa.VMax || setVal < hEsa.VMin
                errordlg(['ESA voltage setpoint must be between ',num2str(hEsa.VMin),' and ',num2str(hEsa.VMax),' V!'],'Invalid input!');
                set(obj.hEsaSetField,'String','');
                return
            end

            hEsa.setVSet(setVal);
            set(obj.hEsaSetField,'String','');

        end

        function deflBtnCallback(obj,~,~)
            %DEFLBTNCALLBACK Sets Defl HVPS voltage based on user input

            setVal = str2double(obj.hDeflSetField.String);

            % Find Defl power supply
            hDefl = obj.Hardware(contains([obj.Hardware.Tag],'Defl','IgnoreCase',true)&strcmpi([obj.Hardware.Type],'Power Supply'));
            if length(hDefl)~=1
                error('beamlineGUI:invalidTags','Invalid tags! Must be exactly one power supply available with tag containing ''defl''...');
            end

            if isnan(setVal)
                errordlg('A valid voltage value must be entered!','Invalid input!');
                set(obj.hDeflSetField,'String','');
                return
            elseif setVal > hDefl.VMax || setVal < hDefl.VMin
                errordlg(['Defl voltage setpoint must be between ',num2str(hDefl.VMin),' and ',num2str(hDefl.VMax),' V!'],'Invalid input!');
                set(obj.hDeflSetField,'String','');
                return
            end

            hDefl.setVSet(setVal);
            set(obj.hDeflSetField,'String','');

        end

        function ysteerBtnCallback(obj,~,~)
            %YSTEERBTNCALLBACK Sets Y-steer HVPS voltage based on user input

            setVal = str2double(obj.hYsteerSetField.String);

            % Find y-steer power supply
            hYsteer = obj.Hardware(contains([obj.Hardware.Tag],'Ysteer','IgnoreCase',true)&strcmpi([obj.Hardware.Type],'Power Supply'));
            if length(hYsteer)~=1
                error('beamlineGUI:invalidTags','Invalid tags! Must be exactly one power supply available with tag containing ''ysteer''...');
            end

            if isnan(setVal)
                errordlg('A valid voltage value must be entered!','Invalid input!');
                set(obj.hYsteerSetField,'String','');
                return
            elseif setVal > hYsteer.VMax || setVal < hYsteer.VMin
                errordlg(['y-steer voltage setpoint must be between ',num2str(hYsteer.VMin),' and ',num2str(hYsteer.VMax),' V!'],'Invalid input!');
                set(obj.hYsteerSetField,'String','');
                return
            end

            hYsteer.setVSet(setVal);
            set(obj.hYsteerSetField,'String','');

        end

        function massBtnCallback(obj,~,~)
            %MASSBTNCALLBACK Sets mass flow controller voltage based on user input

            setVal = str2double(obj.hMassSetField.String);

            % Find mass flow power supply
            hMass = obj.Hardware(contains([obj.Hardware.Tag],'Mass','IgnoreCase',true)&strcmpi([obj.Hardware.Type],'Power Supply'));
            if length(hMass)~=1
                error('beamlineGUI:invalidTags','Invalid tags! Must be exactly one power supply available with tag containing ''mass''...');
            end

            if isnan(setVal)
                errordlg('A valid set value must be entered!','Invalid input!');
                set(obj.hMassSetField,'String','');
                return
            elseif setVal > 5 || setVal < 0
                errordlg('Mass flow setpoint must be between 0 and 5V!','Invalid input!');
                set(obj.hMassSetField,'String','');
                return
            end

            hMass.setVSet(setVal,1);
            set(obj.hMassSetField,'String','');

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

        function [extraction,einzel,mass] = readDMM(obj)
            %READDMM Reads DMM values for extraction, einzel, and mass flow controller

            % Find DMM
            hDMM = obj.Hardware(contains([obj.Hardware.Tag],'extraction','IgnoreCase',true)&contains([obj.Hardware.Tag],'einzel','IgnoreCase',true)&contains([obj.Hardware.Tag],'mass','IgnoreCase',true)&strcmpi([obj.Hardware.Type],'Multimeter'));
            if length(hDMM)~=1
                error('beamlineGUI:invalidTags','Invalid tag! No multimeter with ''Extraction'', ''Einzel'', & ''Mass'' tags found...');
            end

            dataOut = hDMM.performScan(1,3);

            % Parse dataOut for voltages and turn into readings
            extraction = dataOut(1);
            einzel = dataOut(2);
            mass = dataOut(3);

        end

        function readVal = readHVPS(obj,tag)
            %READHVPS Reads HVPS value based on tag input

            % Find power supply matching tags
            hHVPS = obj.Hardware(contains([obj.Hardware.Tag],tag,'IgnoreCase',true)&strcmpi([obj.Hardware.Type],'Power Supply'));
            if length(hHVPS)~=1
                error('beamlineGUI:invalidTags','Invalid tag! No power supply with tag %s found...',tag);
            end

            readVal = hHVPS.measV;

        end

        function readVal = readFaraday(obj)
            %READFARADAY Reads Faraday cup current value

            % Find picoammeter
            hFaraday = obj.Hardware(contains([obj.Hardware.Tag],'Faraday','IgnoreCase',true)&strcmpi([obj.Hardware.Type],'Picoammeter'));
            if length(hFaraday)~=1
                error('beamlineGUI:invalidHardware','Invalid hardware configuration! Must be exactly one picoammeter with tag containing ''Faraday''...');
            end

            readVal = hFaraday.read;
            hFaraday.devRW(':SYST:LOC');

        end

        function readVal = readPressureSensor(obj,tag)
            %READPRESSURESENSOR Reads pressure sensor value based on tag input

            switch lower(tag)
                case {'beamline','gas'}
                    sensorNum = 1;
                case {'chamber','rough'}
                    sensorNum = 2;
                case 'p3'
                    sensorNum = 3;
            end

            % Find correct gauge controller
            hPressure = obj.Hardware(contains([obj.Hardware.Tag],tag,'IgnoreCase',true)&strcmpi([obj.Hardware.Type],'Pressure Sensor'));
            if length(hPressure)~=1
                error('beamlineGUI:invalidTags','Invalid tag! No pressure sensor with tag %s found...',tag);
            end

            readVal = hPressure.readPressure(sensorNum);

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

