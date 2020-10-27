function [filt_sig,tmavg,tmstd] = tmzscore_filter(sig,wl,pct)
%
% [filt_sig,tmavg,tmstd] = tmzscore_filter(sig,wl,pct)
%
% Applies the trimmed moving standardization to a signal 'sig'.
%
% Required Parameters:
%
% sig
%       A Nx1 vector of data.
% wl
%       The window length of the filter.
% pct
%       The percentage of extrema inside a data window which will be
%       excluded (trimming percentage).
%
%
%
% Written by Marcus Vollmer, 2015
% Last Modified: 29 June 2016
% Version 0.2
%
%endOfHelp


    if rem(wl,2)~=1
        wl=wl+1;
    end

    ts = NaN(size(sig,1)+wl-1,wl);
    for j=1:wl
        ts(j:end-wl+j,j) = sig;
    end
    ts = sort(ts((wl+1)/2:end-(wl-1)/2,:),2);
    
% trimmed moving average
    tmavg = HRV.nanmean(ts(:,1+round(wl*pct/2):end-round(wl*(1-pct)/2)),2);
    sig_tma = (sig-tmavg);
    

    
    for j=1:wl
        ts(j:end-wl+j,j) = sig_tma;
    end
    ts = sort(ts((wl+1)/2:end-(wl-1)/2,:),2);    
     
% trimmed moving standard deviation
    tmstd = HRV.nanstd(ts(:,1+round(wl*pct/2):end-round(wl*(1-pct)/2)),0,2);
    
    filt_sig = sig_tma./tmstd;    
 
end