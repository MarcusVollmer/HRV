function [sig,unit,description,Fs,refAnn] = load_signal(folder,data)

    data = [folder data(1:max(strfind(data,'.')-1))];
    samplestr = data(max(strfind(data,'\'))+1:end);

    oldFolder = cd(data(1:max(strfind(data,'\'))-1));
    
    try
        refAnn = rdann(samplestr,'atr'); 
        refAnn_dat = 'atr';
    catch
        try
            refAnn = rdann(samplestr,'ari');
            refAnn_dat = 'ari';            
        catch
            try
                refAnn = rdann(samplestr,'ecg');
                refAnn_dat = 'ecg';
            catch
                refAnn = rdann(samplestr,'qrs');
                refAnn_dat = 'qrs';
            end
        end
    end 

     %Generate the 100m.mat and 100m.hea fiels from the *.dat and *.hea files
    wfdb2mat(samplestr)
 
    siginfo = wfdbdesc(samplestr); %computationally expensive!  
    siginfocell = squeeze(struct2cell(siginfo));
    description = siginfocell(5,:);
   
    % get Sampling Frequency
    Fs = siginfo.SamplingFrequency;    
    if ~isnumeric(Fs) || isnan(Fs)
        if strcmp(Fs(end-1:end),'Hz')
            tmp = strfind(Fs,' ');
            if isempty(tmp)
                Fs = str2num(Fs(1:end-2));
            else
                Fs = str2num(Fs(1:tmp-1));
            end
        else
            [~,~,Fs] = rdsamp(samplestr,1,1,1); 
        end
    end 

    load([samplestr 'm'])
    sig = val';

    % Gain
    gain_info = siginfocell(16,:);
    gain = zeros(1,size(gain_info,2));
    unit = cell(1,size(gain_info,2));
    for i=1:size(gain_info,2)
        tmp = gain_info{i};
        postmp = strfind(tmp,' ');
        gain(i) = str2num(tmp(1:postmp(1)-1));
        postmp = strfind(tmp,'/');
        unit{i} = tmp(postmp(1)+1:end);
    end
    sig = sig./repmat(gain,size(sig,1),1);

    delete([samplestr 'm.mat'])
    delete([samplestr 'm.hea'])  

    cd(oldFolder)
end