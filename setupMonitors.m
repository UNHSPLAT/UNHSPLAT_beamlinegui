function monitors = setupMonitors(instruments)
    % Function initializing and defining properties of measured values


    % =======================================================================
    % define read functions monitors will call to manipulate instrument output 
    % =======================================================================
    function val = read_srsHVPS(self)
        val = self.parent.measV;
    end
 
    % =======================================================================
    % define set functions monitors will use to set parameters
    % =======================================================================
    function set_srsHVPS(self,volt)

        if volt ==0
            volt =2;
        end
        if isnan(volt)
            errordlg('A valid voltage value must be entered!','Invalid input!');
            return
        elseif abs(volt) > abs(self.parent.VMax) || abs(volt) < abs(self.parent.VMin)
            errordlg(['Defl voltage setpoint must be between ',num2str(hDefl.VMin),' and ',num2str(hDefl.VMax),' V!'],'Invalid input!');
            return
        end    

        function stop_func(src,evt)
            self.read();
            self.lock = false;
        end
        self.lock = true;
        %check the voltage being applied and ramp the voltage in steps if need be
        minstep = 50;
        if abs(volt)-abs(self.lastRead)>minstep
            multivolt = linspace(self.lastRead,volt,ceil((abs(volt)-abs(self.lastRead))/minstep)+1);
            multivolt = multivolt(2:end);
            self.monTimer = timer('Period',minstep/(2000/60),... %period
                      'ExecutionMode','fixedSpacing',... %{singleShot,fixedRate,fixedSpacing,fixedDelay}
                      'BusyMode','queue',... %{drop, error, queue}
                      'TasksToExecute',numel(multivolt),...          
                      'StartDelay',0,...
                      'TimerFcn',@(src,evt)self.parent.setVSet(multivolt(get(src,'TasksExecuted'))),...
                      'StartFcn',@(src,evt)setfield( self , 'lock' , true ),...
                      'StopFcn',@stop_func,...
                      'ErrorFcn',@stop_func);
            start(self.monTimer);
        else
            self.parent.setVSet(volt);
            self.lock = false;
        end
    end

    function set_MFC(self,volt)
        if volt <.2
            self.parent(2).setVSet(volt,1)
        else
            errordlg('A valid voltage value must be entered!','Invalid input!');
        end
    end
    

    % =======================================================================
    % Define level 1 monitors and set parameters 
    %   monitors that dont have parent instruments (such as a datetime measurement)
    %   to pull parameters from should assign 
    %       - parent = struct("Type",'local','Connected',true)
    %   to bypass instrument connection checks correctly
    % =======================================================================
    monitors = struct(...       
                'voltChicane4',monitor('readFunc',@read_srsHVPS,...
                                     'setFunc',@set_srsHVPS,...
                                     'textLabel','Chicane Voltage 4',...
                                     'unit','V',...
                                     'active',true,...
                                     'formatSpec','%.0f',...
                                     'group','Chicane',...
                                     'parent',instruments.HvChicane4...
                                     ),...
                'voltChicane2',monitor('readFunc',@read_srsHVPS,...
                                     'setFunc',@set_srsHVPS,...
                                     'textLabel','Chicane Voltage 2',...
                                     'unit','V',...
                                     'active',true,...
                                     'formatSpec','%.0f',...
                                     'group','Chicane',...
                                     'parent',instruments.HvChicane2...
                                     ),...
                 'voltDefl',monitor('readFunc',@read_srsHVPS,...
                                     'setFunc',@set_srsHVPS,...
                                     'textLabel','Defl Voltage',...
                                     'unit','V',...
                                     'active',true,...
                                     'formatSpec','%.0f',...
                                     'group','HV',...
                                     'parent',instruments.HvDefl...
                                     ),...
                 'voltXsteer',monitor('readFunc',@read_srsHVPS,...
                                     'setFunc',@set_srsHVPS,...
                                     'textLabel','X-Steer Voltage',...
                                     'unit','V',...
                                     'active',true,...
                                     'formatSpec','%.0f',...
                                     'group','HV',...
                                     'parent',instruments.HvEsa...
                                     ),...
                 'voltYsteer',monitor('readFunc',@read_srsHVPS,...
                                     'setFunc',@set_srsHVPS,...
                                     'textLabel','Y-Steer Voltage',...
                                     'unit','V',...
                                     'active',true,...
                                     'formatSpec','%.0f',...
                                     'group','HV',...
                                     'parent',instruments.HvYsteer...
                                     ),...
                 'voltExbn',monitor('readFunc',@read_srsHVPS,...
                                     'setFunc',@(self,x) set_srsHVPS(self,-abs(x)),...
                                     'textLabel','ExB- Voltage',...
                                     'unit','V',...
                                     'active',true,...
                                     'formatSpec','%.0f',...
                                     'group','HV',...
                                     'parent',instruments.HvExbn...
                                     ),...
                 'voltExbp',monitor('readFunc',@read_srsHVPS,...
                                     'setFunc',@set_srsHVPS,...
                                     'textLabel','ExB+ Voltage',...
                                     'unit','V',...
                                     'active',true,...
                                     'formatSpec','%.0f',...
                                     'parent',instruments.HvExbp...
                                     ),...
                 'voltExt',monitor('readFunc',@(x) abs(x.parent.performScan(1,1)*4000),...
                                     'textLabel','Extraction Voltage',...
                                     'unit','V',...
                                     'formatSpec','%.0f',...
                                     'group','HV',...
                                     'parent',instruments.keithleyMultimeter1...
                                     ),...
                 'voltLens',monitor('readFunc',@(x) abs(x.parent.performScan(2,2)*1000),...
                                     'textLabel','Lens Voltage',...
                                     'unit','V',...
                                     'group','HV',...
                                     'formatSpec','%.0f',...
                                     'parent',instruments.keithleyMultimeter1...
                                     ),...
                 'voltMFC',monitor('readFunc',@(x) x.parent(1).performScan(3,3),...
                                     'setFunc',@set_MFC,...
                                     'textLabel','MFC Voltage',...
                                     'unit','V',...
                                     'active',true,...
                                     'group','LV',...
                                     'parent',[instruments.keithleyMultimeter1,...
                                                instruments.LvMass]...
                                     ),...
                 'pressureBeamTTR',monitor('readFunc',@(x) x.parent.readPressure(2),...
                                     'textLabel','Beam Pressure TTR',...
                                     'unit','T',...
                                     'group','pressure',...
                                     'parent',instruments.leyboldPressure1...
                                     ),...
                 'pressureSourceGas',monitor('readFunc',@(x) x.parent.readPressure(1),...
                                     'textLabel','Source Gas Inflow Pressure',...
                                     'unit','T',...
                                     'formatSpec','%.2f',...
                                     'group','pressure',...
                                     'parent',instruments.leyboldPressure1...
                                     ),...
                 'pressureBeamTurboRough',monitor('readFunc',@(x) x.parent.readPressure(3),...
                                     'textLabel','Beam Turbo Rough Pressure',...
                                     'unit','T',...
                                     'group','pressure',...
                                     'parent',instruments.leyboldPressure3...
                                     ),...
                 'pressureBeamIG2',monitor('readFunc',@(x) x.parent.readPressure(2),...
                                     'textLabel','Beam Pressure (IG2)',...
                                     'unit','T',...
                                     'group','pressure',...
                                     'parent',instruments.leyboldPressure3...
                                     ),...
                 'pressureBeamIG1',monitor('readFunc',@(x) x.parent.readPressure(1),...
                                     'textLabel','Beam Pressure (IG1)',...
                                     'unit','T',...
                                     'group','pressure',...
                                     'parent',instruments.leyboldPressure3...
                                     ),...
                 'pressureChamberIG2',monitor('readFunc',@(x) x.parent.readPressure(3),...
                                     'textLabel','Chamber Pressure (IG2)',...
                                     'unit','T',...
                                     'group','pressure',...
                                     'parent',instruments.leyboldPressure2...
                                     ),...
                 'pressureChamberIG1',monitor('readFunc',@(x) x.parent.readPressure(2),...
                                     'textLabel','Chamber Pressure (IG1)',...
                                     'unit','T',...
                                     'group','pressure',...
                                     'parent',instruments.leyboldPressure2...
                                     ),...
                 'pressureChamberRough1',monitor('readFunc',@(x) x.parent.readPressure(1),...
                                     'textLabel','Chamber Rough Pressure (TTR1)',...
                                     'unit','T',...
                                     'group','pressure',...
                                     'parent',instruments.leyboldPressure2...
                                     ),...
                  'dateTime',monitor('readFunc',@(x) datetime(now(),'ConvertFrom','datenum'),...
                                     'textLabel','Date Time',...
                                     'unit','D-M-Y H:M:S',...
                                     'parent',struct("Type",'local','Connected',true),...
                                     'formatSpec',"%s"...
                                     ),...
                  'T',monitor('readFunc',@(x) now(),...
                                     'textLabel','Time',...
                                     'unit','DateNum',...
                                     'parent',struct("Type",'local','Connected',true),...
                                     'formatSpec',"%d"...
                                     ),...
                  'Ifaraday',monitor('readFunc',@(x) x.parent.read(),...
                                     'textLabel','I Faraday Cup',...
                                     'unit','A',...
                                     'formatSpec','%.3e',...
                                     'parent',instruments.picoFaraday...
                                     )...
                 );
    
    % =======================================================================
    % Level 2 monitor read functions
    % =======================================================================
    function val = read_voltEXB(self)
        voltExbp = self.siblings(1).lastRead();
        voltExbn = self.siblings(2).lastRead();
        val = voltExbp-voltExbn;
    end

    function C = calc_C()
        % Reference species location
        % will be expanded with full calibration data
        Mcal = 12; 
        VexbCal = 912;
        VextCal = 10000;
        C = VexbCal/(VextCal/Mcal)^(1/2);
    end

    function val = read_Mass(self)
        voltExt = self.siblings(1).lastRead();
        voltEXB = self.siblings(2).lastRead();
        val = (calc_C*voltExt^(1/2)/voltEXB)^2;
    end

    % =======================================================================
    % Level 2 monitor set functions
    % =======================================================================
    function set_Mass(self,M)
        voltExt = self.siblings(1).lastRead();
        monEXB = self.siblings(2);
        monXsteer = self.siblings(3);
        monYsteer = self.siblings(4);
        x_ratio = 375/10000; %Calibrated x-steer ratio
        y_ratio = 25/10000; %Calibrated y-steer ratio
        
        % set x-steer voltage to nom value
        monXsteer.set(voltExt*x_ratio);

        % set y-steer voltage to nom value
        monYsteer.set(voltExt*y_ratio);

        % set ExB voltage to desired mass
        monEXB.set(calc_C*(voltExt/M)^(1/2))
    end

    function set_voltEXB(self,volt)
        disp(volt);
        monVoltExbp = self.siblings(1);
        monVoltExbn = self.siblings(2);
        monVoltExbp.set(volt/2);
        monVoltExbn.set(volt/2);

        % get the siblings ramp timers and locks
        self.monTimer = self.siblings.monTimer;
        self.lock = self.siblings.lock;
        function stop_func(varargin)
            self.lock = false;
        end
        set(self.monTimer,'StopFcn',@stop_func);
    end
    % =======================================================================
    % Setup level 2 monitors (Derrive values from sibling monitors)
    %   - level 2 monitors may utilize sibling monitors to read or set values
    %   - because these are referential to other monitors assignment order matters
    % =======================================================================
    monitors.voltExB = monitor('readFunc',@read_voltEXB,...
                                     'setFunc',@set_voltEXB,...
                                     'textLabel','ExB Voltage',...
                                     'unit','V',...
                                     'active',true,...
                                     'formatSpec','%.0f',...
                                     'group','HV',...
                                     'parent',[instruments.HvExbp,instruments.HvExbn],...
                                     'siblings',[monitors.voltExbp,monitors.voltExbn]...
                                     );

    monitors.M = monitor('readFunc',@read_Mass,...
                                     'setFunc',@set_Mass,...
                                     'textLabel','Target Mass',...
                                     'unit','AMU',...
                                     'active',true,...
                                     'formatSpec','%.3f',...
                                     'parent',[instruments.HvExbp,...
                                                instruments.HvExbn,...
                                                instruments.keithleyMultimeter1],...
                                     'siblings',[monitors.voltExt,...
                                                monitors.voltExB,...
                                                monitors.voltXsteer,...
                                                monitors.voltYsteer]...
                                     );

    %assign tags to instrument tag parameters, may just want to have these and the 
    %   instrument structs setup as lists
     fields = fieldnames(monitors);
     for i=1:numel(fields)
         monitors.(fields{i}).setfield('Tag',fields{i});
     end
end