function monitors = setupMonitors(instruments)
    monitors = struct(...
            'beamPressureGas',monitor('PbeamGas','Beamline Gas Inflow Pressure','T',instruments.leyboldPressure1));
%              'beamPressureRough',
%             'beamPressureIon1',
%             'chamberPressureIon1',
%             'chamberPressureIon2',
%             'FaradayCup',
%             'voltExbn',
%             'voltExBp',
%             'voltXsteer',
%             'voltYsteer',
%             'voltDefl',
%             'voltMass',
%             'voltSetMass',
%             'voltExt',
%             'voltLens'
%     )

    %assign tags to instrument structures
%     fields = fieldnames(instruments)
%     for i=1:numel(fields)
%         setfield(getfield(instruments,fields{i}),'Tag',fields{i})
end