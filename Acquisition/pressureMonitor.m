classdef pressureMonitor < acquisition
    % TODO: 1 - Test and uncomment hardware-dependent lines
    %FARADAYCUPVSEXBSWEEP Configures and runs a sweep of Faraday cup current vs ExB voltage

    properties (Constant)
        Type string = "Pressure Monitor" % Acquisition type identifier string
        Period double = 5 % Period of pressure readings in seconds
    end

    properties
        hCenter2 % Handle to Leybold Center 2 pressure gauge controller
        hGraphix3 % Handle to Leybold Graphix 3 pressure gauge controller
        hFigure % Handle to pressure readings figure
        hAxes % Handle to pressure readings axes
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

                tic;
                iR = 1;
                while isvalid(obj) && isvalid(obj.hFigure)
                    readings(iR).time = toc; %#ok<*AGROW> % Needs to grow on every loop iteration
                    readings(iR).rough = obj.hCenter2.readPressure(1);
                    readings(iR).gas = obj.hCenter2.readPressure(2);
                    readings(iR).chamber = obj.hGraphix3.readPressure(1);
                    save(fullfile(obj.hBeamlineGUI.DataDir,'readings.mat'),'readings');
                    plot(obj.hAxes,[readings.time],[readings.rough],'r-',[readings.time],[readings.gas],'g-',[readings.time],[readings.chamber],'b-');
                    set(obj.hAxes,'YScale','log');
                    xlabel(obj.hAxes,'Time [sec]');
                    ylabel(obj.hAxes,'Pressure [torr]');
                    title(obj.hAxes,'PRESSURE MONITOR - CLOSE WINDOW TO EXIT TEST');
                    legend(obj.hAxes,'Rough Vac','Gas Line','Chamber');
                    pause(obj.Period);
                    iR = iR+1;
                end

                hFig = figure;
                hAx = axes(hFig);
                plot(hAx,[readings.time],[readings.rough],'r-',[readings.time],[readings.gas],'g-',[readings.time],[readings.chamber],'b-');
                set(hAx,'YScale','log');
                xlabel(hAx,'Time [sec]');
                ylabel(hAx,'Pressure [torr]');
                title(hAx,'Pressure vs Time');
                legend(hAx,'Rough Vac','Gas Line','Chamber');

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

            % Delete obj
            delete(obj);

        end

    end

end