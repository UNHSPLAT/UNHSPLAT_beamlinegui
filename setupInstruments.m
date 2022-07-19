 function instruments = setupInstruments

    % Define configuration funcitons to be executed on connection

    %Config Multimeter
    function config_keithleyMultimeter(hDMM)
        if hDMM.Connected
            hDMM.devRW('SENS:FUNC "VOLT", (@101:103)');
            hDMM.devRW('SENS:VOLT:INP MOHM10, (@101:103)');
            hDMM.devRW('SENS:VOLT:NPLC 1, (@101:103)');
            hDMM.devRW('ROUT:SCAN:CRE (@101:103)');
        end
    end

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

    % Config Power Supplies
    function self = config_pwrsupply(self)
        self.setVSet(0);
    end

    % Generate list of available hardware
    visaList = get_visadevlist();
    instruments = struct("leyboldPressure1",leyboldCenter2("ASRL7::INSTR",visaList),...
                         "leyboldPressure2",leyboldGraphix3("ASRL8::INSTR",visaList),...
                         "leyboldPressure3",leyboldGraphix3("ASRL10::INSTR",visaList),...
                         "picoFaraday",keithley6485('GPIB0::14::INSTR',visaList,@config_picoFaraday),...
                         "HvExbn",srsPS350('GPIB0::19::INSTR',visaList,@config_pwrsupply),...
                         "HvExbp",srsPS350('GPIB0::15::INSTR',visaList,@config_pwrsupply),...
                         "HvEsa",srsPS350('GPIB0::16::INSTR',visaList,@config_pwrsupply),...
                         "HvDefl",srsPS350('GPIB0::17::INSTR',visaList,@config_pwrsupply),...
                         "HvYsteer",srsPS350('GPIB0::18::INSTR',visaList,@config_pwrsupply),...
                         "LvMass",keysightE36313A('GPIB0::5::INSTR',visaList),...
                         "keithleyMultimeter1",keithleyDAQ6510('USB0::0x05E6::0x6510::04524689::0::INSTR',...
                                                               visaList,@config_keithleyMultimeter)...
                         );
    
    %assign tags to instrument structures
    fields = fieldnames(instruments);
    for i=1:numel(fields)
        instruments.(fields{i}).Tag = fields{i};
    end
end