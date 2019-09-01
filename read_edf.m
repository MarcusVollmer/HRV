function [record, signals, start_date, header, header2] = read_edf(fname, qdl, memory)
% Read European Data Format
%
% Reads the signals information and raw signal data stored in a binary file
% with EDF specifications as definded in the original paper [1]. 
%
% HEADER RECORD
% 8 ascii : version of this data format (0)
% 80 ascii : local patient identification (mind item 3 of the additional EDF+ specs)
% 80 ascii : local recording identification (mind item 4 of the additional EDF+ specs)
% 8 ascii : startdate of recording (dd.mm.yy) (mind item 2 of the additional EDF+ specs)
% 8 ascii : starttime of recording (hh.mm.ss)
% 8 ascii : number of bytes in header record
% 44 ascii : reserved
% 8 ascii : number of data records (-1 if unknown, obey item 10 of the additional EDF+ specs)
% 8 ascii : duration of a data record, in seconds
% 4 ascii : number of signals (ns) in data record 
% ns * 16 ascii : ns * label (e.g. EEG Fpz-Cz or Body temp) (mind item 9 of the additional EDF+ specs)
% ns * 80 ascii : ns * transducer type (e.g. AgAgCl electrode)
% ns * 8 ascii : ns * physical dimension (e.g. uV or degreeC)
% ns * 8 ascii : ns * physical minimum (e.g. -500 or 34)
% ns * 8 ascii : ns * physical maximum (e.g. 500 or 40)
% ns * 8 ascii : ns * digital minimum (e.g. -2048)
% ns * 8 ascii : ns * digital maximum (e.g. 2047)
% ns * 80 ascii : ns * prefiltering (e.g. HP:0.1Hz LP:75Hz)
% ns * 8 ascii : ns * nr of samples in each data record
% ns * 32 ascii : ns * reserved 
% 
% DATA RECORD
% nr of samples[1] * integer : first signal in the data record
% nr of samples[2] * integer : second signal
% ..
% ..
% nr of samples[ns] * integer : last signal 
%
%   References:
%      [1] Kemp, B. et al. (1992) A simple format for exchange of digitized
%      polygraphic recordings, Electroencephalography and Clinical
%      Neurophysiology, 82 (1992): 391-393.
%      http://www.edfplus.info/specs/edf.html
%
%
%   MIT License (MIT) Copyright (c) 2017-2019 Marcus Vollmer,
%   marcus.vollmer@uni-greifswald.de
%   Feel free to contact me for discussion, proposals and issues.
%   last modified: 03 July 2019
%   version: 0.04

if nargin<2 || isempty(qdl)
    qdl=0;
end

if nargin<3 || isempty(memory)
    memory=0;
end

fid = fopen(fname,'r');


% HEADER
    header = fread(fid, 8+80+80, '*char')';
    start_date = datetime(fread(fid, 16, '*char')', 'InputFormat', 'dd.MM.yyHH.mm.ss');
    header2 = fread(fid, 8+44, '*char')';

% 8 ascii : number of data records (-1 if unknown, obey item 10 of the additional EDF+ specs)
    n_records = str2double(fread(fid, 8, '*char'));
   
% 8 ascii : duration of a data record, in seconds
    n_duration = str2double(fread(fid, 8, '*char'));
  
% 4 ascii : number of signals (ns) in data record 
    n_signals = str2double(fread(fid, 4, '*char'));

signals = table();
% ns * 16 ascii : ns * label (e.g. EEG Fpz-Cz or Body temp) (mind item 9 of the additional EDF+ specs)
    signals.name = cellstr(fread(fid, [16 n_signals], '*char')');

% ns * 80 ascii : ns * transducer type (e.g. AgAgCl electrode)
    signals.transducer_type = cellstr(fread(fid, [80 n_signals], '*char')');

% ns * 8 ascii : ns * physical dimension (e.g. uV or degreeC)
    signals.physical_dimension = cellstr(fread(fid, [8 n_signals], '*char')');

% ns * 8 ascii : ns * physical minimum (e.g. -500 or 34)
    signals.physical_minimum = str2num(fread(fid, [8 n_signals], '*char')');

% ns * 8 ascii : ns * physical maximum (e.g. 500 or 40)
    signals.physical_maximum = str2num(fread(fid, [8 n_signals], '*char')');

% ns * 8 ascii : ns * digital minimum (e.g. -2048)
    signals.digital_minimum = str2num(fread(fid, [8 n_signals], '*char')');

% ns * 8 ascii : ns * digital maximum (e.g. 2047)
    signals.digital_maximum = str2num(fread(fid, [8 n_signals], '*char')');

% ns * 80 ascii : ns * prefiltering (e.g. HP:0.1Hz LP:75Hz)
    signals.prefiltering = cellstr(fread(fid, [80 n_signals], '*char')');

% ns * 8 ascii : ns * nr of samples in each data record
    signals.n = str2num(fread(fid, [8 n_signals], '*char')');

% ns * 32 ascii : ns * reserved 
    signals.reserved = cellstr(fread(fid, [32 n_signals], '*char')');


% Digital to physical transformation
    signals.scale = (signals.physical_maximum-signals.physical_minimum)./(signals.digital_maximum-signals.digital_minimum);
    signals.translation = signals.physical_maximum - signals.scale.*signals.digital_maximum;
    signals.Fs = signals.n/n_duration;

    
if memory==1
    %Memory saving mode
    record = struct;
    for i=1:n_signals
        record.(matlab.lang.makeValidName(signals.name{i})) = zeros(n_records*signals.n(i),1);
    end
    
    % Read Signals
    for j=1:n_records
        data = fread(fid,sum(signals.n),'int16');
        for i=1:n_signals 
            record.(matlab.lang.makeValidName(signals.name{i}))(((j-1)*signals.n(i)+1):(j*signals.n(i))) = signals.translation(i) + signals.scale(i)*data((sum(signals.n(1:i-1))+1):sum(signals.n(1:i)));
        end
    end
    fclose(fid);
  
    
else
    % Read Signals
    data = fread(fid,'int16=>int16');
    if qdl==0
        record = struct;
        % nr of samples[i] * integer : i-th signal
            for i=1:n_signals
                tmp = (repmat(sum(signals.n(1:(i-1)))+(1:signals.n(i)), n_records, 1) + sum(signals.n)*repmat(0:(n_records-1), signals.n(i), 1)')';
                record.(matlab.lang.makeValidName(signals.name{i})) = signals.translation(i) + signals.scale(i)*data(tmp(:));
            end
    else
        if sum(strcmp(qdl,signals.name))==1
            v = 1;
            i = find(strcmp(qdl,signals.name));
        else
            [i,v] = listdlg('PromptString','Select a signal:', 'SelectionMode','single', 'ListString',signals.name);
        end
        if v==1
        % nr of samples[i] * integer : i-th signal
            tmp = (repmat(sum(signals.n(1:(i-1)))+(1:signals.n(i)), n_records, 1) + sum(signals.n)*repmat(0:(n_records-1), signals.n(i), 1)')';
            record = signals.translation(i) + signals.scale(i)*data(tmp(:));
            signals = signals.Fs(i);
        end
    end

    fclose(fid);
end

end
