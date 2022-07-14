classdef monitorPlot < handle
    % TODO: 1 - Test and uncomment hardware-dependent lines
    %FARADAYCUPVSEXBSWEEP Configures and runs a sweep of Faraday cup current vs ExB voltage

    properties (Constant)
        Type string = "Pressure Monitor" % Acquisition type identifier string
    end

    properties (SetAccess = private)
        hFigure % Handle to readings figure
        Readings struct % Structure containing all readings
        ReadingsListener % Listener for beamlineGUI readings
        xMonStr%
        yMonStr%
        xvals = []%
        yvals = []
        panel%
        ax%
        hGUI %
    end

    methods
        function obj = monitorPlot(hGUI,panel,xMonStr,yMonStr)
            %BEAMLINEMONITOR Construct an instance of this class
            obj.hGUI = hGUI;
            obj.panel = panel;
            obj.xMonStr = xMonStr;
            obj.yMonStr = yMonStr;
            obj.ax = axes(panel);
            obj.pltVal();
            % Add listener to delete configuration GUI figure if main beamline GUI deleted
            %addlistener(obj.hBeamlineGUI,'ObjectBeingDestroyed',@obj.beamlineGUIDeleted);

        end
        
        function pltVal(obj)
            xr = obj.hGUI.Monitors.(obj.xMonStr).lastRead;
%             disp(xr);
%             obj.xvals(end+1) = [obj.hGUI.Monitors.(obj.xMonStr).lastRead];
%             obj.yvals(end+1) = obj.hGUI.Monitors.(obj.yMonStr).lastRead;
%             plot(obj.ax,obj.xvals,obj.yvals);
        end

        function beamlineGUIDeleted(obj,~,~)
            %BEAMLINEGUIDELETED Delete configuration GUI figure

            if isvalid(obj) && isvalid(obj.hFigure)
                delete(obj.hFigure);
            end

        end

        



    end

end