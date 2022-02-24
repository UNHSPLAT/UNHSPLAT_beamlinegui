classdef faradayCupVsExbSweep < acquisition
    % TODO: 1 - Add "RUN TEST" button enable and disable points
    %       2 - Manage figure window appropriately (invisible, delete, etc.)
    %       3 - Save data
    %       4 - Comments!
    %UNTITLED2 Summary of this class goes here
    %   Detailed explanation goes here

    properties (Constant)
        Type string = "Faraday cup vs ExB Sweep"
        MinDefault double = 100
        MaxDefault double = 5000
        StepsDefault double = 20
        DwellDefault double = 10
    end

    properties
        hExb
        hFaraday
        hFigure
        hMinText
        hMinEdit
        hStepsText
        hStepsEdit
        hSpacingEdit
        hMaxText
        hMaxEdit
        hDwellText
        hDwellEdit
        hSweepBtn
        VPoints double
        DwellTime double
    end

    methods
        function obj = faradayCupVsExbSweep(hGUI)
            %UNTITLED2 Construct an instance of this class
            %   Detailed explanation goes here
            obj@acquisition(hGUI);
            addlistener(obj.hBeamlineGUI,'ObjectBeingDestroyed',@obj.beamlineGUIDeleted);
        end

        function runSweep(obj)

            set(obj.hBeamlineGUI.hRunBtn,'Enable','off');
            set(obj.hBeamlineGUI.hRunBtn,'String','Test in progress...');
            
            % % Find ExB power supply
            % obj.hExb = hBeamlineGUI.Hardware(contains(hBeamlineGUI.Hardware.Tag,'ExB')&strcmp(hBeamlineGUI.Hardware.Type,'Power Supply'));
            % if length(hExb)~=1
            %     error('faradayCupVsExbSweep:invalidTags','Invalid tags! Must be exactly one power supply available with tag containing ''ExB''...');
            % end
            %
            % % Find Faraday cup picoammeter
            % obj.hFaraday = hBeamlineGUI.Hardware(contains(hBeamlineGUI.Hardware.Tag,'Faraday')&strcmp(hBeamlineGUI.Hardware.Type,'Picoammeter'));
            % if length(hFaraday)~=1
            %     error('faradayCupVsExbSweep:invalidTags','Invalid tags! Must be exactly one picoammeter available with tag containing ''Faraday''...');
            % end
            
            % Create figure
            obj.hFigure = figure('MenuBar','none',...
                'ToolBar','none',...
                'Resize','off',...
                'Position',[400,160,300,185],...
                'NumberTitle','off',...
                'Name','ExB Sweep Config',...
                'DeleteFcn',@obj.closeGUI);
            
            % Set positions
            ystart = 155;
            ypos = ystart;
            ysize = 20;
            ygap = 16;
            xpos = 30;
            xtextsize = 100;
            xeditsize = 60;
            
            % Create components
            obj.hMinText = uicontrol(obj.hFigure,'Style','text',...
                'Position',[xpos,ypos,xtextsize,ysize],...
                'String','Min Voltage [V]: ',...
                'FontSize',8,...
                'HorizontalAlignment','center');
            
            ypos = ypos-ysize;
            
            obj.hMinEdit = uicontrol(obj.hFigure,'Style','edit',...
                'Position',[xpos+(xtextsize-xeditsize)/2,ypos,xeditsize,ysize],...
                'String',num2str(obj.MinDefault),...
                'HorizontalAlignment','right');
            
            ypos = ypos-ysize-ygap;
            
            obj.hStepsText = uicontrol(obj.hFigure,'Style','text',...
                'Position',[xpos,ypos,xtextsize,ysize],...
                'String','Number of Steps: ',...
                'FontSize',8,...
                'HorizontalAlignment','center');
            
            ypos = ypos-ysize;
            
            obj.hStepsEdit = uicontrol(obj.hFigure,'Style','edit',...
                'Position',[xpos+(xtextsize-xeditsize)/2,ypos,xeditsize,ysize],...
                'String',num2str(obj.StepsDefault),...
                'HorizontalAlignment','right');
            
            ypos = ypos-ysize*2;
            
            obj.hSpacingEdit = uicontrol(obj.hFigure,'Style','checkbox',...
                'Position',[xpos-10,ypos,xtextsize+20,ysize],...
                'String',' Logarithmic Spacing',...
                'Value',1,...
                'HorizontalAlignment','right');
            
            ypos = ystart;
            xpos = 170;
            
            obj.hMaxText = uicontrol(obj.hFigure,'Style','text',...
                'Position',[xpos,ypos,xtextsize,ysize],...
                'String','Max Voltage [V]: ',...
                'FontSize',8,...
                'HorizontalAlignment','center');
            
            ypos = ypos-ysize;
            
            obj.hMaxEdit = uicontrol(obj.hFigure,'Style','edit',...
                'Position',[xpos+(xtextsize-xeditsize)/2,ypos,xeditsize,ysize],...
                'String',num2str(obj.MaxDefault),...
                'HorizontalAlignment','right');
            
            ypos = ypos-ysize-ygap;
            
            obj.hDwellText = uicontrol(obj.hFigure,'Style','text',...
                'Position',[xpos,ypos,xtextsize,ysize],...
                'String','Dwell Time [s]: ',...
                'FontSize',8,...
                'HorizontalAlignment','center');
            
            ypos = ypos-ysize;
            
            obj.hDwellEdit = uicontrol(obj.hFigure,'Style','edit',...
                'Position',[xpos+(xtextsize-xeditsize)/2,ypos,xeditsize,ysize],...
                'String',num2str(obj.DwellDefault),...
                'HorizontalAlignment','right');
            
            ypos = ypos-ysize*2-ygap;
            
            obj.hSweepBtn = uicontrol(obj.hFigure,'Style','pushbutton',...
                'Position',[xpos,ypos,xtextsize,ysize+ygap],...
                'String','RUN SWEEP',...
                'FontSize',10,...
                'FontWeight','bold',...
                'HorizontalAlignment','center',...
                'Callback',@obj.sweepBtnCallback);

%             waitfor(obj.hFigure); % not sure i need this

        end

        function beamlineGUIDeleted(obj,~,~)

            if isvalid(obj) && isvalid(obj.hFigure)
                delete(obj.hFigure);
            end
            
        end
    end

    methods (Access = private)

        function sweepBtnCallback(obj,~,~)
            
            try
    
                % Retrieve config values
                minVal = str2double(obj.hMinEdit.String);
                maxVal = str2double(obj.hMaxEdit.String);
                stepsVal = str2double(obj.hStepsEdit.String);
                dwellVal = str2double(obj.hDwellEdit.String);
    
                % Error checking
                if isnan(minVal) || isnan(maxVal) || isnan(stepsVal) || isnan(dwellVal)
                    errordlg('All fields must be filled with a valid numeric entry!','User input error!');
                    return
                elseif minVal > maxVal || minVal < 0 || maxVal < 0
                    errordlg('Invalid min and max voltages! Must be increasing positive values.','User input error!');
                    return
%                 elseif maxVal > obj.hExb.VMax || minVal < obj.hExb.VMin
%                     errordlg(['Invalid min and max voltages! Cannot exceed power supply range of ',num2str(obj.hExb.VMin),' to ',num2str(obj.hExb.VMax),' V'],'User input error!');
%                     return
                elseif dwellVal <= 0
                    errordlg('Invalid dwell time! Must be a positive value.','User input error!');
                    return
                elseif uint64(stepsVal) ~= stepsVal || ~stepsVal
                    errordlg('Invalid number of steps! Must be a positive integer.','User input error!');
                    return
                end
    
                % Determine log vs linear spacing
                logSpacing = logical(obj.hSpacingEdit.Value);

                % Retrieve config info
                operator = obj.hBeamlineGUI.TestOperator;
                gasType = obj.hBeamlineGUI.GasType;
                testSequence = obj.hBeamlineGUI.TestSequence;

                % Save config info
                save(fullfile(obj.hBeamlineGUI.DataDir,'config.mat'),'minVal','maxVal','stepsVal','dwellVal','logSpacing','operator','gasType','testSequence');
    
                % Create voltage setpoint array
                if logSpacing
                    vPoints = logspace(log10(minVal),log10(maxVal),stepsVal);
                else
                    vPoints = linspace(minVal,maxVal,stepsVal);
                end
                obj.VPoints = vPoints;
    
                % Set DwellTime property
                obj.DwellTime = dwellVal;
    
                % Set config figure to invisible
                set(obj.hFigure,'Visible','off');
    
                % Run sweep
                for iV = 1:length(obj.VPoints)
                    % Set ExB voltage
                    fprintf('Setting voltage to %.2f V...\n',obj.VPoints(iV));
%                     obj.hExb.setVSet(obj.VPoints(iV));
                    % Pause for dwell time
                    pause(obj.DwellTime);
                    % Obtain readings
%                     readings = obj.hBeamlineGUI.updateReadings;
%                     timestamp = now;
                    % Save data
                    fname = strrep(sprintf('ExB_%.2fV.mat',obj.VPoints(iV)),'.','p');
                    fprintf('Saving data to file: %s\n',fname);
%                     save(fullfile(obj.hBeamlineGUI.DataDir,fname),'readings','timestamp');
                end

                fprintf('\nTest complete!\n');
                delete(obj.hFigure);

            catch MExc

                delete(obj.hFigure);
                rethrow(MExc);

            end

        end

        function closeGUI(obj,~,~)

            if isvalid(obj.hBeamlineGUI)
                set(obj.hBeamlineGUI.hRunBtn,'String','RUN TEST');
                set(obj.hBeamlineGUI.hRunBtn,'Enable','on');
            end

            delete(obj);

        end

    end

end