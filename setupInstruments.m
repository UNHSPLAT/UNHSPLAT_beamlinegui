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

    % Set multimeter configure route
    function config_keithleyMultimeter(hDMM)
        if hDMM.Connected
            hDMM.devRW('SENS:FUNC "VOLT", (@101:103)');
            hDMM.devRW('SENS:VOLT:INP MOHM10, (@101:103)');
            hDMM.devRW('SENS:VOLT:NPLC 1, (@101:103)');
            hDMM.devRW('ROUT:SCAN:CRE (@101:103)');
        end
    end
    config_keithleyMultimeter(instruments.keithleyMultimeter1)
    % Configure picoammeter
    function config_picoFaraday(hFaraday)
        if hFaraday.Connected
            hFaraday.Tag = "Faraday";
            hFaraday.devRW(':SYST:ZCH OFF');
            dataOut = strtrim(hFaraday.devRW(':SYST:ZCH?'));
            while ~strcmp(dataOut,'0')
                warning('beamlineGUI:keithleyNonresponsive','Keithley not listening! Zcheck did not shut off as expected...');
                hFaraday.devRW(':SYST:ZCH OFF');
                dataOut = strtrim(hFaraday.devRW(':SYST:ZCH?'));
            end
            hFaraday.devRW('ARM:COUN 1');
            dataOut = strtrim(hFaraday.devRW('ARM:COUN?'));
            while ~strcmp(dataOut,'1')
                warning('beamlineGUI:keithleyNonresponsive','Keithley not listening! Arm count did not set to 1 as expected...');
                hFaraday.devRW('ARM:COUN 1');
                dataOut = strtrim(hFaraday.devRW('ARM:COUN?'));
            end
            hFaraday.devRW('FORM:ELEM READ');
            dataOut = strtrim(hFaraday.devRW('FORM:ELEM?'));
            while ~strcmp(dataOut,'READ')
                warning('beamlineGUI:keithleyNonresponsive','Keithley not listening! Output format not set to ''READ'' as expected...');
                hFaraday.devRW('FORM:ELEM READ');
                dataOut = strtrim(hFaraday.devRW('FORM:ELEM?'));
            end
            hFaraday.devRW(':SYST:LOC');
        end
    end
    config_picoFaraday(instruments.picoFaraday)
    %assign tags to instrument structures
    fields = fieldnames(instruments);
    %visaList = get_visadevlist();
    for i=1:numel(fields)
        instruments.(fields{i}).Tag = fields{i};
        %instruments.(fields{i}).resourcelist = visaList;
        %instruments.(fields{i}).connectDevice();
    end
end