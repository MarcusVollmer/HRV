function myAnn = singleqrs(signal,Fs,varargin)
%
% singleqrs(signal,Fs,...)
%
% Octave-compatible code for heart beat detection in one bio signal
%
% Required Parameters:
%
% signal
%       String specifying the name of the record to process.  Do not include
%       the '.dat' or '.hea' suffix in recordName.
% Fs
%       An integer variable which specifies the sampling rate (in Hz).
%
% The record name can be followed by parameter/value pairs to specify
% additional properties of the QRS detection.
%
% threshold
%       The threshold factor is a value between 0 and 1. The higher the
%       factor the less annotations. (default: 0.5)
% downsampling
%       An integer variable which specifies the frequency (in Hz) of the
%       time series which will be triggered by omission. (default: 80)
% debugmode
%       An true-false variable which enables the debug mode of the
%       calculation. Various figures will show false negative and false
%       positive annotations. Therefor a 'atr','ari' or 'ecg' file must
%       exists in the same folder as the record file. (default: 0)
%       By now: only available using Matlab.
% wl_tma
%       An integer variable which specifies the length of the trimmed
%       moving average filter. (default: ceil(.2*Fs))
%       For ECG signals the default value of ceil(.2*Fs), for pulsatile
%       signals a value of ceil(Fs) is recommended.
% wl_we
%       An vector of integer variables which specifies the window length of
%       windowed extrema. First value is for minima, second for windowed
%       maxima. (default: ceil(Fs/3) for both)
%       For ECG signals the default value of ceil(Fs/3), for pulsatile
%       signals the vector [ceil(1.5*Fs/3) ceil(Fs/3)] is recommended.      
%
% This function has one output argument:
% myAnn
%       A vector containing the Annotation.
%
% Dependencies:
%
%       1) This function requires the WFDB Toolbox 0.9.7 and later for
%          MATLAB and Octave. 
%          For information on how to install the toolbox, please see:
%              http://www.physionet.org/physiotools/matlab/wfdb-app-matlab/
%
%       2) The Toolbox is supported only on 64-bit MATLAB 2013a - 2015a
%          and on GNU Octave 3.6.4 and later, on Linux, Mac OS X, and Windows.
%
%       3) On 64-bit MATLAB you will need the Statistics Toolbox (till
%          2014b) or Statistics and Machine Learning Toolbox (since 2015a).
%
%
% Written by Marcus Vollmer, January 07, 2016.
%
% Last Modified: 29 June 2016
% Version 0.3
%
% %Example:
% [~,signal,Fs]=rdsamp('mitdb/100',1,10000);
% Ann = singleqrs(signal,Fs);
%
% [~,signal]=rdsamp('challenge/2014/set-p/100',2);
% Fs = 250;
% Ann = singleqrs(signal,Fs,'downsampling',80,'wl_tma',Fs,...
%   'wl_we',[ceil(1.5*Fs/3) ceil(Fs/3)]);
%
%endOfHelp

%Get signal 
if nargin<2
    error('At least two arguments are needed: The signal and sampling frequency.')
end  

%Set default parameter values
    threshold = .5;
    downsampling = Fs;
    debugmode = 0;  
    pct=.25;
    R=.4;
    Beat_min=50;
    Beat_max=220;
    wl_tma = ceil(.2*Fs);
    wl_we = ceil(Fs/3);
    debug_file = 'debug.mat';
 
%Set parameter values by argument
if nargin>2
    inputs = {'threshold','downsampling','debugmode','pct','R','Beat_min','Beat_max','wl_tma','wl_we','debug_file','output_file'};
    for n=3:2:nargin
        tmp = find(strcmp(varargin{n-2},inputs), 1);
        if(~isempty(tmp))
            eval([inputs{tmp} ' = varargin{n-1};'])
        else
            error(['''' varargin{n} ''' is not an accepted input argument.'])
        end
    end
end


% Downsampling by filter (moving average)
    factor = max([1 floor(Fs/downsampling)]);                     
    Fs = Fs/factor;
    sig = filter((1/factor)*ones(1,factor),1,signal);
    sig = sig(1:factor:end,:);

% High-pass filtering and standardization
    if debugmode==0
        sig_tma = tma_filter(sig,ceil(wl_tma/factor),pct);	% trimmed moving average
        clear sig;
    else
        [sig_tma,tma] = tma_filter(sig,ceil(wl_tma/factor),pct);	% trimmed moving average        
    end
    sig_tmzscore = HRV.nanzscore(sig_tma);             % zscore filter
    clear sig_tma;
    
% Compute annotations
    if debugmode>=1
        [Ann,valid,tmpmin,tmpmax,wmin,wmax,range,thr] = mvqrs_ann(sig_tmzscore,Fs,ceil(wl_we/factor),Beat_min,Beat_max,threshold,R);
    else
        Ann = mvqrs_ann(sig_tmzscore,Fs,ceil(wl_we/factor),Beat_min,Beat_max,threshold,R);  
    end        
    Ann = Ann(Ann>0 & Ann<=size(sig_tmzscore,1));
    myAnn = Ann*factor;  

    
% % Write annotation file
% % see Issue ID52:
% % wrann(recordName,output_file,myAnn);
% if size(myAnn,1)<2500
%     wrann(recordName,output_file,myAnn);
% else
%     wrann(recordName,output_file,myAnn(1:2000)); 
%     for ann_num=2:ceil(size(myAnn,1)/2000)
%         wrann(recordName,[output_file num2str(ann_num)],myAnn((ann_num-1)*2000+1:min(ann_num*2000,size(myAnn,1))));
%         mrgann(recordName,output_file,[output_file num2str(ann_num)],'qrs_merge')
%         copyfile([recordName '.qrs_merge'],[recordName '.' output_file])
%         delete([recordName '.' output_file num2str(ann_num)])
%     end
%     delete([recordName '.qrs_merge'])
% end
% % For more information, run 'help wrann'.


% Open figures in debugmode
    if debugmode>=1
        tolerance = floor(.15*Fs);
        save record_debug.mat sig tma sig_tmzscore tmpmin tmpmax wmin wmax valid range thr Ann Fs factor tolerance Beat_min Beat_max threshold wl_tma wl_we;
        movefile('record_debug.mat',debug_file);
    end

end