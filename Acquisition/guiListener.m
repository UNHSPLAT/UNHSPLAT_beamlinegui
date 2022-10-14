classdef guiListener < handle
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here

    properties
        parent % Handle to beamline GUI
        listener %
        guiHand %
        fSetFunction = @(x) x%
        propertyName = ''%
        bufferTime = 0%
        buffer = timer%
    end

    methods

        function obj = guiListener(parent,propertyName,guiHand,fSetFunction)
            %UNTITLED Construct an instance of this class
            %   Detailed explanation goes here
            obj.parent = parent;
            % Add listener to update data when new readings are taken by main beamlineGUI
            obj.listener = listener(parent,...
                                propertyName,'PostSet',@obj.fTriggered);
            obj.guiHand = guiHand;
            obj.fSetFunction = fSetFunction;
            obj.propertyName = propertyName;

        end
    end

    methods 
        function fTriggered(obj,~,~)
            obj.fSetFunction(obj);
        end
    end
end

