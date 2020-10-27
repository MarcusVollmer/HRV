function write_edf(fname, signals, header)
% Write European Data Format
%
% Writes the signals information and raw signal data in a binary file
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
%   MIT License (MIT) Copyright (c) 2020 Marcus Vollmer,
%   marcus.vollmer@uni-greifswald.de
%   Feel free to contact me for discussion, proposals and issues.
%   last modified: 08 October 2020
%   version: 0.02

if nargin<3 || isempty(header)
    
end

fid = fopen(fname,'w');

%https://www.mathworks.com/matlabcentral/fileexchange/38641-reading-and-saving-of-data-in-the-edf
%https://www.edfplus.info/specs/edfplus.html#additionalspecs
% HEADER
  % 8 ascii : version of this data format (0)
    fwrite(fid, pad('0',8), 'char');
    
  % 80 ascii : local patient identification (mind item 3 of the additional EDF+ specs)
    if isstruct(header)
        patient = '';
        fn = setdiff(fieldnames(header), ...
            {'fs','start_date','version','signalnames','transducer_type','physical_dimension'});
        for i=1:size(fn,1)
            switch class(header.(fn{i}))
                case 'logical'
                    if header.(fn{i})
                        tmp = [fn{i} ': TRUE'];
                    else
                        tmp = [fn{i} ': FALSE'];
                    end
                case 'string'
                    tmp = [fn{i} ': ' header.(fn{i})];
                case 'char'
                    tmp = [fn{i} ': ' header.(fn{i})];
                case 'datetime'
                    tmp = [fn{i} ': ' datestr(header.(fn{i}))];
                otherwise
                    if isnumeric(header.(fn{i}))
                        tmp = [fn{i} ': ' num2str(header.(fn{i}))];
                    else
                        tmp = '';
                    end
            end
            if i<size(fn,1)
                patient = [patient tmp '; '];
            else
                patient = [patient tmp];
            end
        end
    elseif ischar(header)
        patient = header;
    else
        patient = '';
    end

    if strlength(patient)>80
        warning(['Local patient identification is too long in file: ' fname '. The information was cutted down to 80 characters.'])
        fwrite(fid, patient(1:80), 'char');
    else
        fwrite(fid, pad(patient,80), 'char');
    end
    
  % 80 ascii : local recording identification (mind item 4 of the additional EDF+ specs)
    if isfield(header,'version')
        if strlength(header.version)>80
            warning(['Local recording identification is too long in file: ' fname '. The information was cutted down to 80 characters.'])
            fwrite(fid, header.version(1:80), 'char');
        else
            fwrite(fid, pad(header.version,80), 'char');
        end
    else
        fwrite(fid, pad('',80), 'char');
    end

  % 8 ascii : startdate of recording (dd.mm.yy) (mind item 2 of the additional EDF+ specs)
  % 8 ascii : starttime of recording (hh.mm.ss)
    if isfield(header,'start_date') && ~isempty(header.start_date)
        fwrite(fid, datestr(header.start_date,'dd.mm.yy'), 'char');
        fwrite(fid, datestr(header.start_date,'HH.MM.SS'), 'char');
    else
        fwrite(fid, pad('',16), 'char');
    end

  % 8 ascii : number of bytes in header record
    fwrite(fid, pad('768',8), 'char');
    
  % 44 ascii : reserved
    fwrite(fid, pad('EDF+C',44), 'char'); % continuous ECG
    
  % 8 ascii : number of data records (-1 if unknown, obey item 10 of the additional EDF+ specs)
    n_records = 1;
    fwrite(fid, pad(num2str(n_records),8), 'char');
    
  % 8 ascii : duration of a data record, in seconds
    n_duration = size(signals,2)/header.fs;
    fwrite(fid, pad(num2str(n_duration,'%.7g'),8), 'char');
    
  % 4 ascii : number of signals (ns) in data record
    ns = size(signals,1);
    fwrite(fid, pad(num2str(ns),4), 'char');
    
  % ns * 16 ascii : ns * label (e.g. EEG Fpz-Cz or Body temp) (mind item 9 of the additional EDF+ specs)
    if isfield(header,'signalnames')
        if ns==1
            fwrite(fid, pad(header.signalnames,16), 'char');
        else
            for i=1:ns
                fwrite(fid, pad(header.signalnames{i},16), 'char');
            end
        end
    else
        fwrite(fid, pad('',ns*16), 'char');
    end
  
  % ns * 80 ascii : ns * transducer type (e.g. AgAgCl electrode)
    if isfield(header,'transducer_type')
        if ns==1
            fwrite(fid, pad(header.transducer_type,80), 'char');
        else
            for i=1:ns
                fwrite(fid, pad(header.transducer_type{i},80), 'char');
            end
        end
    else
        fwrite(fid, pad('',ns*80), 'char');
    end

  % ns * 8 ascii : ns * physical dimension (e.g. uV or degreeC)
    if isfield(header,'physical_dimension')
        if ns==1
            fwrite(fid, pad(header.physical_dimension,8), 'char');
        else
            for i=1:ns
                fwrite(fid, pad(header.physical_dimension{i},8), 'char');
            end
        end
    else
        fwrite(fid, pad('',ns*8), 'char');
    end
    
  % ns * 8 ascii : ns * physical minimum (e.g. -500 or 34)  
  % ns * 8 ascii : ns * physical maximum (e.g. 500 or 40)
  % ns * 8 ascii : ns * digital minimum (e.g. -2048)
  % ns * 8 ascii : ns * digital maximum (e.g. 2047)
    for i=1:ns*4
        fwrite(fid, pad('unknown', 8), 'char');
    end
    
  % ns * 80 ascii : ns * prefiltering (e.g. HP:0.1Hz LP:75Hz)
    fwrite(fid, pad('',ns*80), 'char'); 
  
  % ns * 8 ascii : ns * nr of samples in each data record
    for i=1:ns
        fwrite(fid, pad(num2str(size(signals,2)), 8), 'char');
    end
  
  % ns * 32 ascii : ns * reserved 
    for i=1:ns
        fwrite(fid, pad('', 32), 'char');
    end
    
% DATA RECORD
  % nr of samples[1] * integer : first signal in the data record
  % nr of samples[2] * integer : second signal
  % ..
  % nr of samples[ns] * integer : last signal 
    for i=1:ns
        fwrite(fid, signals(i,:), 'int16');
    end
    
    fclose(fid);

end
