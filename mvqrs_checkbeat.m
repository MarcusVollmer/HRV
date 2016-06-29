function [Ann,wmin,wmax,thr] = mvqrs_checkbeat(sig,Fs,wl,Beat_min,Beat_max,threshold)
%
% [Ann,wmin,wmax,thr] = mvqrs_checkbeat(sig,Fs,wl,Beat_min,Beat_max)
%
% Computes the beat annotations of a given time series 'sig'.
%
% Required Parameters:
%
% sig
%       A Nx1 vector of data.
% Fs
%       The sampling frequency in Hz.
% wl
%       The length to be assumed for the constancy criterion.
% Beat_min
%       A minimal heart rate to be assumed. (bpm)
% Beat_max
%       A maximal heart rate to be assumed. (bpm)
% threshold
%       The threshold factor is a value between 0 and 1. The higher the
%       factor the less annotations (good results with 0.5).
%
%
% Written by Marcus Vollmer, 2014
% Last Modified: 29 June 2016
% Version 0.3
%
%endOfHelp

sig = sig(:);

% compute windowed extrema of the signal
    [~,wmax] = windowed_extrema(sig,round(Fs*60/Beat_min));
    [wmin,~] = windowed_extrema(sig,round(Fs*60/(.5*Beat_max)));

% apply a moving average filter
    wmax = filter(ones(1,round(Fs*60/Beat_min))/round(Fs*60/Beat_min),1,wmax);
    wmin = filter(ones(1,round(Fs*60/Beat_max))/round(Fs*60/Beat_max),1,wmin);

% adaptive threshold
thr_range = wmax([round(Fs*60/Beat_min):length(sig) repmat(length(sig),1,round(Fs*60/Beat_min)-1)]) - ...
    wmin([round(Fs*60/Beat_max):length(sig) repmat(length(sig),1,round(Fs*60/Beat_max)-1)]);
thr = threshold*thr_range + wmin([round(Fs*60/Beat_max):length(sig) repmat(length(sig),1,round(Fs*60/Beat_max)-1)]);
thr8  = .8*threshold*thr_range + wmin([round(Fs*60/Beat_max):length(sig) repmat(length(sig),1,round(Fs*60/Beat_max)-1)]);

% threshold checkup
thr_g = sig>thr';
thr_s = sig<=thr8';

% constancy criterion
const = (diff(sig)==0)';
v = version;
if strfind(v,'R') %matlab
    cc = strfind(const,ones(1,wl-1));
else %octave
    cc = findstr(const,ones(1,wl-1));
end

% constant and above threshold
cc = cc(thr_g(cc))';

% select beginning of the constant parts
cc_accept = cc(diff([false; cc])>1);

% find last thr_s smaller than cc_accept
% (inflection point / beginning of rectangle) 
ip = [1; find(diff(thr_g)==1)];
Ann = zeros(size(cc_accept));
for i=1:size(cc_accept,1)
    Ann(i) = ip(sum(ip<=cc_accept(i))); 
end
Ann = unique(Ann);

% check if a beat annotation comes from the same rectangle
ip2 = [0; find(diff(thr_s)==1)];
if size(Ann,1)>1
    for i=2:size(Ann,1)
        if sum(ip2<Ann(i)) == sum(ip2<Ann(i-1))
            Ann(i) = Ann(i-1);
        end        
    end
end
Ann = unique(Ann);

% plot(diff(Ann))
