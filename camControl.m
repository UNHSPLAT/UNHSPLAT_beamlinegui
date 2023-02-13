classdef camControl < handle

    properties
        Tag string =""%
        textLabel string = ""% 
        unit string = ""%
    end
    properties (SetObservable) 
        figmanager%
        datamanager%
        uimanager%
        timer%
    end

    methods
        function obj = camControl(varargin)
            % Initialize Webcam
            try cam = webcam; %cam.ColorEnable = 0;
            catch
                link = 'https://www.mathworks.com/matlabcentral/fileexchange/45182-matlab-support-package-for-usb-webcams';
                error(['Missing MATLAB Support Package for USB Webcams!' ...
                    '\nSee <a href="' link '">' link '</a> for installation information%s'],"")
            end
            
            if ~isfolder("input\")
                mkdir input\
            end
            addpath(genpath('.'));
            
            % Initialize Figure, UI, and Data Manager objects
            obj.figmanager = FigureManager(cam);
            obj.uimanager = UIManager(cam);
            obj.datamanager = DataManager(obj.figmanager,obj.uimanager,cam);
            connectComponents(obj.uimanager,obj.figmanager,obj.datamanager);
            
            % Test if using supported gpu
            try
                gpuDevice;
                obj.datamanager.gpuSupport = true;
                warning("NVIDIA GPU Detected, activated GPU acceleration")
            catch
                obj.datamanager.gpuSupport = false;
            end
            
            % Run Main Loop
            obj.datamanager.setupPreview;
            
            % initialize timer to execute peakfinding
            obj.timer =  timer('Period',.5,... %period
                      'ExecutionMode','fixedSpacing',... %{singleShot,fixedRate,fixedSpacing,fixedDelay}
                      'BusyMode','queue',... %{drop, error, queue}
                      'StartDelay',0,...
                      'TimerFcn',@obj.update ...
                      );

            start(obj.timer);
            
        end

        function update(obj,~,~)
            obj.datamanager.mainLoop;
        end

        function shutdown(obj,~,~)
            close(obj.figmanager.RecordingFigure);
            close(obj.figmanager.RateGraphFigure);
            close(obj.figmanager.PreviewFigure);
            close(obj.uimanager.WebcamUIFigure);
            stop(obj.timer);
        end

        function restart(obj,~,~)
            obj.shutdown();
            obj = camControl;
        end

    end
end


