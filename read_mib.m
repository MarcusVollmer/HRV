function [record, Fs, StartDate, header] = read_mib(fname)
% Read machine-independent beat file
%
% Reads the header and beat information. 
%
% HEADER RECORD
% Delimetered rows (delimiter:'=') of variable and value.
% Includes a line with variable 'Start time', 'First beat', and 'samples
% per second'. Ends with 'End header'.
% Maximum header length: 100 rows.
% 
% DATA RECORD
% Each beat one row with single character given the beat annotation (e.g.
% 'Q' means regular beat) and a floating number in milliseconds.
% You may use the following codes:
%  - Q means normal beat
%  - V means VPC (ventricular premature contraction)
%  - A means APC (atrial premature contraction)
%  - Z means noise
%
%   MIT License (MIT) Copyright (c) 2019 Marcus Vollmer,
%   marcus.vollmer@uni-greifswald.de
%   Feel free to contact me for discussion, proposals and issues.
%   last modified: 11 June 2019
%   version: 0.03


% HEADER
    opts = delimitedTextImportOptions("NumVariables", 2);

  % Specify range and delimiter
    opts.DataLines = [1, 100];
    opts.Delimiter = "=";

  % Specify column names and types
    opts.VariableNames = ["Variable", "Value"];
    opts.VariableTypes = ["string", "string"];
    opts = setvaropts(opts, [1, 2], "WhitespaceRule", "preserve", "EmptyFieldRule", "auto");
    opts.ExtraColumnsRule = "ignore";
    opts.EmptyLineRule = "read";

    header = readtable(fname, opts);
    clear opts
  % Search for header end
    end_header = find(header.Variable=="End header");
    
    header = header(1:end_header-1,:);
    Fs = double(header.Value(header.Variable=="Samples per second"));
    
  % Identify date format
    StartDate = [header.Value{header.Variable=="Start date"} ' ' header.Value{header.Variable=="Start time"}];
    FirstBeat = [header.Value{header.Variable=="Start date"} ' ' header.Value{header.Variable=="First beat"}];
    switch length(strfind(StartDate, ':')) + length(strfind(StartDate, '.'))
        case 1
            StartDate = datetime(StartDate, 'InputFormat','dd-MMM-yy HH:mm');
        case 2
            StartDate = datetime(StartDate, 'InputFormat','dd-MMM-yy HH:mm:ss');
        case 3
            StartDate = datetime(StartDate, 'InputFormat','dd-MMM-yy HH:mm:ss.SSS');
        otherwise
            error('Error. \nYour start date is not in a proper date format (''HH:mm'' or ''HH:mm:ss'' or ''HH:mm:ss.SSS''). The date format stored in your file is %s.', StartDate)   
    end
    switch length(strfind(FirstBeat, ':')) + length(strfind(FirstBeat, '.'))
        case 1
            FirstBeat = datetime(FirstBeat, 'InputFormat','dd-MMM-yy HH:mm');
        case 2
            FirstBeat = datetime(FirstBeat, 'InputFormat','dd-MMM-yy HH:mm:ss');
        case 3
            FirstBeat = datetime(FirstBeat, 'InputFormat','dd-MMM-yy HH:mm:ss.SSS');
        otherwise
            error('Error. \nYour first beat date is not in a proper date format (''HH:mm'' or ''HH:mm:ss'' or ''HH:mm:ss.SSS''). The date format stored in your file is %s.', FirstBeat)   
    end   
    FirstBeatOffset = round(seconds(FirstBeat-StartDate)*Fs)/Fs;
    
    
% Read beat locations
    fid = fopen(fname,'r');
    dataArray = textscan(fid, '%1s%s%[^\n\r]', 'Delimiter', '', 'WhiteSpace', '', 'TextType', 'string', 'HeaderLines' ,end_header, 'ReturnOnError', false, 'EndOfLine', '\r\n');
    fclose(fid);
    
  % for filtering purposes and interrupting recordings
    labels = categorical(dataArray{1}); 
    periods = find(labels=='#');
    
    RR = double(dataArray{2});   
    
    record = struct;
    record.header = header;
    record.Fs = Fs;
    nextdays = 0;
    if isempty(periods)
      % non-stop recording
        record.Ann = round(cumsum([FirstBeatOffset; RR])*Fs/1000); % as frames
        record.RR = diff(Ann); % as frames  
        record.labels = labels;
    else
      % interrupting recordings
        periods = [0;periods;length(RR)];
        for i=1:length(periods)-1
            if i==1
                FirstBeat_local = FirstBeat;
            elseif i==2
                FirstBeat_local = datetime([header.Value{header.Variable=="Start date"} dataArray{2}{periods(i)}], 'InputFormat','dd-MMM-yy HH:mm:ss.SSS');
                if rem(datenum(FirstBeat_local),1)<rem(datenum(FirstBeat),1)
                    nextdays = nextdays+1;             
                end
                FirstBeat_local = FirstBeat_local+nextdays;
            else 
                FirstBeat_local = datetime([header.Value{header.Variable=="Start date"} dataArray{2}{periods(i)}], 'InputFormat','dd-MMM-yy HH:mm:ss.SSS');
                if datetime(dataArray{2}{periods(i)}, 'InputFormat','HH:mm:ss.SSS') < datetime(dataArray{2}{periods(i-1)}, 'InputFormat','HH:mm:ss.SSS')
                    nextdays = nextdays+1;                    
                end
                FirstBeat_local = FirstBeat_local+nextdays;
            end
            range = periods(i)+1:periods(i+1)-1;
            fieldname = matlab.lang.makeValidName(datestr(FirstBeat_local));
            record.RR.(fieldname) = table(...
                FirstBeat_local+seconds(cumsum(RR(range))/1000), ...
                round(Fs*cumsum(RR(range)/1000)), ...
                labels(range), ... 
                round(Fs*RR(range)/1000), ...                               
                'VariableNames',{'Date','Ann','label','RR'});
            %record.RR.(fieldname).RR(1) = NaN;
            record.RR.(fieldname).Date.Format = 'dd.MM.uuuu HH:mm:ss.SSS';            
        end
    end
end