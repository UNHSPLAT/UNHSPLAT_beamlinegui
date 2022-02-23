classdef faradayCupVsExbSweep < acquisition
    %UNTITLED2 Summary of this class goes here
    %   Detailed explanation goes here

    properties (Constant)
        Type string = "Faraday cup vs ExB Sweep"
        MinDefault double = 100
        MaxDefault double = 5000
        StepsDefault double = 20
        DwellDefault double = 10
    end

    properties
        hExb
        hFaraday
        hFigure
        hMinText
        hMinEdit
        hStepsText
        hStepsEdit
        hSpacingEdit
        hMaxText
        hMaxEdit
        hDwellText
        hDwellEdit
        hSweepBtn
        VPoints double
        DwellTime double
    end

    methods
        function obj = faradayCupVsExbSweep(hGUI)
            %UNTITLED2 Construct an instance of this class
            %   Detailed explanation goes here
            obj@acquisition(hGUI);
        end

        function runSweep(obj)
            
            % % Find ExB power supply
            % obj.hExb = hBeamlineGUI.Hardware(contains(hBeamlineGUI.Hardware.Tag,'ExB')&strcmp(hBeamlineGUI.Hardware.Type,'Power Supply'));
            % if length(hExb)~=1
            %     error('faradayCupVsExbSweep:invalidTags','Invalid tags! Must be exactly one power supply available with tag containing ''ExB''...');
            % end
            %
            % % Find Faraday cup picoammeter
            % obj.hFaraday = hBeamlineGUI.Hardware(contains(hBeamlineGUI.Hardware.Tag,'Faraday')&strcmp(hBeamlineGUI.Hardware.Type,'Picoammeter'));
            % if length(hFaraday)~=1
            %     error('faradayCupVsExbSweep:invalidTags','Invalid tags! Must be exactly one picoammeter available with tag containing ''Faraday''...');
            % end
            
            % Create figure
            obj.hFigure = figure('MenuBar','none',...
                'ToolBar','none',...
                'Resize','off',...
                'Position',[400,160,300,185],...
                'NumberTitle','off',...
                'Name','ExB Sweep Config',...
                'DeleteFcn',@obj.deleteFigure);
            
            % Set positions
            ystart = 155;
            ypos = ystart;
            ysize = 20;
            ygap = 16;
            xpos = 30;
            xtextsize = 100;
            xeditsize = 60;
            
            % Create components
            obj.hMinText = uicontrol(obj.hFigure,'Style','text',...
                'Position',[xpos,ypos,xtextsize,ysize],...
                'String','Min Voltage [V]: ',...
                'FontSize',8,...
                'HorizontalAlignment','center');
            
            ypos = ypos-ysize;
            
            obj.hMinEdit = uicontrol(obj.hFigure,'Style','edit',...
                'Position',[xpos+(xtextsize-xeditsize)/2,ypos,xeditsize,ysize],...
                'String',num2str(obj.MinDefault),...
                'HorizontalAlignment','right');
            
            ypos = ypos-ysize-ygap;
            
            obj.hStepsText = uicontrol(obj.hFigure,'Style','text',...
                'Position',[xpos,ypos,xtextsize,ysize],...
                'String','Number of Steps: ',...
                'FontSize',8,...
                'HorizontalAlignment','center');
            
            ypos = ypos-ysize;
            
            obj.hStepsEdit = uicontrol(obj.hFigure,'Style','edit',...
                'Position',[xpos+(xtextsize-xeditsize)/2,ypos,xeditsize,ysize],...
                'String',num2str(obj.StepsDefault),...
                'HorizontalAlignment','right');
            
            ypos = ypos-ysize*2;
            
            obj.hSpacingEdit = uicontrol(obj.hFigure,'Style','checkbox',...
                'Position',[xpos-10,ypos,xtextsize+20,ysize],...
                'String',' Logarithmic Spacing',...
                'Value',1,...
                'HorizontalAlignment','right');
            
            ypos = ystart;
            xpos = 170;
            
            obj.hMaxText = uicontrol(obj.hFigure,'Style','text',...
                'Position',[xpos,ypos,xtextsize,ysize],...
                'String','Max Voltage [V]: ',...
                'FontSize',8,...
                'HorizontalAlignment','center');
            
            ypos = ypos-ysize;
            
            obj.hMaxEdit = uicontrol(obj.hFigure,'Style','edit',...
                'Position',[xpos+(xtextsize-xeditsize)/2,ypos,xeditsize,ysize],...
                'String',num2str(obj.MaxDefault),...
                'HorizontalAlignment','right');
            
            ypos = ypos-ysize-ygap;
            
            obj.hDwellText = uicontrol(obj.hFigure,'Style','text',...
                'Position',[xpos,ypos,xtextsize,ysize],...
                'String','Dwell Time [s]: ',...
                'FontSize',8,...
                'HorizontalAlignment','center');
            
            ypos = ypos-ysize;
            
            obj.hDwellEdit = uicontrol(obj.hFigure,'Style','edit',...
                'Position',[xpos+(xtextsize-xeditsize)/2,ypos,xeditsize,ysize],...
                'String',num2str(obj.DwellDefault),...
                'HorizontalAlignment','right');
            
            ypos = ypos-ysize*2-ygap;
            
            obj.hSweepBtn = uicontrol(obj.hFigure,'Style','pushbutton',...
                'Position',[xpos,ypos,xtextsize,ysize+ygap],...
                'String','RUN SWEEP',...
                'FontSize',10,...
                'FontWeight','bold',...
                'HorizontalAlignment','center',...
                'Callback',@obj.sweepBtnCallback);

%             waitfor(obj.hFigure); % not sure i need this

        end
    end

    methods (Access = private)

        function sweepBtnCallback(obj,~,~)

            minVal = str2double(obj.hMinEdit.String);
            maxVal = str2double(obj.hMaxEdit.String);
            stepsVal = str2double(obj.hStepsEdit.String);
            dwellVal = str2double(obj.hDwellEdit.String);

            if isnan(minVal) || isnan(maxVal) || isnan(stepsVal) || isnan(dwellVal)
                errordlg('All fields must be filled with a valid numeric entry!','User input error!');
                return
            elseif minVal > maxVal || minVal < 0 || maxVal < 0
                errordlg('Invalid min and max voltages! Must be increasing positive values.','User input error!');
                return
%             elseif maxVal > obj.hExb.VMax || minVal < obj.hExb.VMin
%                 errordlg('Invalid min and max voltages! Cannot exceed power supply range of %g to %g V',obj.hExb.VMin,obj.hExb.VMax);
%                 return
            end

            spacingVal = logical(obj.hSpacingEdit.Value);

            if spacingVal
                obj.VPoints = logspace(log10(minVal),log10(maxVal),stepsVal);
            else
                obj.VPoints = linspace(minVal,maxVal,stepsVal);
            end



        end

        function deleteFigure(obj,~,~)



        end

    end

end