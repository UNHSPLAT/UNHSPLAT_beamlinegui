classdef beamlineMonitor < acquisition
    % TODO: 1 - Test and uncomment hardware-dependent lines
    %FARADAYCUPVSEXBSWEEP Configures and runs a sweep of Faraday cup current vs ExB voltage

    properties (Constant)
        Type string = "Pressure Monitor" % Acquisition type identifier string
    end

    properties (SetAccess = private)
        hFigure % Handle to readings figure
        hAxesP % Handle to pressure readings axes
        hAxesI % Handle to current readings axes
        hAxesV % Handle to voltage readings axes
        Readings struct % Structure containing all readings
        ReadingsListener % Listener for beamlineGUI readings
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
            obj.hFigure = figure('NumberTitle','off',...
                'Name','Beamline Monitor - Close Window to Exit Test',...
                'Position',[100,100,900,600],...
                'DeleteFcn',@obj.closeFigure);
            try
                % Create axes
                obj.hAxesP = axes(obj.hFigure);
                subplot(2,2,[1 2],obj.hAxesP);
                obj.hAxesI = axes(obj.hFigure);
                subplot(2,2,3,obj.hAxesI);
                obj.hAxesV = axes(obj.hFigure);
                subplot(2,2,4,obj.hAxesV);

                % legend(obj.hAxesP,'Rough Vac','Gas Line','Beamline','Chambe

                % Add listener to update data when new readings are taken by main beamlineGUI
                obj.ReadingsListener = addlistener(obj.hBeamlineGUI,'LastRead','PostSet',@obj.updateFigures);
    
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

            if isvalid(obj) && isvalid(obj.hFigure)
                delete(obj.hFigure);
            end

        end

        function closeFigure(obj,~,~)
            %CLOSEFIGURE Re-enable beamline GUI run test button, plot all data, and delete obj when figure is closed
            
            % Enable beamline GUI run test button if still valid
            if isvalid(obj.hBeamlineGUI)
                set(obj.hBeamlineGUI.hRunBtn,'String','RUN TEST');
                set(obj.hBeamlineGUI.hRunBtn,'Enable','on');
            end
    
            % Plot pressure data
            % hFigP = figure('NumberTitle','off','Name','Pressure Data');
            % hAxP = axes(hFigP);
            % plot(hAxP,[obj.Readings.T],[obj.Readings.PRough],'r-',...
            %     [obj.Readings.T],[obj.Readings.PGas],'g-',...
            %     [obj.Readings.T],[obj.Readings.PBeamline],'b-',...
            %     [obj.Readings.T],[obj.Readings.PChamber],'c-');
            % set(hAxP,'YScale','log');
            % datetick(hAxP,'x','HH:MM:SS');
            % ylabel(hAxP,'Pressure [torr]');
            % title(hAxP,'Pressure vs Time');
            % legend(hAxP,'Rough Vac','Gas Line','Beamline','Chamber','Location','northwest');

            % % Plot current data
            % hFigI = figure('NumberTitle','off','Name','Current Data');
            % hAxI = axes(hFigI);
            % plot(hAxI,[obj.Readings.T],[obj.Readings.IFaraday],'r-');
            % datetick(hAxI,'x','HH:MM:SS');
            % ylabel(hAxI,'I_F_a_r_a_d_a_y [A]');
            % title(hAxI,'Current vs Time');

            % % Plot voltage data
            % hFigV = figure('NumberTitle','off','Name','Voltage Data');
            % hAxV = axes(hFigV);
            % plot(hAxV,[obj.Readings.T],[obj.Readings.VExtraction],'r-',...
            %     [obj.Readings.T],[obj.Readings.VEinzel],'g-',...
            %     [obj.Readings.T],[obj.Readings.VExb],'b-',...
            %     [obj.Readings.T],[obj.Readings.VEsa],'c-',...
            %     [obj.Readings.T],[obj.Readings.VDefl],'m-',...
            %     [obj.Readings.T],[obj.Readings.VYsteer],'k-');
            % datetick(hAxV,'x','HH:MM:SS');
            % ylabel(hAxV,'Voltage [V]');
            % title(hAxV,'Voltage vs Time');
            % legend(hAxV,'Extraction','Einzel','ExB','ESA','Defl','y-steer','Location','northwest');

            % Delete obj
            delete(obj.ReadingsListener);
            delete(obj);

        end

    end

    methods (Access = private)

        function plotVals(obj,~,~)
            hold(obj.hAxesP,'on');
            hold(obj.hAxesV,'on');
            fields = fieldnames(obj.hBeamlineGUI.Monitors);
            p_ledge = {};
            v_ledge = {};
            for i =1:numel(fields)
                group = obj.hBeamlineGUI.Monitors.(fields{i}).group;
                if strcmp(group,"pressure")
                    plot(obj.hAxesP,[obj.Readings.T],[obj.Readings.(fields{i})]);
                    p_ledge{end+1} = fields{i};
                elseif strcmp(group,"HV")
                    plot(obj.hAxesV,[obj.Readings.T],[obj.Readings.(fields{i})]);
                    v_ledge{end+1} = fields{i};
                end
            end
            hold(obj.hAxesP,'off');
            hold(obj.hAxesV,'off');
            plot(obj.hAxesI,[obj.Readings.T],[obj.Readings.Ifaraday],'r-');

            legend(obj.hAxesP,p_ledge,'Location','northwest');
            legend(obj.hAxesV,v_ledge,'Location','northwest');

            set(obj.hAxesP,'YScale','log');
            datetick(obj.hAxesP,'x','HH:MM:SS');
            ylabel(obj.hAxesP,'Pressure [torr]');
            title(obj.hAxesP,'PRESSURE MONITOR (LAST 100 READINGS)');

            datetick(obj.hAxesI,'x','HH:MM:SS');
            ylabel(obj.hAxesI,'I_{Faraday} [A]');
            title(obj.hAxesI,'CURRENT MONITOR (LAST 100 READINGS)');

            datetick(obj.hAxesV,'x','HH:MM:SS');
            ylabel(obj.hAxesV,'Voltage [V]');
            title(obj.hAxesV,'VOLTAGE MONITOR (LAST 100 READINGS)');
            
        end

        function updateFigures(obj,~,~)

            % Check that a new timestamp was recorded
            if obj.Readings(end).T ~= obj.hBeamlineGUI.LastRead.T

                try

                    % Append LastRead to Readings property
                    obj.Readings(end+1) = obj.hBeamlineGUI.LastRead;

                    % Update pressure monitor
                    obj.plotVals()

                    % Append new data to file
                    readings = obj.Readings;
                    % save(fullfile(obj.hBeamlineGUI.DataDir,'beamlineMonitor.mat'),'readings');
    
                catch MExc
    
                    % Delete figure if error, triggering closeGUI callback
                    delete(obj.hFigure);
    
                    % Rethrow caught exception
                    rethrow(MExc);
    
                end

            end

        end

    end

end