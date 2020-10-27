function [record] = read_pdf(fname,ink)
% Reads the ECG with header information from ECG-PDFs created by AppleWatch
% and AliveCor (Kardia and aliveecg).
%
% REQUIREMENTS

% UNIX/ GNU/LINUX
%   A - This function works with UNIX systems with Inkscape
%     To read the header information and to extract the path of ECG leads,
%     this function is converting the PDF to SVG using 'Inkscape':
%     https://inkscape.org
%
%   B - Alternatively you can also use these two functions:
%
%     To read the header information the function is converting the PDF to
%     TXT using 'pdf2txt' written by Yusuke Shinyama and available with
%     'PDFMiner':
%     http://manpages.ubuntu.com/manpages/focal/man1/pdf2txt.1.html
%     https://pypi.org/project/pdfminer/ 
%
%     To extract the path of ECG leads, the function is converting the PDF 
%     to SVG using 'pdf2svg' written by David Barton and Matthew Flaschen:
%     http://manpages.ubuntu.com/manpages/focal/man1/pdf2svg.1.html 
%
% WINDOWS
%     To read the header information and to extract the path of ECG leads,
%     this function is converting the PDF to SVG using 'Inkscape':
%     https://inkscape.org
%
% MAC OS X
%     To read the header information and to extract the path of ECG leads,
%     this function is converting the PDF to SVG using 'Inkscape':
%     https://inkscape.org
%
%
%
% INPUT
% fname - file location
%
% OUTPUT
% record - Matlab struct containing the header information as named fields
% and the ECG is stored in record.ecg
%
% 
%
%   MIT License (MIT) Copyright (c) 2020 Marcus Vollmer,
%   marcus.vollmer@uni-greifswald.de
%   Feel free to contact me for discussion, proposals and issues.
%   last modified: 12 October 2020
%   version: 0.02


    if nargin<2 || isempty(ink)
        ink = [];
    end
    
    
record = struct();
tmp_dir = 'tmpconvert';
mkdir(tmp_dir)

status_1 = 1;
status_2 = 1;
status_3 = 1;


% Check neccessary installations and convert PDF
switch isunix + 1*ismac + 3*ispc
  case 1
% UNIX
    status_1 = system('command -v pdf2svg');
    status_2 = system('command -v pdf2txt');
    status_3 = system('command -v inkscape');
    
    % For testing puposes
    if ~isempty(ink)
        % force Inkscape usage
        status_2 = 2;
    end
    
    if (status_1==0 && status_2==0)
        curtxt = [tmp_dir filesep 'tmp.txt'];
        copyfile(fname,[tmp_dir filesep 'tmp.pdf']);
        system(['pdf2txt -o ' curtxt ' ' tmp_dir filesep 'tmp.pdf']);        
        system(['pdf2svg ''' fname ''' ' tmp_dir filesep 'tmp_%03i.svg all']);
    elseif status_3==0
        system(['cp ''' fname ''' ' tmp_dir filesep 'tmp.pdf']);        
        system(['inkscape --export-plain-svg --export-type=svg -T ' tmp_dir filesep 'tmp.pdf -o ' tmp_dir filesep 'tmp.svg']);
        movefile([tmp_dir filesep 'tmp.svg'],[tmp_dir filesep 'tmp.txt'])
        i = 0;
        e = '';
        while ~contains(e, 'Import first page instead.')
            i = i+1;            
            [~,e] = system(['inkscape --export-plain-svg --export-type=svg --pdf-page=' num2str(i) ' ' tmp_dir filesep 'tmp.pdf -o ' tmp_dir filesep sprintf('tmp_%03i.svg', i)]);
        end
        delete([tmp_dir filesep sprintf('tmp_%03i.svg', i)])
    end
    
  case 2
% MAC OS
    [status_3, cmdout] = system('mdfind -name ''kMDItemFSName=="Inkscape.app"''');
    
    if ~isempty(cmdout)
        copyfile(fname,[tmp_dir filesep 'tmp.pdf']);        
        system(['/Applications/Inkscape.app/Contents/MacOS/inkscape --export-plain-svg --export-type=svg -T ' tmp_dir filesep 'tmp.pdf -o ' tmp_dir filesep 'tmp.svg']);
        movefile([tmp_dir filesep 'tmp.svg'],[tmp_dir filesep 'tmp.txt'])
        i = 0;
        e = '';
        while ~contains(e, 'Import first page instead.')
            i = i+1;            
            [~,e] = system(['/Applications/Inkscape.app/Contents/MacOS/inkscape --export-plain-svg --export-type=svg --pdf-page=' num2str(i) ' ' tmp_dir filesep 'tmp.pdf -o ' tmp_dir filesep sprintf('tmp_%03i.svg', i)]);
        end
        delete([tmp_dir filesep sprintf('tmp_%03i.svg', i)])
    end
    
  case 3
% WINDOWS
    [status_3] = system('inkscape --help');
    
    if status_3==0
        copyfile(fname,[tmp_dir filesep 'tmp.pdf']);
        system(['inkscape --export-plain-svg --export-type=svg -T ' tmp_dir filesep 'tmp.pdf -o ' tmp_dir filesep 'tmp.svg']);
        movefile([tmp_dir filesep 'tmp.svg'],[tmp_dir filesep 'tmp.txt'])
        i = 0;
        e = '';
        while ~contains(e, 'Import first page instead.')
            i = i+1;            
            [~,e] = system(['inkscape --export-plain-svg --export-type=svg --pdf-page=' num2str(i) ' ' tmp_dir filesep 'tmp.pdf -o ' tmp_dir filesep sprintf('tmp_%03i.svg', i)]);
        end
        delete([tmp_dir filesep sprintf('tmp_%03i.svg', i)])
    end

end


if ~(status_1==0 && status_2==0 || status_3==0)
    warndlg('The import of ECG-PDFs requires the installation of `Inkscape` or the packages `pdf2svg` and `pdf2txt`.')
else
    
    if (status_1==0 && status_2==0)
      % Extract header information 
        fid = fopen(curtxt);
        data = fscanf(fid,'%c'); % Import as character array
        fclose(fid);

        appleflag = contains(data,'watchOS');
        kardia    = contains(data,'Kardia');
        aliveecg  = contains(data,'aliveecg');

        switch appleflag+2*kardia+3*aliveecg
            case 1
              % Apple Watch / 
              % tested with iOS 13.6, watchOS 6.2.8, Watch5,2 
              % tested with iOS 13.6, watchOS 5.3.3, Watch4,3
                fid = fopen(curtxt);          
                record.name = fgetl(fid);

                tmp = fgetl(fid);
                colon_hit = strfind(tmp,':');
                tmp = strtrim(tmp(colon_hit(1)+1:end));
                if length(strfind(tmp,'.'))==1                    
                    try
                        record.birthdate = datetime(tmp(1:12), 'InputFormat', 'dd. MMM yyyy');
                    catch                
                        prompt = {['The birth date is ''' tmp '''. Please enter the date in this Matlab readable format:']};
                        dlgtitle = 'Format of the birth date';
                        dims = [1 50];
                        definput = {'yyyy-MM-dd'};
                        answer = inputdlg(prompt, dlgtitle, dims, definput);
                        record.birthdate = datetime(answer, 'InputFormat', 'yyyy-MM-dd');
                    end
                else
                    record.birthdate = datetime(strtrim(tmp(colon_hit+[1:12])));
                end
                
                tmp = fgetl(fid);
                hyphen_hit = strfind(tmp,'—');
                BPM_hit = strfind(tmp,'BPM');
                record.rhythm = strtrim(tmp(1:hyphen_hit-1));
                record.bpm = str2double(tmp((BPM_hit-4):(BPM_hit-1)));

                tmp = fgetl(fid);
                while  ~contains(tmp,':')
                    tmp = fgetl(fid);
                end
                dot_hit = strfind(tmp,'.');
                colon_hit = strfind(tmp,':');
                if length(dot_hit)==1
                    try
                        record.start_date = datetime([tmp(dot_hit(1)+[-2:10]) tmp(colon_hit+[-2:2])], 'InputFormat', 'dd. MMM yyyy HH:mm');
                    catch                
                        prompt = {['The start date is ''' tmp '''. Please enter the recording start date in this Matlab readable format:']};
                        dlgtitle = 'Format of the recording date';
                        dims = [1 50];
                        definput = {'yyyy-MM-dd HH:mm'};
                        answer = inputdlg(prompt, dlgtitle, dims, definput);
                        record.start_date = datetime(answer, 'InputFormat', 'yyyy-MM-dd HH:mm');
                    end
                else
                    record.start_date = datetime([tmp(dot_hit(1)+[-2:8]) tmp(colon_hit+[-2:2])], 'InputFormat', 'dd.MM.yyyy HH:mm');
                end

                fgetl(fid);
                tmp = fgetl(fid);
                comma_hit = strfind(tmp,',');
                fs_hit = strfind(tmp,'Hz');
                hyphen_hit = [strfind(tmp,'-'), strfind(tmp,'—')];
                space_hit = strfind(tmp,' ');

                record.physical_dimension = tmp((space_hit(sum(space_hit<comma_hit(2)))+1):(comma_hit(2)-1)); %adu
                slash_hit = strfind(record.physical_dimension,'/');
                record.physical_dimension = record.physical_dimension((slash_hit+1):end); %adu

                record.signalnames = tmp((space_hit(sum(space_hit<comma_hit(3)))+1):(comma_hit(3)-1));
                record.fs = str2double(tmp((space_hit(sum(space_hit<fs_hit))+1):(fs_hit-1)));
                record.version = strtrim(tmp((fs_hit+4):(hyphen_hit-1)));

                fclose(fid);

            case 2
              % AliveCor report / 
              % tested with Kardia v4.9.2.1518, Report v4.9.2,
              % tested with Kardia v4.7.0.1509, Report v4.7.0
                fid = fopen(curtxt);
                num_labels = 0;
                while ~isempty(fgetl(fid))
                    num_labels = num_labels+1;
                end

                if num_labels==3
                  % Name and birthdate
                    tmp = fgetl(fid);
                    comma_hit = strfind(tmp,', ');
                    space_hit = strfind(tmp,' '); 
                    if isempty(comma_hit)
                        record.name = tmp;
                    else
                        record.name = tmp(1:comma_hit-1);
                        record.birthdate = datetime(strtrim(tmp((comma_hit+1):min(space_hit(space_hit>(comma_hit+1))))),'InputFormat','dd.MM.yy');
                    end
                end

              % Recording date
                tmp = fgetl(fid); 
                comma_hit = strfind(tmp,',');
                space_hit = strfind(tmp,' '); 
                colon_hit = strfind(tmp,':');
                try
                    record.start_date = datetime([tmp(comma_hit+1:space_hit(end-1)) tmp(colon_hit(1)+[-2:5])], 'InputFormat', 'dd. MMMM yyyy HH:mm:ss', 'Locale','system');
                catch
                    prompt = {['The recording date is ''' tmp '''. Please enter the date and time in this Matlab readable format:']};
                    dlgtitle = 'Format of the recording date';
                    dims = [1 50];
                    definput = {'yyyy-MM-dd HH:mm:ss'};
                    answer = inputdlg(prompt, dlgtitle, dims, definput);
                    record.start_date = datetime(answer, 'InputFormat', 'yyyy-MM-dd HH:mm:ss'); 
                end

              % Heart rate
                tmp = fgetl(fid);
                record.bpm = str2double(tmp(1:end-3));

                fgetl(fid);

              % Record duration
                tmp = fgetl(fid);
                colon_hit = strfind(tmp,':');
                record.duration = strtrim(tmp(colon_hit+1:end));

                fgetl(fid);
                fgetl(fid);
                fgetl(fid);
                fgetl(fid);

              % Diagnosis
                tmp = fgetl(fid);
                record.Finding_by_Kardia = tmp;

                fgetl(fid);

              % Filter settings
                tmp = fgetl(fid);
                space_hit = strfind(tmp,'  ');
                record.filter = strtrim(tmp(1:space_hit(1)));

              % Physical dimension
                record.physical_dimension = 'mV';

                fgetl(fid);
              % Version
                tmp = fgetl(fid);
                comma_hit = strfind(tmp,',');
                record.version = strtrim(tmp(comma_hit(1)+1:comma_hit(end)-1));
                
                fclose(fid);

            case 3
              % AliveCor report / tested with aliveecg 5.7.3
                fid = fopen(curtxt);
                fgetl(fid);
                fgetl(fid);
                fgetl(fid);
                fgetl(fid);

              % Name and birthdate
                tmp = fgetl(fid);
                comma_hit = strfind(tmp,', ');
                space_hit = strfind(tmp,' ');            
                record.name = tmp(1:comma_hit-1);
                record.birthdate = datetime(strtrim(tmp((comma_hit+1):min(space_hit(space_hit>(comma_hit+1))))),'InputFormat','dd.MM.yy');

              % Recording date
                tmp = fgetl(fid);
                % Translate German to English
                tmp = regexprep(tmp, ...
                    {'Mär','Mai','Juni','Okt','Dez','nachm.', 'vorm.'}, ...
                    {'Mar','May','June','Oct','Dec','PM', 'AM'});    
                comma_hit = strfind(tmp,',');
                try
                    record.start_date = datetime(tmp(comma_hit(1)+1:end), 'InputFormat', 'dd. MMM. yyyy, hh:mm:ss a');
                catch                
                    prompt = {['The recording date is ''' tmp '''. Please enter the date and time in this Matlab readable format:']};
                    dlgtitle = 'Format of the recording date';
                    dims = [1 50];
                    definput = {'yyyy-MM-dd HH:mm:ss'};
                    answer = inputdlg(prompt, dlgtitle, dims, definput);
                    record.start_date = datetime(answer, 'InputFormat', 'yyyy-MM-dd HH:mm:ss');
                end

              % Record duration
                tmp = fgetl(fid);
                colon_hit = strfind(tmp,':');
                record.duration = strtrim(tmp(colon_hit+1:end));

              % Heart rate
                tmp = fgetl(fid);
                record.bpm = str2double(tmp(1:end-3));

                fgetl(fid);
                
              % Diagnosis
                tmp = fgetl(fid);
                colon_hit = strfind(tmp,':');
                record.diagnosis_by_AliceCor = strtrim(tmp(colon_hit+1:end));

                fgetl(fid);
                fgetl(fid);

              % Filter settings
                tmp = fgetl(fid);
                space_hit = strfind(tmp,'  ');
                record.filter = strtrim(tmp(1:space_hit(1)));

              % Physical dimension
                record.physical_dimension = 'mV';

              % ECG Leads
                record.signalnames = [];
                k = 1;
                fgetl(fid);
                tmp = fgetl(fid);
                while ~contains(tmp,'alive','IgnoreCase',true)
                    record.signalnames{k} = tmp;
                    k = k+1;
                    fgetl(fid);
                    tmp = fgetl(fid);
                end

              % Version
                comma_hit = strfind(tmp,',');
                record.version = strtrim(tmp(comma_hit(1)+1:comma_hit(2)-1));
                
                fclose(fid);      

            otherwise
               warndlg('This function is not programmed for ....')
        end
    else
      % Read labels from Inkscape svg with option '-T'
        cursvg = [tmp_dir filesep 'tmp.txt'];
        fid = fopen(cursvg);
        data = fscanf(fid,'%c');
        
        front_hit = strfind(data,'aria-label=');
        back_hit_candidates = strfind(data,'"');
        back_hit = front_hit;
        for jj=1:size(front_hit,2)            
            back_hit(jj) = back_hit_candidates(sum(back_hit_candidates<front_hit(jj))+2);
            front_hit(jj) = back_hit_candidates(sum(back_hit_candidates<front_hit(jj))+1);
            data_txt{jj} = data(front_hit(jj)+1:back_hit(jj)-1);
        end
        
        appleflag = contains(data,'watchOS');
        kardia    = contains(data,'Kardia');
        aliveecg  = contains(data,'aliveecg');

        switch appleflag+2*kardia+3*aliveecg
            case 1
              % Apple Watch /
              % tested with iOS 13.6, watchOS 6.2.8, Watch5,2
              % tested with iOS 13.6, watchOS 5.3.3, Watch4,3
              
                record.name = data_txt{1};                
                colon_hit = strfind(data_txt{2},':');
                record.birthdate = datetime(strtrim(data_txt{2}(colon_hit+[1:12])));

                tmp = data_txt{6};
                hyphen_hit = strfind(tmp,'—');
                record.rhythm = strtrim(tmp(1:hyphen_hit-1));
                
                tmp = data_txt{7};
                BPM_hit = strfind(tmp,'BPM');                
                record.bpm = str2double(tmp(1:(BPM_hit-1)));

                tmp = [data_txt{3}, data_txt{4}, data_txt{5}];
                dot_hit = strfind(tmp,'.');
                colon_hit = strfind(tmp,':');
                record.start_date = datetime([tmp(dot_hit(1)+[-2:8]) tmp(colon_hit+[-2:2])], 'InputFormat', 'dd.MM.yyyy HH:mm');

                tmp = data_txt{contains(data_txt, 'Hz')};
                comma_hit = strfind(tmp,',');
                fs_hit = strfind(tmp,' Hz');
                hyphen_hit = strfind(tmp,'-');
                space_hit = strfind(tmp,' ');

                record.physical_dimension = tmp((space_hit(sum(space_hit<comma_hit(2)))+1):(comma_hit(2)-1)); %adu
                slash_hit = strfind(record.physical_dimension,'/');
                record.physical_dimension = record.physical_dimension((slash_hit+1):end); %adu

                record.signalnames =  tmp((space_hit(sum(space_hit<comma_hit(3)))+1):(comma_hit(3)-1));
                record.fs = str2double(tmp((space_hit(sum(space_hit<fs_hit))+1):(fs_hit-1)));
                record.fs = str2double(tmp((space_hit(sum(space_hit<fs_hit))+1):(fs_hit-1)));
                record.version = strtrim(tmp((fs_hit+4):(hyphen_hit-1)));

                
            case 2
              % AliveCor report / 
              % tested with Kardia v4.9.2.1518, Report v4.9.2,
              % tested with Kardia v4.7.0.1509, Report v4.7.0
                            
                bpm_num = find(contains(data_txt, 'bpm'));
                
                if bpm_num>5
                  % Name and birthdate
                    tmp = data_txt{2};
                    comma_hit = strfind(tmp,', ');
                    space_hit = strfind(tmp,' '); 
                    if isempty(comma_hit)
                        record.name = tmp;
                    else
                        record.name = tmp(1:comma_hit-1);
                        record.birthdate = datetime(strtrim(tmp((comma_hit+1):min(space_hit(space_hit>(comma_hit+1))))),'InputFormat','dd.MM.yy');
                    end
                end

              % Recording date
                tmp = data_txt{bpm_num-2}; 
                comma_hit = strfind(tmp,',');
                space_hit = strfind(tmp,' '); 
                colon_hit = strfind(tmp,':');
                try
                    record.start_date = datetime([tmp(comma_hit+1:space_hit(end-1)) tmp(colon_hit(1)+[-2:5])], 'InputFormat', 'dd. MMMM yyyy HH:mm:ss', 'Locale','system');
                catch
                    prompt = {['The recording date is ''' tmp '''. Please enter the date and time in this Matlab readable format:']};
                    dlgtitle = 'Format of the recording date';
                    dims = [1 50];
                    definput = {'yyyy-MM-dd HH:mm:ss'};
                    answer = inputdlg(prompt, dlgtitle, dims, definput);
                    record.start_date = datetime(answer, 'InputFormat', 'yyyy-MM-dd HH:mm:ss'); 
                end

              % Heart rate
                tmp = data_txt{bpm_num};
                record.bpm = str2double(tmp(1:end-3));

              % Record duration
                record.duration = data_txt{bpm_num+2};

              % Diagnosis
                record.Finding_by_Kardia = data_txt{bpm_num+5};

              % Filter settings
                tmp = data_txt{end};
                space_hit = strfind(tmp,'Hz');
                record.filter = strtrim(tmp(1:space_hit(1)+1));

              % Physical dimension
                record.physical_dimension = 'mV';

              % Version
                tmp = data_txt{bpm_num+6};
                comma_hit = strfind(tmp,',');
                record.version = strtrim(tmp(comma_hit(1)+1:comma_hit(end)-1));
                
                
            case 3
              % AliveCor report / tested with aliveecg 5.7.3
              
                bpm_num = find(contains(data_txt, 'bpm'));
                
                if bpm_num>6
                  % Name and birthdate
                    tmp = data_txt{3};
                    comma_hit = strfind(tmp,', ');
                    space_hit = strfind(tmp,' ');            
                    record.name = tmp(1:comma_hit-1);
                    record.birthdate = datetime(strtrim(tmp((comma_hit+1):min(space_hit(space_hit>(comma_hit+1))))),'InputFormat','dd.MM.yy');
                end                

              % Recording date
                % Translate German to English
                tmp = regexprep(data_txt{bpm_num-2}, ...
                    {'Mär','Mai','Juni','Okt','Dez','nachm.', 'vorm.'}, ...
                    {'Mar','May','June','Oct','Dec','PM', 'AM'});    
                comma_hit = strfind(tmp,',');
                try
                    record.start_date = datetime(tmp(comma_hit(1)+1:end), 'InputFormat', 'dd. MMM. yyyy, hh:mm:ss a');
                catch                
                    prompt = {['The recording date is ''' tmp '''. Please enter the date and time in this Matlab readable format:']};
                    dlgtitle = 'Format of the recording date';
                    dims = [1 50];
                    definput = {'yyyy-MM-dd HH:mm:ss'};
                    answer = inputdlg(prompt, dlgtitle, dims, definput);
                    record.start_date = datetime(answer, 'InputFormat', 'yyyy-MM-dd HH:mm:ss');
                end

              % Record duration
                record.duration = data_txt{bpm_num+2};

              % Heart rate
                tmp = data_txt{bpm_num};
                record.bpm = str2double(tmp(1:end-3));

              % Diagnosis
                record.diagnosis_by_AliceCor = data_txt{bpm_num+4};

              % Filter settings
                tmp = data_txt{1};
                space_hit = strfind(tmp,'Hz');
                record.filter = strtrim(tmp(1:space_hit(1)+1));

              % Physical dimension
                record.physical_dimension = 'mV';

              % ECG Leads
                record.signalnames = [];
                k = 1;                
                alive_num = find(contains(data_txt, 'alive'));
                for jj=alive_num+1:size(data_txt,2)
                    if ~contains(data_txt{jj}, 'Page')
                        record.signalnames{k} = data_txt{jj};
                        k = k+1;
                    end
                end

              % Version
                tmp = data_txt{contains(data_txt, 'aliveecg')};
                comma_hit = strfind(tmp,',');
                record.version = strtrim(tmp(comma_hit(1)+1:comma_hit(2)-1));   
              
        end      

    end


  % Read pages to extract ECG
    % Remarks:
    % Inkscape paths example (Move with implicit LineTo (relative coordinates)): 
    % m 25.61887,56.09067 0.13848,0.0023 0.13848,-0.0042
    % PDF2SVG paths example (Move with explicit LineTo (absolute coordinates)): 
    % M 25.617188 56.089844 L 25.757812 56.09375 L 25.894531 56.089844
    % Read more here:
    % https://css-tricks.com/svg-path-syntax-illustrated-guide/
    % https://www.w3.org/TR/SVG/paths.html  
  
    pages = dir([tmp_dir filesep '*.svg']);

    record.ecg = [];
    record.ann = [];

    for j=1:size(pages,1)
        cursvg = [tmp_dir filesep pages(j).name];
        fid = fopen(cursvg);
        data = fscanf(fid,'%c');

      % extract ECG
        switch appleflag+2*kardia+3*aliveecg
            case 1
              % Apple Watch /
              % tested with iOS 13.6, watchOS 6.2.8, Watch5,2
              % tested with iOS 13.6, watchOS 5.3.3, Watch4,3
                front_hit = strfind(data,'<path');
                back_hit_candidates = strfind(data,'/>');
                back_hit = front_hit;
                for jj=1:size(front_hit,2)
                    back_hit(jj) = back_hit_candidates(sum(back_hit_candidates<front_hit(jj))+1);
                end
                [out,idx] = sort([back_hit-front_hit], 'descend');

                num_paths = sum(out/out(1)>.5);
                idx = sort(idx(1:num_paths));

                time = [];
                ecg = [];
                lengths = [];
                xtmp = [];
                for jj=1:num_paths
                    cur_path = data(front_hit(idx(jj)):back_hit(idx(jj)));
                    [mat_path, path_syntax] = path2mat(cur_path);
                    x = mat_path(1,:);
                    y = mat_path(2,:);
                    if x(1)==x(2)
                        x = x(2:end);
                        y = y(2:end);
                    end
                    
                    lengths(jj) = length(x);
                    time(jj,1:length(x)) = x;
                    ecg(jj,1:length(y)) = y;
                    xtmp = [xtmp x];
                end
                    
              % Linear interpolation of missing coordinates
                xtmp = sort(unique(x));
                d_xtmp = diff(xtmp);
                xtmp = xtmp([true d_xtmp>.1*mean(d_xtmp)]);
                d_xtmp = diff(xtmp);
                skip_coord = round(d_xtmp/min(d_xtmp));
                tmp_coord = find(skip_coord~=1);

                xtmp_interp = [];
                for j_skip_coord = 1:length(tmp_coord)
                    skip_length = skip_coord(tmp_coord(j_skip_coord));
                    skip_pos = tmp_coord(j_skip_coord);
                    xtmp_interp = [xtmp_interp linspace(xtmp(skip_pos), xtmp(skip_pos+1), skip_length+1)];
                end
                xtmp = unique(sort([xtmp xtmp_interp]));
                

                if path_syntax=='M'
                  % Search for optimal pair of location and scale to convert double to integer
                    jj=1;
                    a = round(1/min(setdiff(abs(diff(ecg(jj,1:lengths(jj)))),0)));
                    ecg = ecg*a;
                
                    for jj=1:num_paths
                        b = mean(ecg(jj,1:lengths(jj))-round(ecg(jj,1:lengths(jj))));
                        ecg(jj,1:lengths(jj)) = round(ecg(jj,1:lengths(jj))-b);
                    end
                end

                
                for jj=1:num_paths
                    y = interp1(time(jj,1:lengths(jj)), ecg(jj,1:lengths(jj)), xtmp, 'linear');
                    record.ecg = [record.ecg -y];
                end
                
                record.ecg = record.ecg-round((max(record.ecg)+min(record.ecg))/2);

                %plot(record.ecg)


            case 2
              % AliveCor report / 
              % tested with Kardia v4.9.2.1518, Report v4.9.2 
              % tested with Kardia v4.7.0.1509, Report v4.7.0

                front_hit = strfind(data,'<path');
                back_hit_candidates = strfind(data,'/>');
                back_hit = front_hit;
                for jj=1:size(front_hit,2)
                    back_hit(jj) = back_hit_candidates(sum(back_hit_candidates<front_hit(jj))+1);
                end
                [out,idx] = sort([back_hit-front_hit], 'descend');

                num_paths = sum(out/out(13)>2);
                idx = sort(idx(1:num_paths));

                time = [];
                ecg = [];
                lengths = [];
                xtmp = [];
                beat_ann = [];
                ann = [];
                for jj=1:num_paths
                  % extract ECG
                    cur_path = data(front_hit(idx(jj)):back_hit(idx(jj)));
                    mat_path = path2mat(cur_path);
                    x = mat_path(1,:);
                    y = mat_path(2,:);
                    if x(1)==x(2)
                        x = x(2:end);
                        y = y(2:end);
                    end
                    %plot(x,-y)
                    %diff(x)

                    lengths(jj) = length(x);
                    time(jj,1:length(x)) = x;
                    ecg(jj,1:length(y)) = y;
                    xtmp = [xtmp x];

                  % extract annotations 
                  % beat locations are stored in paths after the ECG signal
                    if jj==num_paths
                        beat_idx = idx(jj)+1:length(out);
                    else
                        beat_idx = idx(jj)+1:idx(jj+1)-1;
                    end
                    if isempty(beat_idx)
                        beat_ann(jj,1:end) = 0;
                    else
                        for j_beat=1:length(beat_idx)
                            cur_path = data(front_hit(beat_idx(j_beat)):back_hit(beat_idx(j_beat)));
                            mat_path = path2mat(cur_path);
                            beat_ann(jj,j_beat) = mat_path(1,1);
                        end
                    end
                end

              % Linear interpolation of missing coordinates
                xtmp = sort(unique(xtmp));
                d_xtmp = diff(xtmp);
                xtmp = xtmp([true d_xtmp>.1*mean(d_xtmp)]);
                d_xtmp = diff(xtmp);
                skip_coord = round(d_xtmp/min(d_xtmp));
                tmp_coord = find(skip_coord~=1);
                
                xtmp_interp = [];
                for j_skip_coord = 1:length(tmp_coord)
                    skip_length = skip_coord(tmp_coord(j_skip_coord));
                    skip_pos = tmp_coord(j_skip_coord);
                    xtmp_interp = [xtmp_interp linspace(xtmp(skip_pos), xtmp(skip_pos+1), skip_length+1)];
                end
                xtmp = unique(sort([xtmp xtmp_interp]));

                
                ECG = zeros(length(xtmp),num_paths);
                for jj=1:num_paths
                  % Interpolate ECG
                    y = interp1(round(time(jj,1:lengths(jj))*1e10), ecg(jj,1:lengths(jj)), round(xtmp*1e10), 'linear');

                    if j==1 && jj==1
                        intercept = ecg(1,1);
                        ECG(:,jj) = y;
                    else
                        ECG(:,jj) = y+(ecg_connect-y(1));
                    end
                    ecg_connect = ECG(end,jj);

                  % Save annotations at sampling coordinates
                    ind = interp1(xtmp,1:length(xtmp),setdiff(beat_ann(jj,:),0),'nearest');
                    ann(1:length(xtmp),jj) = 0;
                    ann(ind,jj) = 1;
                end
                
                record.ann = [record.ann find(ann(:))'+size(record.ecg,2)-1];
                record.ecg = [record.ecg -(ECG(:)'-intercept)];
                
                %plot(ECG(:))
                %figure;plot(record.ecg)
                %hold on;
                %plot(record.ann, record.ecg(record.ann), 'ok')

            case 3
              % AliveCor report / tested with aliveecg 5.7.3

                front_hit = strfind(data,'<path');
                back_hit_candidates = strfind(data,'/>');
                back_hit = front_hit;
                for jj=1:size(front_hit,2)
                    back_hit(jj) = back_hit_candidates(sum(back_hit_candidates<front_hit(jj))+1);
                end
                [out,idx] = sort([back_hit-front_hit], 'descend');

                num_paths = sum(out/out(1)>.5);
                idx = sort(idx(1:num_paths));

                time = [];
                ecg = [];
                lengths = [];
                xtmp = [];
                for jj=1:num_paths
                    cur_path = data(front_hit(idx(jj)):back_hit(idx(jj)));
                    mat_path = path2mat(cur_path);
                    x = mat_path(1,:);
                    y = mat_path(2,:);
                    if x(1)==x(2)
                        x = x(2:end);
                        y = y(2:end);
                    end
                    %plot(x,y)
                    %diff(x)               

                    lengths(jj) = length(x);
                    time(jj,1:length(x)) = x;
                    ecg(jj,1:length(y)) = y;
                    xtmp = [xtmp x];
                end

              % Linear interpolation of missing coordinates
                xtmp = sort(unique(xtmp));
                d_xtmp = diff(xtmp);
                xtmp = xtmp([true d_xtmp>.1*mean(d_xtmp)]);
                d_xtmp = diff(xtmp);
                skip_coord = round(d_xtmp/min(d_xtmp));
                tmp_coord = find(skip_coord~=1);

                xtmp_interp = [];
                for j_skip_coord = 1:length(tmp_coord)
                    skip_length = skip_coord(tmp_coord(j_skip_coord));
                    skip_pos = tmp_coord(j_skip_coord);
                    xtmp_interp = [xtmp_interp linspace(xtmp(skip_pos), xtmp(skip_pos+1), skip_length+1)];
                end
                xtmp = unique(sort([xtmp xtmp_interp]));
                
                
                for jj=1:num_paths
                    y = interp1(time(jj,1:lengths(jj)), ecg(jj,1:lengths(jj)), xtmp, 'linear');
                    ecg(jj,1:length(y)) = y;
                end

                record.ecg = [record.ecg ecg];
        end
        fclose(fid);
    end

end


if ~isempty(record)
  % Remove leading and trailing NaNs and adjust annotations
    nansum = sum(isnan(record.ecg), 1)==size(record.ecg,1);
    nanidx = find(nansum);
    if ~isempty(nanidx)
        leadingnans  = sum(nanidx==1:length(nanidx));
        trailingnans = sum(fliplr(nanidx)==size(record.ecg,2):-1:(size(record.ecg,2)-length(nanidx)+1));

        record.ecg = record.ecg(:, (leadingnans+1):(size(record.ecg,2)-trailingnans));
        if ~isempty(record.ann)
            record.ann = record.ann-leadingnans;
        end            
    end

  % Remove annotation field if empty
    if isempty(record.ann)
        record = rmfield(record,'ann');
    end

  % Remove temporary folder
    rmdir(tmp_dir, 's')    
    
end


end
