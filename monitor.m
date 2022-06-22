classdef monitor
    properties
        tag string %
        textLabel string % 
        unit string %
        instrument % 
        readF %function which takes the relevant instrument structure and outputs val of desired format
        val

    end

    methods
        function obj = monitor(tag,textLabel,unit,instrument)
            obj.textLabel = textLabel;
            obj.unit = unit;
            obj.instrument = instrument;
            obj.tag = tag;
        end
    end
end