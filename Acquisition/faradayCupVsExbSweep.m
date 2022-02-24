classdef faradayCupVsExbSweep < acquisition
    % TODO: 1 - Test and uncomment hardware-dependent lines
    %FARADAYCUPVSEXBSWEEP Configures and runs a sweep of Faraday cup current vs ExB voltage

    properties (Constant)
        Type string = "Faraday cup vs ExB Sweep" % Acquisition type identifier string
        MinDefault double = 100 % Default minimum voltage
        MaxDefault double = 5000 % Default maximum voltage
        StepsDefault double = 20 % Default number of steps
        DwellDefault double = 10 % Default dwell time
    end

    properties
        hExb % Handle to ExB power supply
        hFigure % Handle to configuration GUI figure
        hMinText % Handle to minimum voltage label
        hMinEdit % Handle to minimum voltage field
        hStepsText % Handle to number of steps label
        hStepsEdit % Handle to number of steps field
        hSpacingEdit % Handle to log spacing checkbox
        hMaxText % Handle to maximum voltage label
        hMaxEdit % Handle to maximum voltage field
        hDwellText % Handle to dwell time label
        hDwellEdit % Handle to dwell time field
        hSweepBtn % Handle to run sweep button
        VPoints double % Array of ExB voltage setpoints
        DwellTime double % Dwell time setting
    end

    methods
        function obj = faradayCupVsExbSweep(hGUI)
            %FARADAYCUPVSEXBSWEEP Construct an instance of this class

            obj@acquisition(hGUI);
            
            % Add listener to delete configuration GUI figure if main beamline GUI deleted
            addlistener(obj.hBeamlineGUI,'ObjectBeingDestroyed',@obj.beamlineGUIDeleted);
        end

        function runSweep(obj)
            %RUNSWEEP Establishes configuration GUI, with run sweep button triggering actual sweep execution

            % Disable and relabel beamline GUI run test button
            set(obj.hBeamlineGUI.hRunBtn,'Enable','off');
            set(obj.hBeamlineGUI.hRunBtn,'String','Test in progress...');
            
            % % Find ExB power supply
            % obj.hExb = hBeamlineGUI.Hardware(contains(hBeamlineGUI.Hardware.Tag,'ExB')&strcmp(hBeamlineGUI.Hardware.Type,'Power Supply'));
            % if length(hExb)~=1
            %     error('faradayCupVsExbSweep:invalidTags','Invalid tags! Must be exactly one power supply available with tag containing ''ExB''...');
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

        end

        function beamlineGUIDeleted(obj,~,~)
            %BEAMLINEGUIDELETED Delete configuration GUI figure

            if isvalid(obj) && isvalid(obj.hFigure)
                delete(obj.hFigure);
            end
            
        end
    end

    methods (Access = private)

        function sweepBtnCallback(obj,~,~)
            %SWEEPBTNCALLBACK Begin sweep execution based on configuration info
            
            % Run inside a try-catch to reset beamline GUI run test button if error occurs
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
    
                % Create voltage setpoint array
                if logSpacing
                    vPoints = logspace(log10(minVal),log10(maxVal),stepsVal);
                else
                    vPoints = linspace(minVal,maxVal,stepsVal);
                end
                obj.VPoints = vPoints;

                % Save config info
                save(fullfile(obj.hBeamlineGUI.DataDir,'config.mat'),'vPoints','minVal','maxVal','stepsVal','dwellVal','logSpacing','operator','gasType','testSequence');
    
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

                % Delete figure if error, triggering closeGUI callback
                delete(obj.hFigure);

                % Rethrow caught exception
                rethrow(MExc);

            end

        end

        function closeGUI(obj,~,~)
            %CLOSEGUI Re-enable beamline GUI run test button and delete obj when figure is closed

            % Enable beamline GUI run test button if still valid
            if isvalid(obj.hBeamlineGUI)
                set(obj.hBeamlineGUI.hRunBtn,'String','RUN TEST');
                set(obj.hBeamlineGUI.hRunBtn,'Enable','on');
            end

            % Delete obj
            delete(obj);

        end

    end

end