%% Converting SVG path to Matlab matrix
%   MIT License (MIT) Copyright (c) 2020 Marcus Vollmer,
%   marcus.vollmer@uni-greifswald.de
%   last modified: 08 October 2020
%   version: 0.03

    function [mat_path, path_syntax] = path2mat(path) 
        tmp = strfind(path,'="');
        if length(tmp)>1
            tmp_d = strfind(path,'d="');
            tmp_figures = strfind(path,'Figures="');
            if ~isempty(tmp_d)
                dat = path(tmp_d+3:end);
            elseif ~isempty(tmp_figures)
                dat = path(tmp_figures+9:end);
            else
                warning(['Attribute that contains the path not found: ' path(1:100) '...'])
            end
        else
            dat = path(tmp+2:end);
        end
        dat = dat(1:min(strfind(dat,'"'))-1);
        dat = strrep(dat, ',', ' ');

        alphabet = {'M';'m';'L';'l';'V';'v';'H';'h'};
        vals = str2num(replace(dat, alphabet, {'';'';'';'';'';'';'';''}));
        
        mat_path = [];
        path_syntax = [];
        
        if isempty(vals)
            warning(['The path appears to contain no values: ' dat(1:100) '...'])
        else
            hit_s = strfind(dat,' ');
            hit_s = hit_s([true diff(hit_s)>1]);
            
            hit_idx = [];
            hit_type = [];
            for i=1:length(alphabet)
                tmp = strfind(dat,alphabet{i});
                hit_idx = [hit_idx; tmp'];
                hit_type = [hit_type; repmat(alphabet{i}, length(tmp), 1)];
            end
            if length(hit_type)>1
                hits = table(hit_idx,hit_type);
            else
                hits = table(hit_idx,{hit_type});
            end
            hits.Properties.VariableNames = {'idx','type'};
            hits = sortrows(hits,'idx','ascend'); 
                      
            for i=1:size(hits,1)
                if i==size(hits,1)
                    cur_dat = str2num(dat(hits.idx(i)+1:end));                    
                else
                    cur_dat = str2num(dat(hits.idx(i)+1:hits.idx(i+1)-1));
                end

                switch dat(hits.idx(i))
                    case 'M'
                      % M (uppercase) indicates that absolute coordinates will follow
                        mat_path = [mat_path [cur_dat(1:2:end); cur_dat(2:2:end)]];
                        path_syntax = 'M';
                    case 'm'
                      % m (lowercase) indicates that relative coordinates will follow
                        mat_path = [mat_path [cumsum(cur_dat(1:2:end)); cumsum(cur_dat(2:2:end))]];
                        path_syntax = 'm';   
                    case 'L'
                      % Draw a line from the current point to the given
                      % coordinate which becomes the new current point
                      % L (uppercase) indicates that absolute coordinates will follow
                        mat_path = [mat_path [cur_dat(1:2:end); cur_dat(2:2:end)]];                        
                        
                    case 'l'
                      % Draw a line from the current point to the given
                      % coordinate which becomes the new current point
                      % l (lowercase) indicates that relative coordinates will follow
                        mat_path = [mat_path [cumsum(cur_dat(1:2:end))+mat_path(1,end); cumsum(cur_dat(2:2:end))+mat_path(2,end)]];
                        
                    case 'V'
                      % Draws a vertical line from the current point
                      % V (uppercase) indicates that absolute coordinates will follow
                        mat_path = [mat_path [repmat(mat_path(1,end),1,length(cur_dat)); cur_dat]];
                          
                    case 'v'
                      % Draws a vertical line from the current point
                      % v (lowercase) indicates that relative coordinates will follow
                        mat_path = [mat_path [repmat(mat_path(1,end),1,length(cur_dat)); cumsum(cur_dat)+mat_path(2,end)]];
                        
                    case 'H'
                      % Draws a horizontal line from the current point
                      % H (uppercase) indicates that absolute coordinates will follow
                        mat_path = [mat_path [cur_dat; repmat(mat_path(2,end),1,length(cur_dat))]];
                        
                    case 'h'
                      % Draws a horizontal line from the current point
                      % h (lowercase) indicates that relative coordinates will follow
                        mat_path = [mat_path [cumsum(cur_dat)+mat_path(1,end); repmat(mat_path(2,end),1,length(cur_dat))]];
                end
            end            
        end
    end