function [Ann,valid,tmpmin,tmpmax,wmin,wmax,range,thr] = mvqrs_ann(sig,Fs,wl_we,Beat_min,Beat_max,threshold,R)
%
% [Ann,valid,tmpmin,tmpmax,wmin,wmax,range,thr] = mvqrs_ann(sig,Fs,wl_we,Beat_min,Beat_max,threshold,R)
%
% Computes the beat annotations of a given time series 'sig'.
%
% Required Parameters:
%
% sig
%       A Nx1 vector of data.
% Fs
%       The sampling frequency in Hz.
% wl_we
%       The window length of Windowed Extrema.
% Beat_min
%       A minimal heart rate to be assumed. (bpm)
% Beat_max
%       A maximal heart rate to be assumed. (bpm)
% threshold
%       The threshold factor is a value between 0 and 1. The higher the
%       factor the less annotations (good results with 0.5).
% R
%       A threshold for annotations to be declined whenever the signal
%       quality is too low.
%
%
% Written by Marcus Vollmer, 2014
% Last Modified: 29 June 2016
% Version 0.4
%
%endOfHelp


n = size(sig,1);
valid = ones(n,1);

if length(wl_we)==1
    [tmpmin,tmpmax] = windowed_extrema(sig,wl_we);  % windowed extrema   
elseif length(wl_we)==2
    [tmpmin,~] = windowed_extrema(sig,wl_we(1));  % windowed extrema
    [~,tmpmax] = windowed_extrema(sig,wl_we(2));  % windowed extrema
else
    error('Inappropriate use of wl_we.')
end

[Ann,wmin,wmax,thr] = mvqrs_checkbeat(tmpmax-tmpmin,Fs,round(Fs/25),Beat_min,Beat_max,threshold); % check beat with feature extraction

% valid parts of time series using range filter 
shift_wmax = round(Fs*60/Beat_min);
shift_wmin = round(Fs*60/Beat_max);
range = wmax(shift_wmax:end)-wmin(shift_wmin:end-shift_wmax+shift_wmin);
range(n-shift_wmax+1:n) = range(n-shift_wmax);   
for k=1:n
    if range(k)<=R
       valid(max(1,k-round(shift_wmin/2)):min(n,k+round(shift_wmax/2))) = 0;
    end
end

Ann = Ann(valid(Ann)==1); % valid annotations

