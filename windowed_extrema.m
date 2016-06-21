function [wmin,wmax] = windowed_extrema(sig,wl)
%
% [wmin,wmax] = windowed_extrema(sig,wl)
%
% Computes the windowed minimum and maximum of a given time series sig.
%
% Required Parameters:
%
% sig
%       A Nx1 vector of data.
% wl
%       The window length of the filter.
%
%
% Written by Marcus Vollmer, 2014
% Last Modified: January 15, 2015
% Version 0.1
%
%endOfHelp

    ts = NaN(size(sig,1),wl);
    for j=1:wl
        ts(j:end,j) = sig(1:(end-j+1));
    end
    wmin = nanmin(ts,[],2)';
    wmax = nanmax(ts,[],2)';
    
end
