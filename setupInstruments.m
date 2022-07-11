function instruments = setupInstruments

    instruments = struct("leyboldPressure1",leyboldCenter2("ASRL7::INSTR"),...
                         "leyboldPressure2",leyboldGraphix3("ASRL8::INSTR"),...
                         "leyboldPressure3",leyboldGraphix3("ASRL10::INSTR"),...
                         "picoFaraday",keithley6485('GPIB0::14::INSTR'),...
                         "HvExbn",srsPS350('GPIB0::19::INSTR'),...
                         "HvExbp",srsPS350('GPIB0::15::INSTR'),...
                         "HvEsa",srsPS350('GPIB0::16::INSTR'),...
                         "HvDefl",srsPS350('GPIB0::17::INSTR'),...
                         "HvYsteer",srsPS350('GPIB0::18::INSTR'),...
                         "LvMass",keysightE36313A('GPIB0::5::INSTR'),...
                         "keithleyMultimeter1",keithleyDAQ6510('USB0::0x05E6::0x6510::04524689::0::INSTR')...
                         );
    %assign tags to instrument structures
    fields = fieldnames(instruments);
    %visaList = get_visadevlist();
    for i=1:numel(fields)
        instruments.(fields{i}).Tag = fields{i};
        %instruments.(fields{i}).resourcelist = visaList;
        %instruments.(fields{i}).connectDevice();
    end
end