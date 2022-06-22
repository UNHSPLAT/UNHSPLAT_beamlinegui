classdef faradayCupSweep < acquisition
    %FARADAYCUPSWEEP Configures and runs a sweep of Faraday cup current vs selectable voltage supply

    properties (Constant)
        Type string = "Faraday cup Sweep" % Acquisition type identifier string
        MinDefault double = 100 % Default minimum voltage
        MaxDefault double = 2500 % Default maximum voltage
        StepsDefault double = 40 % Default number of steps
        DwellDefault double = 5 % Default dwell time
        PSList string = ["ExBp","ESA","Defl","Ysteer"] % List of sweep supplies
    end

    properties
        PSTag string % String identifying user-selected HVPS
        hHVPS % Handle to desired power supply
        hConfFigure % Handle to configuration GUI figure
        hFigure1 % Handle to I-V data plot
        hFigure2 % Handle to I-1/V^2 data plot
        hAxes1 % Handle to I-V data axes
        hAxes2 % Handle to I-1/V^2 data axes
        hSupplyText % Handle to sweep supply label
        hSupplyEdit % Handle to sweep supply field
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
        VPoints double % Array of ExBp voltage setpoints
        DwellTime double % Dwell time setting
    end

    methods
        function obj = faradayCupSweep(hGUI)
            %FARADAYCUPVSEXBpSWEEP Construct an instance of this class

            obj@acquisition(hGUI);
            
            % Add listener to delete configuration GUI figure if main beamline GUI deleted
            addlistener(obj.hBeamlineGUI,'ObjectBeingDestroyed',@obj.beamlineGUIDeleted);
        end

        function runSweep(obj)
            %RUNSWEEP Establishes configuration GUI, with run sweep button triggering actual sweep execution

            % Disable and relabel beamline GUI run test button
            set(obj.hBeamlineGUI.hRunBtn,'Enable','off');
            set(obj.hBeamlineGUI.hRunBtn,'String','Test in progress...');
            
            % Create figure
            obj.hConfFigure = figure('MenuBar','none',...
                'ToolBar','none',...
                'Resize','off',...
                'Position',[400,160,300,220],...
                'NumberTitle','off',...
                'Name','Sweep Config',...
                'DeleteFcn',@obj.closeGUI);

            % Set positions
            ystart = 190;
            ysize = 20;
            xpos = 150;
            xtextsize = 100;
            xeditsize = 60;

            obj.hSupplyText = uicontrol(obj.hConfFigure,'Style','text',...
                'Position',[xpos-xtextsize,ystart,xtextsize,ysize],...
                'String','Sweep Supply: ',...
                'FontSize',9,...
                'HorizontalAlignment','right');

            obj.hSupplyEdit = uicontrol(obj.hConfFigure,'Style','popupmenu',...
                'Position',[xpos,ystart,xeditsize,ysize],...
                'String',obj.PSList,...
                'HorizontalAlignment','right');
            
            % Set positions
            ystart = 155;
            ypos = ystart;
            ysize = 20;
            ygap = 16;
            xpos = 30;
            xtextsize = 100;
            xeditsize = 60;
            
            % Create components
            obj.hMinText = uicontrol(obj.hConfFigure,'Style','text',...
                'Position',[xpos,ypos,xtextsize,ysize],...
                'String','Min Voltage [V]: ',...
                'FontSize',8,...
                'HorizontalAlignment','center');
            
            ypos = ypos-ysize;
            
            obj.hMinEdit = uicontrol(obj.hConfFigure,'Style','edit',...
                'Position',[xpos+(xtextsize-xeditsize)/2,ypos,xeditsize,ysize],...
                'String',num2str(obj.MinDefault),...
                'HorizontalAlignment','right');
            
            ypos = ypos-ysize-ygap;
            
            obj.hStepsText = uicontrol(obj.hConfFigure,'Style','text',...
                'Position',[xpos,ypos,xtextsize,ysize],...
                'String','Number of Steps: ',...
                'FontSize',8,...
                'HorizontalAlignment','center');
            
            ypos = ypos-ysize;
            
            obj.hStepsEdit = uicontrol(obj.hConfFigure,'Style','edit',...
                'Position',[xpos+(xtextsize-xeditsize)/2,ypos,xeditsize,ysize],...
                'String',num2str(obj.StepsDefault),...
                'HorizontalAlignment','right');
            
            ypos = ypos-ysize*2;
            
            obj.hSpacingEdit = uicontrol(obj.hConfFigure,'Style','checkbox',...
                'Position',[xpos-10,ypos,xtextsize+20,ysize],...
                'String',' Logarithmic Spacing',...
                'Value',1,...
                'HorizontalAlignment','right');
            
            ypos = ystart;
            xpos = 170;
            
            obj.hMaxText = uicontrol(obj.hConfFigure,'Style','text',...
                'Position',[xpos,ypos,xtextsize,ysize],...
                'String','Max Voltage [V]: ',...
                'FontSize',8,...
                'HorizontalAlignment','center');
            
            ypos = ypos-ysize;
            
            obj.hMaxEdit = uicontrol(obj.hConfFigure,'Style','edit',...
                'Position',[xpos+(xtextsize-xeditsize)/2,ypos,xeditsize,ysize],...
                'String',num2str(obj.MaxDefault),...
                'HorizontalAlignment','right');
            
            ypos = ypos-ysize-ygap;
            
            obj.hDwellText = uicontrol(obj.hConfFigure,'Style','text',...
                'Position',[xpos,ypos,xtextsize,ysize],...
                'String','Dwell Time [s]: ',...
                'FontSize',8,...
                'HorizontalAlignment','center');
            
            ypos = ypos-ysize;
            
            obj.hDwellEdit = uicontrol(obj.hConfFigure,'Style','edit',...
                'Position',[xpos+(xtextsize-xeditsize)/2,ypos,xeditsize,ysize],...
                'String',num2str(obj.DwellDefault),...
                'HorizontalAlignment','right');
            
            ypos = ypos-ysize*2-ygap;
            
            obj.hSweepBtn = uicontrol(obj.hConfFigure,'Style','pushbutton',...
                'Position',[xpos,ypos,xtextsize,ysize+ygap],...
                'String','RUN SWEEP',...
                'FontSize',10,...
                'FontWeight','bold',...
                'HorizontalAlignment','center',...
                'Callback',@obj.sweepBtnCallback);

        end

        function beamlineGUIDeleted(obj,~,~)
            %BEAMLINEGUIDELETED Delete configuration GUI figure

            if isvalid(obj) && isvalid(obj.hConfFigure)
                delete(obj.hConfFigure);
            end
            
        end
    end

    methods (Access = private)

        function sweepBtnCallback(obj,~,~)
            %SWEEPBTNCALLBACK Begin sweep execution based on configuration info
            
            % Run inside a try-catch to reset beamline GUI run test button if error occurs
            try
    
                % Retrieve config values
                psTag = obj.PSList(obj.hSupplyEdit.Value);
                minVal = str2double(obj.hMinEdit.String);
                maxVal = str2double(obj.hMaxEdit.String);
                stepsVal = str2double(obj.hStepsEdit.String);
                dwellVal = str2double(obj.hDwellEdit.String);
            
                % Find desired power supply
                obj.hHVPS = obj.hBeamlineGUI.Hardware(contains([obj.hBeamlineGUI.Hardware.Tag],psTag,'IgnoreCase',true)&strcmpi([obj.hBeamlineGUI.Hardware.Type],'Power Supply'));
                if length(obj.hHVPS)~=1
                    error('faradayCupSweep:invalidTags','Invalid tags! Must be exactly one power supply available with tag containing ''%s''...',psTag);
                end
    
                % Error checking
                if isnan(minVal) || isnan(maxVal) || isnan(stepsVal) || isnan(dwellVal)
                    errordlg('All fields must be filled with a valid numeric entry!','User input error!');
                    return
                elseif minVal > maxVal || minVal < 0 || maxVal < 0
                    errordlg('Invalid min and max voltages! Must be increasing positive values.','User input error!');
                    return
                elseif maxVal > obj.hHVPS.VMax || minVal < obj.hHVPS.VMin
                    errordlg(['Invalid min and max voltages! Cannot exceed power supply range of ',num2str(obj.hHVPS.VMin),' to ',num2str(obj.hHVPS.VMax),' V'],'User input error!');
                    return
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
                set(obj.hConfFigure,'Visible','off');

                % Stop beamline timer (timer callback executed manually during test)
                stop(obj.hBeamlineGUI.hTimer);

                % Create figures and axes
                obj.hFigure1 = figure('NumberTitle','off','Name','Faraday Cup Current vs Voltage');
                obj.hAxes1 = axes(obj.hFigure1);
                obj.hFigure2 = figure('NumberTitle','off','Name','Faraday Cup Current vs 1/V^2');
                obj.hAxes2 = axes(obj.hFigure2);

                % Preallocate arrays
                T = strings(1,length(obj.VPoints));
                Vexbp = zeros(1,length(obj.VPoints));
                Ifar = zeros(1,length(obj.VPoints));
                Vext = zeros(1,length(obj.VPoints));
                Vesa = zeros(1,length(obj.VPoints));
                Vdef = zeros(1,length(obj.VPoints));
                Vyst = zeros(1,length(obj.VPoints));
                Vmfc = zeros(1,length(obj.VPoints));
                Pbml = zeros(1,length(obj.VPoints));
                Pgas = zeros(1,length(obj.VPoints));
                Prou = zeros(1,length(obj.VPoints));
    
                % Run sweep
                for iV = 1:length(obj.VPoints)
                    if isempty(obj.hFigure1) || ~isvalid(obj.hFigure1)
                        obj.hFigure1 = figure('NumberTitle','off',...
                            'Name','Faraday Cup Current vs Voltage');
        
                        obj.hAxes1 = axes(obj.hFigure1); %#ok<LAXES> Only executed if figure deleted or not instantiated
                    end
                    if isempty(obj.hFigure2) || ~isvalid(obj.hFigure2)
                        obj.hFigure2 = figure('NumberTitle','off',...
                            'Name','Faraday Cup Current vs 1/V^2');
        
                        obj.hAxes2 = axes(obj.hFigure2); %#ok<LAXES> Only executed if figure deleted or not instantiated
                    end

                    % Set ExB voltage
                    fprintf('Setting voltage to %.2f V...\n',obj.VPoints(iV));
                    obj.hHVPS.setVSet(obj.VPoints(iV));
                    % Pause for dwell time
                    pause(obj.DwellTime);
                    % Obtain readings
                    fname = fullfile(obj.hBeamlineGUI.DataDir,[strrep(sprintf('%s_%.2fV',psTag,obj.VPoints(iV)),'.','p'),'.mat']);
                    readings = obj.hBeamlineGUI.updateReadings([],[],fname);
                    % Assign variables
                    T(iV) = datestr(readings.T,"yyyy-mm-dd HH:MM:SS");
                    Vexbp(iV) = readings.VExbp;
                    Ifar(iV) = readings.IFaraday;
                    Vext(iV) = readings.VExtraction;
                    Vesa(iV) = readings.VEsa;
                    Vdef(iV) = readings.VDefl;
                    Vyst(iV) = readings.VYsteer;
                    Vmfc(iV) = readings.VMass;
                    Pbml(iV) = readings.PBeamline;
                    Pgas(iV) = readings.PGas;
                    Prou(iV) = readings.PRough;
                    % Plot data
                    switch lower(psTag)
                        case 'exbp'
                            plot(obj.hAxes1,Vexbp(1:iV),Ifar(1:iV));
                            plot(obj.hAxes2,1./Vexbp(1:iV).^2,Ifar(1:iV));
                        case 'esa'
                            plot(obj.hAxes1,Vesa(1:iV),Ifar(1:iV));
                            plot(obj.hAxes2,1./Vesa(1:iV).^2,Ifar(1:iV));
                        case 'defl'
                            plot(obj.hAxes1,Vdef(1:iV),Ifar(1:iV));
                            plot(obj.hAxes2,1./Vdef(1:iV).^2,Ifar(1:iV));
                        case 'ysteer'
                            plot(obj.hAxes1,Vyst(1:iV),Ifar(1:iV));
                            plot(obj.hAxes2,1./Vyst(1:iV).^2,Ifar(1:iV));
                    end
                    set(obj.hAxes1,'YScale','log');
                    xlabel(obj.hAxes1,['V_{',char(psTag),'} [V]']);
                    ylabel(obj.hAxes1,'I_{Faraday} [A]');
                    set(obj.hAxes2,'Yscale','log');
                    xlabel(obj.hAxes2,['1/V^2_{',char(psTag),'} [1/V^2]']);
                    ylabel(obj.hAxes2,'I_F_a_r_a_d_a_y [A]');
                end

                % Save results .mat file
                fname = 'results.mat';
                save(fullfile(obj.hBeamlineGUI.DataDir,fname),'Vexbp','Ifar','Vext','Vesa','Vdef','Vyst','Vmfc','Pbml','Pgas','Prou','T');

                % Save results .csv file
                fname = strrep(fname,'.mat','.csv');
                t = table(T',Vexbp',Ifar',Vext',Vesa',Vdef',Vyst',Vmfc',Pbml',Pgas',Prou','VariableNames',{'t','Vexbp','Ifar','Vext','Vesa','Vdef','Vyst','Vmfc','Pbml','Pgas','Prou'});
                writetable(t,fullfile(obj.hBeamlineGUI.DataDir,fname));

                fprintf('\nTest complete!\n');
                delete(obj.hConfFigure);

            catch MExc

                % Delete figure if error, triggering closeGUI callback
                delete(obj.hConfFigure);

                % Rethrow caught exception
                rethrow(MExc);

            end

        end

        function closeGUI(obj,~,~)
            %CLOSEGUI Re-enable beamline GUI run test button, restart timer, and delete obj when figure is closed

            % Enable beamline GUI run test button if still valid
            if isvalid(obj.hBeamlineGUI)
                set(obj.hBeamlineGUI.hRunBtn,'String','RUN TEST');
                set(obj.hBeamlineGUI.hRunBtn,'Enable','on');
            end

            if strcmp(obj.hBeamlineGUI.hTimer.Running,'off')
                start(obj.hBeamlineGUI.hTimer);
            end

            % Delete obj
            delete(obj);

        end

    end

end