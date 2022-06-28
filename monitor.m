classdef monitor < handle

    properties
        Tag string =""%
        textLabel string = ''% 
        unit string = ''%
        parent % 
        readFunc = @(x) NaN%function which takes the relevant instrument structure and outputs val of desired format
        setFunc = @(x) NaN%
        lastRead %
        guiHand = struct('statusGrpText',[],...
                         'statusGrpRead',[],...
                         'statusGrpSetText',[],...
                         'statusGrpSetField',[],...
                         'statusGrpSetBtn',[]...
                         ) %
        active = false %tag indicating if the monitor can be set (like a highvoltage power supply) or cant be set (like a pressure monitor)
    end

    methods
        function obj = monitor(varargin)
            %assign all properties provided
            if (nargin > 0)
                props = varargin(1:2:numel(varargin));
                vals = varargin(2:2:numel(varargin));
                for i=1:numel(props)
                    obj.(props{i})=vals{i};
                end
            end
        end

        function val = read(obj) 
            val = obj.readFunc(obj);
            obj.lastRead = val;
        end

        function set(obj,val)
            obj.setFunc(obj,val);
        end


        function guiSetCallback(obj,~,~)
            %DEFLBTNCALLBACK Sets Defl HVPS voltage based on user input
            % would like this to somehow remove this from the monitor class
            setVal = str2double(obj.guiHand.statusGrpSetField.String);
            %need to insert some error handling here
            obj.set(setVal);
            set(obj.guiHand.statusGrpSetField,'String','');
        end

        function setfield(obj,field,val)
            obj.(field) = val
        end

    end
end