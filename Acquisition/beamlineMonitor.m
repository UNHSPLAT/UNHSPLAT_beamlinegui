classdef beamlineMonitor < acquisition
    % TODO: 1 - Test and uncomment hardware-dependent lines
    %FARADAYCUPVSEXBSWEEP Configures and runs a sweep of Faraday cup current vs ExB voltage

    properties (Constant)
        Type string = "Pressure Monitor" % Acquisition type identifier string
    end

    properties (SetAccess = private)
        hFigureP % Handle to pressure readings figure
        hAxesP % Handle to pressure readings axes
        hFigureI % Handle to current readings figure
        hAxesI % Handle to current readings axes
        hFigureV % Handle to voltage readings figure
        hAxesV % Handle to voltage readings axes
        Readings struct % Structure containing all readings
    end

    methods
        function obj = beamlineMonitor(hGUI)
            %BEAMLINEMONITOR Construct an instance of this class

            obj@acquisition(hGUI);

            % Add listener to delete configuration GUI figure if main beamline GUI deleted
            addlistener(obj.hBeamlineGUI,'ObjectBeingDestroyed',@obj.beamlineGUIDeleted);

        end

        function runSweep(obj)
            %RUNSWEEP Establishes configuration GUI, with run sweep button triggering actual sweep execution

            % Disable and relabel beamline GUI run test button
            set(obj.hBeamlineGUI.hRunBtn,'String','Test in progress...');
            set(obj.hBeamlineGUI.hRunBtn,'Enable','off');

            % Create figures
            obj.hFigureP = figure('NumberTitle','off','Name','Pressure Monitor','DeleteFcn',@obj.closeFigure);
            obj.hFigureI = figure('NumberTitle','off','Name','Current Monitor','DeleteFcn',@obj.closeFigure);
            obj.hFigureV = figure('NumberTitle','off','Name','Voltage Monitor','DeleteFcn',@obj.closeFigure);

            try

                % Create axes
                obj.hAxesP = axes(obj.hFigureP);
                obj.hAxesI = axes(obj.hFigureI);
                obj.hAxesV = axes(obj.hFigureV);

                % Add listener to update data when new readings are taken by main beamlineGUI
                addlistener(obj.hBeamlineGUI,'LastRead','PostSet',@obj.updateFigures);
    
                % Initialize Readings with LastRead from beamlineGUI
                obj.Readings = obj.hBeamlineGUI.LastRead;
    
                % Retrieve config info
                operator = obj.hBeamlineGUI.TestOperator;
                gasType = obj.hBeamlineGUI.GasType;
                testSequence = obj.hBeamlineGUI.TestSequence;
    
                % Save config info
                save(fullfile(obj.hBeamlineGUI.DataDir,'config.mat'),'operator','gasType','testSequence');

            catch MExc

                % Delete figure if error, triggering closeGUI callback
                delete(obj.hFigure);

                % Rethrow caught exception
                rethrow(MExc);

            end

        end

        function beamlineGUIDeleted(obj,~,~)
            %BEAMLINEGUIDELETED Delete configuration GUI figure

            if isvalid(obj) && isvalid(obj.hFigureP)
                delete(obj.hFigureP);
            end

        end

        function closeFigure(obj,~,~)
            %CLOSEFIGURE Re-enable beamline GUI run test button, close remaining figures, and delete obj when figure is closed
            
            % Get handle to figure being closed
            h = gcbo;

            if ~strcmp(h.Name,'Pressure Monitor')
                if isvalid(obj.hFigureP)
                    delete(obj.hFigureP);
                end
            elseif ~strcmp(h.Name,'Current Monitor')
                if isvalid(obj.hFigureI)
                    delete(obj.hFigureI);
                end
            elseif ~strcmp(h.Name,'Voltage Monitor')
                if isvalid(obj.hFigureV)
                    delete(obj.hFigureV);
                end
            end

            % Enable beamline GUI run test button if still valid
            if isvalid(obj.hBeamlineGUI)
                set(obj.hBeamlineGUI.hRunBtn,'String','RUN TEST');
                set(obj.hBeamlineGUI.hRunBtn,'Enable','on');
            end
    
            % Plot pressure data
            hFigP = figure('NumberTitle','off','Name','Pressure Data');
            hAxP = axes(hFigP);
            plot(hAxP,[obj.Readings.T],[obj.Readings.PRough],'r-',...
                [obj.Readings.T],[obj.Readings.PGas],'g-',...
                [obj.Readings.T],[obj.Readings.PBeamline],'b-');
            set(hAxP,'YScale','log');
            datetick(hAxP,'x','HH:MM:SS');
            ylabel(hAxP,'Pressure [torr]');
            title(hAxP,'Pressure vs Time');
            legend(hAxP,'Rough Vac','Gas Line','Beamline','Location','northwest');

            % Plot current data
            hFigI = figure('NumberTitle','off','Name','Current Data');
            hAxI = axes(hFigI);
            plot(hAxI,[obj.Readings.T],[obj.Readings.IFaraday],'r-');
            datetick(hAxI,'x','HH:MM:SS');
            ylabel(hAxI,'I_F_a_r_a_d_a_y [A]');
            title(hAxI,'Current vs Time');

            % Plot voltage data
            hFigV = figure('NumberTitle','off','Name','Voltage Data');
            hAxV = axes(hFigV);
            plot(hAxV,[obj.Readings.T],[obj.Readings.VExtraction],'r-',...
                [obj.Readings.T],[obj.Readings.VEinzel],'g-',...
                [obj.Readings.T],[obj.Readings.VExb],'b-',...
                [obj.Readings.T],[obj.Readings.VEsa],'c-',...
                [obj.Readings.T],[obj.Readings.VDefl],'m-',...
                [obj.Readings.T],[obj.Readings.VYsteer],'k-');
            datetick(hAxV,'x','HH:MM:SS');
            ylabel(hAxV,'Voltage [V]');
            title(hAxV,'Voltage vs Time');
            legend(hAxV,'Extraction','Einzel','ExB','ESA','Defl','y-steer','Location','northwest');

            % Delete obj
            delete(obj);

        end

    end

    methods (Access = private)

        function updateFigures(obj,~,~)

            % Check that a new timestamp was recorded
            if obj.Readings(end).T ~= obj.hBeamlineGUI.LastRead.T

                try

                    % Append LastRead to Readings property
                    obj.Readings(end+1) = obj.hBeamlineGUI.LastRead;
    
                    % Update pressure monitor
                    if length(obj.Readings)>=100
                        plot(obj.hAxesP,[obj.Readings(end-99:end).T],[obj.Readings(end-99:end).PRough],'r-',...
                            [obj.Readings(end-99:end).T],[obj.Readings(end-99:end).PGas],'g-',...
                            [obj.Readings(end-99:end).T],[obj.Readings(end-99:end).PBeamline],'b-');
                    else
                        plot(obj.hAxesP,[obj.Readings.T],[obj.Readings.PRough],'r-',...
                            [obj.Readings.T],[obj.Readings.PGas],'g-',...
                            [obj.Readings.T],[obj.Readings.PBeamline],'b-');
                    end
                    set(obj.hAxesP,'YScale','log');
                    datetick(obj.hAxesP,'x','HH:MM:SS');
                    ylabel(obj.hAxesP,'Pressure [torr]');
                    title(obj.hAxesP,'PRESSURE MONITOR (LAST 100 READINGS) - CLOSE WINDOW TO EXIT TEST');
                    legend(obj.hAxesP,'Rough Vac','Gas Line','Beamline','Location','northwest');
    
                    % Update current monitor
                    if length(obj.Readings)>=100
                        plot(obj.hAxesI,[obj.Readings(end-99:end).T],[obj.Readings(end-99:end).IFaraday],'r-');
                    else
                        plot(obj.hAxesI,[obj.Readings.T],[obj.Readings.IFaraday],'r-');
                    end
                    datetick(obj.hAxesI,'x','HH:MM:SS');
                    ylabel(obj.hAxesI,'I_F_a_r_a_d_a_y [A]');
                    title(obj.hAxesI,'CURRENT MONITOR (LAST 100 READINGS) - CLOSE WINDOW TO EXIT TEST');
    
                    % Update voltage monitor
                    if length(obj.Readings)>=100
                        plot(obj.hAxesV,[obj.Readings(end-99:end).T],[obj.Readings(end-99:end).VExtraction],'r-',...
                            [obj.Readings(end-99:end).T],[obj.Readings(end-99:end).VEinzel],'g-',...
                            [obj.Readings(end-99:end).T],[obj.Readings(end-99:end).VExb],'b-',...
                            [obj.Readings(end-99:end).T],[obj.Readings(end-99:end).VEsa],'c-',...
                            [obj.Readings(end-99:end).T],[obj.Readings(end-99:end).VDefl],'m-',...
                            [obj.Readings(end-99:end).T],[obj.Readings(end-99:end).VYsteer],'k-');
                    else
                        plot(obj.hAxesV,[obj.Readings.T],[obj.Readings.VExtraction],'r-',...
                            [obj.Readings.T],[obj.Readings.VEinzel],'g-',...
                            [obj.Readings.T],[obj.Readings.VExb],'b-',...
                            [obj.Readings.T],[obj.Readings.VEsa],'c-',...
                            [obj.Readings.T],[obj.Readings.VDefl],'m-',...
                            [obj.Readings.T],[obj.Readings.VYsteer],'k-');
                    end
                    datetick(obj.hAxesV,'x','HH:MM:SS');
                    ylabel(obj.hAxesV,'Voltage [V]');
                    title(obj.hAxesV,'VOLTAGE MONITOR (LAST 100 READINGS) - CLOSE WINDOW TO EXIT TEST');
                    legend(obj.hAxesV,'Extraction','Einzel','ExB','ESA','Defl','y-steer','Location','northwest');

                    % Append new data to file
                    readings = obj.Readings;
                    save(fullfile(obj.hBeamlineGUI.DataDir,'beamlineMonitor.mat'),'readings');
    
                catch MExc
    
                    % Delete figure if error, triggering closeGUI callback
                    delete(obj.hFigureP);
    
                    % Rethrow caught exception
                    rethrow(MExc);
    
                end

            end

        end

    end

end