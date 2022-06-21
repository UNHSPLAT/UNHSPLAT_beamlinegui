classdef monitor
    properties
        tag string %
        textLabel string % 
        unit string %
        instrument string % 
        readFunc %function which takes the relevant instrument structure and outputs val of desired format
        val

    end

    methods
        function obj = monitor(tag = '',textLabel='',unit='',instrument='',readFunc = [])
            obj.textLabel = textLabel
            obj.unit = unit
            obj.instrument = instrument
            obj.readFunc = readFunc
        end
    end
end

function monitors = setupMonitors
    monitors = struct(...
            'beamPressureGas',monitor()
            'beamPressureRough',
            'beamPressureIon1',
            'chamberPressureIon1',
            'chamberPressureIon2',
            'FaradayCup',
            'voltExbn',
            'voltExBp',
            'voltXsteer',
            'voltYsteer',
            'voltDefl',
            'voltMass',
            'voltSetMass',
            'voltExt',
            'voltLens'
    )

    %assign tags to instrument structures
    fields = fieldnames(instruments)
    for i=1:numel(fields)
        setfield(getfield(instruments,fields{i}),'Tag',fields{i})
end