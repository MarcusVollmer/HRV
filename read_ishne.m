function [record, header, start_date] = read_ishne(fname, qdl)
% Read ISHNE Holter Standard Output File Format
%
% Reads the annotation file or raw signal data stored in a binary file with
% ISHNE specifications as definded in the original paper [1].
%
% MAGIC NUMBER
% 8 ascii: format identifier (ISHNE1.0)
%
% CHECKSUM
% 2 ascii: checksum calculated over the complete header (not always
% calculated) 
%
% HEADER RECORD
% 4 ascii: Size of variable length block ('vh' in bytes)
% 4 ascii: Size of ECG  (in samples)
% 4 ascii: Offset of variable length block (in bytes from file beginning)
% 4 ascii: Offset of ECG block (in bytes from file beginning)
% 2 ascii: Version of the file 
% 40 ascii: Subject first name 
% 40 ascii: Subject last name 
% 20 ascii: Subject ID
% 2 ascii: Subject sex (0:unknown, 1:male, 2:female) 
% 2 ascii: Race (0:unknown, 1:Caucasian, 2:Black, 3:Oriental, 4-9:Reserved) 
% 6 ascii: Date of Birth (European: day,month,year) 
% 6 ascii: Date of recording (European)
% 6 ascii: Date of creation of output file (European) 
% 6 ascii: Start time (European: hour[0-23],min,sec)
% 2 ascii: Number of stored leads ('ns')
% 24 ascii: Lead specification (0:Unknown, 1:Generic bipolar, 2:X bipolar,
%      3:Y bipolar, 4:Z bipolar, 5 to 10: I to VF (6 standard limb leads),
%      11 to 16: V1 to V6 (precordial leads), 17:ES, 18:AS,19:Al)  
% 24 ascii: Lead quality (0:Unknown (unrated), 1: Good quality permanently,
%      2: Intermittent noise<10% of total length, 3: Frequent noise (>1O%),
%      4: Lead disconnection (<10%), 5: Lead disconnection (>10%))
% 24 ascii: Amplitude resolution (in integer no. of nV)
% 2 ascii: Pacemaker code (0: no pacemaker, 1: pacemaker type not known,
%      2: single chamber unipolar, 3: dual chamber unipolar,
%      4: single chamber bipolar, 5: dual chamber bi-polar)
% 40 ascii: Type of recorder (analog or digital)
% 2 ascii: Sampling rate (in Hertz)
% 80 ascii: Proprietary of ECG (if any)
% 80 ascii: Copyright and restriction of diffusion (if any)
% 88 ascii: Reserved
% vh ascii: Variable header for comments
%
% DATA RECORD (BIOSIGNALS)
% 2 ascii: first sample of signal 1
% 2 ascii: first sample of signal 2
% ..
% 2 ascii: first sample of signal ns
% 2 ascii: second sample of signal 1
% 2 ascii: second sample of signal 2
% ..
% 2 ascii: second sample of signal ns
% ..
%
% DATA RECORD (ANNOTATION)
% 1 ascii: beat annotation Label 1: generic beat label short list 
%      (N: Normal beat, V: Premature ventricular contraction,
%      S: Supraventricular premature or ectopic beat, C: Calibration Pulse,
%      B: Bundle branch block beat, P: Pace, X: Artefact, !: Timeout)  
% 1 ascii: internal use (e.g. for further beat description)
% 2 ascii: digital samples from last beat annotation (RR Interval in
%      samples) 
%
% Hint: [!,.........,65535] is the Timeout label and used when the sample
% from last annotation is higher than the maximum number that can be
% expressed by an unsigned int, i.e. when it is larger than 65535.
%
%
%   References:
%      [1] Badilini, Fabio for the ISHNE Standard Output Format Task Force
%      (1998) The ISHNE holter standard output file format, Annals of
%      noninvasive electrocardiology, Vol 3, No 3, Part 1, (1998): 263-266. 
%      http://thew-project.org/papers/Badilini.ISHNE.Holter.Standard.pdf
%      http://thew-project.org/papers/ishneAnn.pdf
%
%
%   MIT License (MIT) Copyright (c) 2018 Marcus Vollmer,
%   marcus.vollmer@uni-greifswald.de
%   Feel free to contact me for discussion, proposals and issues.
%   last modified: 06 November 2018
%   version: 0.01

if nargin<2 || isempty(qdl)
    qdl=0;
end

fid = fopen(fname,'r');

% MAGIC NUMBER
magic = fread(fid, 8, '*char')';
if strcmp(magic,'ISHNE1.0') || strcmp(magic,'ANN  1.0')

    % CHECKSUM
        checksum = fread(fid, 1, 'uint16');

    % HEADER
        variableheader = fread(fid, 1, 'long'); 
        samplesize_data = fread(fid, 1, 'long');
        offset_variableheader = fread(fid, 1, 'long');
        offset_data = fread(fid, 1, 'long');
        version = fread(fid, 1, 'short');
    header = table();
        header.First_name  = fread(fid, 40, '*char')';
        header.Last_name   = fread(fid, 40, '*char')';
        header.ID          = fread(fid, 20, '*char')';
        header.Sex         = categorical(fread(fid, 1, 'short'), 0:2, {'unknown', 'male', 'female'});        
        header.Race        = categorical(fread(fid, 1, 'short'), 0:9, {'unknown', 'Caucasian', 'Black', 'Oriental', '4:Reserved', '5:Reserved', '6:Reserved', '7:Reserved', '8:Reserved', '9:Reserved'});              
        header.Birth_Date  = datetime(fliplr(fread(fid, 3, 'short')'));
        header.Record_Date = datetime(fliplr(fread(fid, 3, 'short')'));
        header.File_Date   = datetime(fliplr(fread(fid, 3, 'short')'));
        header.Start_Time  = datetime([0,0,0, fread(fid, 3, 'short')'], 'Format','HH:mm:ss');    
        start_date = datetime(datevec(datenum(header.Record_Date)+datenum(header.Start_Time)-floor(datenum(header.Start_Time))));
        
        header.NumLeads    = fread(fid, 1, 'short');      
        Lead_Spec          = fread(fid, 12, 'short')';
        header.Lead_Specification = categorical(Lead_Spec(1:header.NumLeads), 0:19,...
            {'Unknown', 'Generic bipolar', 'X bipolar', 'Y bipolar', 'Z bipolar',...
            'I','II','III','aVR','aVL','aVF', 'V1','V2','V3','V4','V5','V6',...
            'ES', 'AS', 'Al'});
        Lead_Qual          = fread(fid, 12, 'short')';
        header.Lead_Quality = categorical(Lead_Qual(1:header.NumLeads), 0:5,...
            {'Unknown (unrated)', 'Good quality permanently',...
            'Intermittent noise<10% of total length', 'Frequent noise (>1O%)',...
            'Lead disconnection (<10%)', 'Lead disconnection (>10%)'});
        Amplitude_Resolution = fread(fid, 12, 'short')';	
        header.Lead_Amplitude_Resolution = Amplitude_Resolution(1:header.NumLeads);	    
        header.Pacemaker   = categorical(fread(fid, 1, 'short'), 0:5,...
            {'no pacemaker', 'pacemaker type not known', 'single chamber unipolar',...
            'dual chamber unipolar', 'single chamber bipolar', 'dual chamber bi-polar'});
        header.Type_of_recorder = fread(fid, 40, '*char')';
        header.Sampling_rate = fread(fid, 1, 'short');
        header.Sample_Size   = samplesize_data;
        header.Proprietary   = fread(fid, 80, '*char')';
        header.Copyright     = fread(fid, 80, '*char')';
        header.Reserved      = fread(fid, 88, '*char')';
        
        % Remove whitespace e.g.
        %header.First_name  = deblank(header.First_name);
        
        % Read variable header
        if variableheader>0
            header.Comments = fread(fid, variableheader, '*char')';
        end
    if strcmp(magic,'ISHNE1.0')        
        % Read signals    
            data = fread(fid,'int16');
            fclose(fid);
            if qdl==0
                record = struct;
                % store i-th signal
                    for i=1:header.NumLeads
                        record.(matlab.lang.makeValidName(string(header.Lead_Specification(i)))) = data(i:header.NumLeads:size(data,1));
                    end
            else
                [i,v] = listdlg('PromptString','Select a signal:', 'SelectionMode','single', 'ListString',header.Lead_Specification);
                if v==1
                % store selected signal
                    record = data(i:header.NumLeads:size(data,1));
                    header = header.Sampling_rate;
                end
            end
    else
        % Read annotation
            labels = fread(fid,[4 Inf],'*char')';
            fclose(fid);
            record = table();
            record.label1 = labels(:,1);
            record.label2 = labels(:,2);

            fid = fopen(fname,'r');
            ann = fread(fid,'uint16');
            fclose(fid);            
            record.RR = ann(((offset_data/2)+2):2:end);
            record.Ann = cumsum(record.RR); 
    end
   
else
    warndlg('This file seems not be in ISHNE1.0 format. Import aborted.','Format warning');
end      


end
