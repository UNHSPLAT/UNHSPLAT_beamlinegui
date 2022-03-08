classdef faradayCupStability < acquisition
    % TODO: 1 - Test and uncomment hardware-dependent lines
    %FARADAYCUPVSEXBSWEEP Configures and runs a sweep of Faraday cup current vs ExB voltage

    properties (Constant)
        Type string = "Faraday Cup Stability" % Acquisition type identifier string
        Period double = 5 % Period of current readings in seconds
    end

    properties
        hPico % Handle to Keithley picoammeter
        hFigure % Handle to pressure readings figure
        hAxes % Handle to pressure readings axes
    end

    methods
        function obj = faradayCupStability(hGUI)
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
            obj.hPico = obj.hBeamlineGUI.Hardware(contains([obj.hBeamlineGUI.Hardware.Tag],'Faraday','IgnoreCase',true)&strcmpi([obj.hBeamlineGUI.Hardware.Type],'Picoammeter'));
            if length(obj.hPico)~=1
                error('pressureMonitor:invalidTags','Invalid tags! Must be exactly one picoammeter available with tag containing ''Faraday''...');
            end

            % Create figure
            obj.hFigure = figure('MenuBar','none',...
                'ToolBar','none',...
                'NumberTitle','off',...
                'Name','Faraday Cup Current Monitor',...
                'DeleteFcn',@obj.closeGUI);

            obj.hAxes = axes(obj.hFigure);

            % Retrieve config info
            operator = obj.hBeamlineGUI.TestOperator;
            gasType = obj.hBeamlineGUI.GasType;
            testSequence = obj.hBeamlineGUI.TestSequence;

            % Save config info
            save(fullfile(obj.hBeamlineGUI.DataDir,'config.mat'),'operator','gasType','testSequence');

            try

                tic;
                iR = 1;
                while isvalid(obj) && isvalid(obj.hFigure)
                    readings(iR).time = toc; %#ok<*AGROW> % Needs to grow on every loop iteration
                    readings(iR).faraday = obj.hPico.read;
                    save(fullfile(obj.hBeamlineGUI.DataDir,'readings.mat'),'readings');
                    plot(obj.hAxes,[readings.time],[readings.faraday],'r-');
                    set(obj.hAxes,'YScale','log');
                    xlabel(obj.hAxes,'Time [sec]');
                    ylabel(obj.hAxes,'Current [A]');
                    title(obj.hAxes,'FARADAY CUP MONITOR - CLOSE WINDOW TO EXIT TEST');
                    pause(obj.Period);
                    iR = iR+1;
                end

                hFig = figure;
                hAx = axes(hFig);
                plot(hAx,[readings.time],[readings.faraday],'r-');
                set(hAx,'YScale','log');
                xlabel(hAx,'Time [sec]');
                ylabel(hAx,'Current [A]');
                title(hAx,'Faraday Cup Current vs Time');

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