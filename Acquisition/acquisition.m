classdef acquisition < handle
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here

    properties
        hBeamlineGUI % Handle to beamline GUI
    end

    properties (Abstract, Constant)
        Type string
    end

    methods

        function obj = acquisition(hGUI)
            %UNTITLED Construct an instance of this class
            %   Detailed explanation goes here
            obj.hBeamlineGUI = hGUI;
        end

    end

    methods (Abstract)
        runSweep(obj)
    end

end

