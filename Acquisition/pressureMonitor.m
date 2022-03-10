classdef pressureMonitor < acquisition
    % TODO: 1 - Test and uncomment hardware-dependent lines
    %FARADAYCUPVSEXBSWEEP Configures and runs a sweep of Faraday cup current vs ExB voltage

    properties (Constant)
        Type string = "Pressure Monitor" % Acquisition type identifier string
        Period double = 5 % Period of pressure readings in seconds
    end

    properties (SetAccess = private)
        hCenter2 % Handle to Leybold Center 2 pressure gauge controller
        hGraphix3 % Handle to Leybold Graphix 3 pressure gauge controller
        hFigure % Handle to pressure readings figure
        hAxes % Handle to pressure readings axes
        hTimer % Handle to timer used to execute pressure readings
        Readings struct % Structure containing all pressure readings
        tStart % Handle to start time
    end

    methods
        function obj = pressureMonitor(hGUI)
            %FARADAYCUPVSEXBSWEEP Construct an instance of this class

            obj@acquisition(hGUI);

            % Add listener to delete configuration GUI figure if main beamline GUI deleted
            addlistener(obj.hBeamlineGUI,'ObjectBeingDestroyed',@obj.beamlineGUIDeleted);
        end

        function runSweep(obj)
            %RUNSWEEP Establishes configuration GUI, with run sweep button triggering actual sweep execution

            % Disable and relabel beamline GUI run test button
            set(obj.hBeamlineGUI.hRunBtn,'String','Test in progress...');
            set(obj.hBeamlineGUI.hRunBtn,'Enable','off');

            % Find Leybold center 2
            obj.hCenter2 = obj.hBeamlineGUI.Hardware(contains([obj.hBeamlineGUI.Hardware.Tag],'Rough','IgnoreCase',true)&strcmpi([obj.hBeamlineGUI.Hardware.ModelNum],'Center 2'));
            if length(obj.hCenter2)~=1
                error('pressureMonitor:invalidTags','Invalid tags! Must be exactly one pressure controller available with tag containing ''Rough''...');
            end

            % Find Leybold graphix 3
            obj.hGraphix3 = obj.hBeamlineGUI.Hardware(contains([obj.hBeamlineGUI.Hardware.Tag],'Chamber','IgnoreCase',true)&strcmpi([obj.hBeamlineGUI.Hardware.ModelNum],'Graphix 3'));
            if length(obj.hGraphix3)~=1
                error('pressureMonitor:invalidTags','Invalid tags! Must be exactly one pressure controller available with tag containing ''Chamber''...');
            end

            % Create figure
            obj.hFigure = figure('MenuBar','none',...
                'ToolBar','none',...
                'NumberTitle','off',...
                'Name','Pressure Monitor',...
                'DeleteFcn',@obj.closeGUI);

            try

                obj.hAxes = axes(obj.hFigure);
    
                % Retrieve config info
                operator = obj.hBeamlineGUI.TestOperator;
                gasType = obj.hBeamlineGUI.GasType;
                testSequence = obj.hBeamlineGUI.TestSequence;
    
                % Save config info
                save(fullfile(obj.hBeamlineGUI.DataDir,'config.mat'),'operator','gasType','testSequence');

                obj.tStart = tic;
                obj.createTimer;

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

        function closeGUI(obj,~,~)
            %CLOSEGUI Re-enable beamline GUI run test button and delete obj when figure is closed

            % Enable beamline GUI run test button if still valid
            if isvalid(obj.hBeamlineGUI)
                set(obj.hBeamlineGUI.hRunBtn,'String','RUN TEST');
                set(obj.hBeamlineGUI.hRunBtn,'Enable','on');
            end

            if strcmp(obj.hTimer.Running,'on')
                stop(obj.hTimer);
            end

            hFig = figure;
            hAx = axes(hFig);
            readings = obj.Readings;
            plot(hAx,[readings.time],[readings.rough],'r-',[readings.time],[readings.gas],'g-',[readings.time],[readings.chamber],'b-');
            set(hAx,'YScale','log');
            xlabel(hAx,'Time [sec]');
            ylabel(hAx,'Pressure [torr]');
            title(hAx,'Pressure vs Time');
            legend(hAx,'Rough Vac','Gas Line','Chamber','Location','northwest');

            % Delete obj
            delete(obj);

        end

    end

    methods (Access = private)

        function createTimer(obj)

            obj.hTimer = timer('Name','pressureTimer',...
                'Period',obj.Period,...
                'ExecutionMode','fixedDelay',...
                'TimerFcn',@obj.updateReadings);

            start(obj.hTimer);

        end

        function updateReadings(obj,~,~)

            try

                obj.Readings(end+1).time = toc(obj.tStart);
                obj.Readings(end).gas = obj.hCenter2.readPressure(1);
                obj.Readings(end).rough = obj.hCenter2.readPressure(2);
                obj.Readings(end).chamber = obj.hGraphix3.readPressure(1);
    
                readings = obj.Readings;
                save(fullfile(obj.hBeamlineGUI.DataDir,'readings.mat'),'readings');
                if length(readings)>=100
                    plot(obj.hAxes,[readings(end-99:end).time],[readings(end-99:end).rough],'r-',[readings(end-99:end).time],[readings(end-99:end).gas],'g-',[readings(end-99:end).time],[readings(end-99:end).chamber],'b-');
                else
                    plot(obj.hAxes,[readings.time],[readings.rough],'r-',[readings.time],[readings.gas],'g-',[readings.time],[readings.chamber],'b-');
                end
                set(obj.hAxes,'YScale','log');
                xlabel(obj.hAxes,'Time [sec]');
                ylabel(obj.hAxes,'Pressure [torr]');
                title(obj.hAxes,'PRESSURE MONITOR (LAST 100 READINGS) - CLOSE WINDOW TO EXIT TEST');
                legend(obj.hAxes,'Rough Vac','Gas Line','Chamber','Location','northwest');

            catch MExc

                % Delete figure if error, triggering closeGUI callback
                delete(obj.hFigure);

                % Rethrow caught exception
                rethrow(MExc);

            end

        end

    end

end