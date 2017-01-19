classdef HRV
%Heart Rate Variability
%Continuous measurement for long and short term RR Intervals. All available
%methods uses matrix operations as far as possible, to obtain local HRV
%measures for long sequences of RR intervals. Missing values will be
%accepted.
%
%   Available HRV methods:
%       SDSD - Compute standard deviation of successive differences
%       SDNN - Compute standard deviation of NN intervals
%       RMSSD - Compute root mean square of successive differences
%       pNNx - Probability of intervals greater x ms or smaller -x ms
%       pNN50 - Probability of intervals greater 50ms or smaller -50ms
%       triangular_val - Compute Triangular Index and TINN
%       TRI - Compute Triangular index from the interval histogram
%       TINN - Compute TINN, performing Triangular Interpolation
%       DFA - Perform Detrended Fluctuation Analysis
%       CD - Compute the Correlation Dimension
%       ApEn - Approximate Entropy
%       fft_val_fun - Spectral analysis of sequence (LF,HF,ratio)
%       fft_val - Continuous spectral analysis (LF,HF,ratio)
%       returnmap_val - Results of the Poincare plot (SD1,SD2,ratio)
%       HR - Compute the average heart rate
%       rrx - Compute relative RR intervals
%       rrHRV - Compute HRV based on relative RR intervals
%       RRfilter - Remove artifacts from RR sequences using rrx
%       pattern - Recognition of patterns and regularities in data
%
%   Available helper functions:
%       nanmin
%       nanmax
%       nansum
%       nanmedian
%       nanquantile - Compute quantiles along a dimension of a matrix 
%       nanmean
%       nanstd
%       nanzscore
%
%
%   Example:  HRV analysis of a sythetic RR sequence having an average
%   heart rate of 60 bmp. 
%       HR = repmat(60,30,1);
%       RR = [normrnd(1,.005,size(HR,1)/3,3)-repmat([-.045 .05 .025],...
%       size(HR,1)/3,1)]';
%       RR = RR(:);
%
%       % Downsampling and plot the RR tachogram:
%       Fs = 128;
%       RR = round(RR*Fs)/Fs;
%       Ann = cumsum(RR);
%       plot(Ann,RR)
%
%       % Corresponding relative RR intervals:
%       rr = HRV.rrx(RR);
%       plot(Ann,rr)
%       plot(rr(1:end-1),rr(2:end),'Marker','o',...
%       'MarkerFaceColor',1*[1 1 1],'MarkerEdgeColor',0*[1 1 1],...
%       'MarkerSize',10,'Color',0.5*[1 1 1])
%
%       % Compute certain HRV measures for continuously for 60 successive
%       % RR intervals: 
%       rmssd = HRV.RMSSD(RR,60);
%       rrhrv = HRV.rrHRV(RR,60);
%       plotyy(Ann,rmssd,Ann,rrhrv)
%
%   Example (WFDB Toolbox required):  HRV analysis of data from Physionet
%   with the WFDB Toolbox for MATLAB. Load annotation file from a the
%   MIT-BIH Arrhythmia Database. Sampling frequency is 250 Hz.
%       Ann = rdann('mitdb/100','atr');
%       Fs = 250;
%       Ann = Ann/Fs;
%       RR = [NaN; diff(Ann)];
%
%       % The RR tachogram shows obvious artifacts:
%       plot(Ann,RR)
%
%       % Filter from artifacts and plot the average heart rate:
%       RR = HRV.RRfilter(RR,0.15);
%       plot(Ann,RR)
%
%       % Plot the average heart rate:
%       plot(Ann,HRV.HR(RR,60))
%
%       % Corresponding relative RR intervals:
%       rr = HRV.rrx(RR);
%       plot(Ann,rr)
%
%       % Compute certain HRV measures for continuously for 60 successive
%       % RR intervals: 
%       rmssd = HRV.RMSSD(RR,60);
%       rrhrv = HRV.rrHRV(RR,60);
%       plotyy(Ann,rmssd,Ann,rrhrv)
%
%
%   References:
%      [1] Vollmer, M. (2015) A Robust, Simple and Reliable Measure of
%      Heart Rate Variability using Relative RR Intervals,
%      Computing in Cardiology 2015; 42:609-612.
%      preprint: http://www.cinc.org/archives/2015/pdf/0609.pdf
%
%   Acknowledgements:
%       I want to thank Stefan Frenzel for providing source code for the
%       helper functions nanmin, nanmax, nansum, nanmedian, nanmean, nanstd
%
%   MIT License (MIT) Copyright (c) 2015 Marcus Vollmer,
%   marcus.vollmer@uni-greifswald.de
%   Feel free to contact me for discussion, proposals and issues.
%   last modified: 27 July 2016
%   version: 0.19

    properties
    end
    
    methods(Static)


function hrv_sdsd = SDSD(RR,num,flag,overlap)
%SDSD Standard deviation of successive differences.
%   hrv_sdsd = SDSD(RR,num) is the standard deviation of successive
%   differences. RR is a vector containing RR intervals in seconds. num
%   specifies the number of successive values for which the local standard
%   deviation will be retrospectively computed. hrv_sdsd is a column vector
%   with the same length as RR. hrv_sdsd has NaN values at those positions
%   for which the sample size is smaller 5.
%   If num equals 0, the global standard deviation will be computed.
%   hrv_sdsd is then a number.
%   For faster computation on local measures you can specify an overlap.
%   This is a value between 0 and 1. (default: 1)
%
%   hrv_sdsd = SDSD(RR,num,flag), where flag is 0 or 1 to specify
%   normalization by n-1 or n. (default: 1)
%
%   Example: If RR = repmat([1 .9],1,5),
%      then HRV.SDSD(RR,6) is [NaN;NaN;NaN;NaN;NaN;0.098;0.1;0.1;0.1;0.1]
%      and HRV.SDSD(RR,0,1) is 0.0994 and HRV.SDSD(RR,0,0) is 0.1054.

    RR = RR(:);
    if nargin<2 || isempty(num)
        num = 0;
    end
    if nargin<3 || isempty(flag)
        flag = 1; %The flag is 0 or 1 to specify normalization by n-1 or n.
    end
    if nargin<4 || isempty(overlap)
        overlap = 1;
    end
    
    dRR = diff(RR);
    if num==0
        hrv_sdsd = HRV.nanstd(dRR,flag,1);        
    else
        if ceil(num*(1-overlap))>1
            j=1;
            ts = NaN(length(ceil(num*(1-overlap)):ceil(num*(1-overlap)):length(dRR)),num);
            for i=ceil(num*(1-overlap)):ceil(num*(1-overlap)):length(dRR)
                ts(j,1:(1+i-max(1,(i-num+1)))) = dRR(max(1,(i-num+1)):i);
                j=j+1;
            end
            samplesize = sum(~isnan(ts),2);
            hrv_sdsd_tmp = HRV.nanstd(ts,flag,2); 
            hrv_sdsd_tmp(samplesize<5) = NaN;
            
            hrv_sdsd = NaN(length(RR),1);  
            hrv_sdsd(ceil(num*(1-overlap))+1:ceil(num*(1-overlap)):length(RR)) = hrv_sdsd_tmp;
        else
            ts = NaN(length(RR),num);            
            for j=1:num
                ts(j+1:end,j) = dRR(1:end-j+1);
            end
            samplesize = sum(~isnan(ts),2);
            hrv_sdsd = HRV.nanstd(ts,flag,2); 
            hrv_sdsd(samplesize<5) = NaN;
        end
    end    
end

function hrv_sdnn = SDNN(RR,num,flag,overlap)
%SDNN Standard deviation of NN intervals.
%   hrv_sdnn = SDNN(RR,num) is the standard deviation of NN intervals.
%   RR is a vector containing RR intervals in seconds.
%   num specifies the number of successive values for which the local
%   standard deviation will be retrospectively computed.
%   hrv_sdnn is a column vector with the same length as RR. hrv_sdnn has
%   NaN values at those positions for which the sample size is smaller 5.
%   If num equals 0, the global standard deviation will be computed.
%   hrv_sdnn is then a number.
%   For faster computation on local measures you can specify an overlap.
%   This is a value between 0 and 1. (default: 1)
%
%   hrv_sdnn = SDNN(RR,num,flag), where flag is 0 or 1 to specify
%   normalization by n-1 or n. (default: 1)
%
%   Example: If RR = repmat([1 .9],1,5),
%      then HRV.SDNN(RR,6) is [0;.05;.0471;.05;.049;.05;.05;.05;.05;.05]
%      and HRV.SDNN(RR,0,1) is 0.0500 and HRV.SDNN(RR,0,0) is 0.0527.

    RR = RR(:);
    if nargin<2 || isempty(num)
        num = 0;
    end
    if nargin<3 || isempty(flag)
        flag = 1; %The flag is 0 or 1 to specify normalization by n-1 or n.
    end
    if nargin<4 || isempty(overlap)
        overlap = 1;
    end
    
    if num==0
        hrv_sdnn = HRV.nanstd(RR,flag,1);
    else
        if ceil(num*(1-overlap))>1
            j=1;
            ts = NaN(length(ceil(num*(1-overlap)):ceil(num*(1-overlap)):length(RR)),num);
            for i=ceil(num*(1-overlap)):ceil(num*(1-overlap)):length(RR)
                ts(j,1:(1+i-max(1,(i-num+1)))) = RR(max(1,(i-num+1)):i);
                j=j+1;
            end
            samplesize = sum(~isnan(ts),2);
            hrv_sdnn_tmp = HRV.nanstd(ts,flag,2); 
            hrv_sdnn_tmp(samplesize<5) = NaN;
            
            hrv_sdnn = NaN(length(RR),1);  
            hrv_sdnn(ceil(num*(1-overlap)):ceil(num*(1-overlap)):length(RR)) = hrv_sdnn_tmp;              
        else
            ts = NaN(length(RR),num);
            for j=1:num
                ts(j:end,j) = RR(1:end-j+1);
            end
            samplesize = sum(~isnan(ts),2);
            hrv_sdnn = HRV.nanstd(ts,flag,2);
            hrv_sdnn(samplesize<5) = NaN;
        end
    end
end

function hrv_rmssd = RMSSD(RR,num,flag,overlap)  
%RMSSD Root Mean Square of Successive Differences.
%   hrv_rmssd = RMSSD(RR,num) is the root mean square of successive
%   differences.
%   RR is a vector containing RR intervals in seconds.
%   num specifies the number of successive values for which the local
%   RMSSD will be retrospectively computed.
%   hrv_rmssd is a column vector with the same length as RR. hrv_rmssd has
%   NaN values at those positions for which the sample size is smaller 5.
%   If num equals 0, the global measure will be computed.
%   hrv_rmssd is then a number.
%   For faster computation on local measures you can specify an overlap.
%   This is a value between 0 and 1. (default: 1)
%
%   hrv_rmssd = RMSSD(RR,num,flag), where flag is 0 or 1 to specify
%   normalization by n-1 or n. (default: 1)
%
%   Example: If RR = repmat([1 .9],1,5),
%      then HRV.RMSSD(RR,6) is [NaN;NaN;NaN;NaN;NaN;0.1;0.1;0.1;0.1;0.1]
%      and HRV.RMSSD(RR,0,1) is 0.1000 and HRV.RMSSD(RR,0,0) is 0.1061.

    RR = RR(:);
    if nargin<2 || isempty(num)
        num = 0;
    end
    if nargin<3 || isempty(flag)
        flag = 1; %The flag is 0 or 1 to specify normalization by n-1 or n.
    end 
    if nargin<4 || isempty(overlap)
        overlap = 1;
    end
    
    dRR = diff(RR).^2;
    if num==0
        hrv_rmssd = sqrt(HRV.nansum(dRR)./(sum(~isnan(dRR))-1+flag));
    else
        if ceil(num*(1-overlap))>1
            j=1;
            ts = NaN(length(ceil(num*(1-overlap)):ceil(num*(1-overlap)):length(dRR)),num);
            for i=ceil(num*(1-overlap)):ceil(num*(1-overlap)):length(dRR)
                ts(j,1:(1+i-max(1,(i-num+1)))) = dRR(max(1,(i-num+1)):i);
                j=j+1;
            end 
            samplesize = sum(~isnan(ts),2);
            hrv_rmssd_tmp = sqrt(HRV.nansum(ts,2)./(samplesize-1+flag)); 
            hrv_rmssd_tmp(samplesize<5) = NaN;
            
            hrv_rmssd = NaN(length(RR),1);  
            hrv_rmssd(ceil(num*(1-overlap))+1:ceil(num*(1-overlap)):length(RR)) = hrv_rmssd_tmp;  
        else
            ts = NaN(length(RR),num);
            for j=1:num
                ts(j+1:end,j) = dRR(1:end-j+1);
            end    
            samplesize = sum(~isnan(ts),2);
            hrv_rmssd = sqrt(HRV.nansum(ts,2)./(samplesize-1+flag));
            hrv_rmssd(samplesize<5) = NaN;
        end
    end
end

function [hrv_pNNx,hrv_NNx] = pNNx(RR,num,x,flag,overlap) 
%pNNx Probability of intervals greater x ms or smaller -x ms.
%   [hrv_pNNx,hrv_NNx] = pNNx(RR,num,x) computes the number for which the
%   successive RR differences exceed x milliseconds and its proportion.
%   RR is a vector containing RR intervals in seconds.
%   num specifies the number of successive values for which the local
%   measure will be retrospectively computed.
%   x is a number which specifies the limit of successive differences in
%   milliseconds.
%   hrv_pNNx is a column vector with the same length as RR. hrv_pNNx has
%   NaN values at those positions for which the sample size is smaller 5.
%   If num equals 0, the global measure will be computed.
%   hrv_pNNx is then a number.
%   For faster computation on local measures you can specify an overlap.
%   This is a value between 0 and 1. (default: 1)
%
%   [hrv_pNNx,hrv_NNx] = pNNx(RR,num,x,flag), where flag is 0 or 1 to
%   specify normalization by n-1 or n. (default: 1)
%
%   Example: If RR = repmat([1 .98 .9],1,3),
%      then HRV.pNNx(RR,6,20) is [NaN;NaN;NaN;NaN;NaN;1;1;1;1]
%      and  HRV.pNNx(RR,6,150) is [NaN;NaN;NaN;NaN;NaN;0;0;0;0]
%      and [hrv_pNNx,hrv_NNx] = HRV.pNNx(RR,0,20,0) is hrv_pNNx = 1.1429
%      and hrv_NNx = 8. 

    RR = RR(:);
    if nargin<3 || isempty(num) || isempty(x)
        error('HRV.pNNx: wrong number or types of arguments');
    end
    if nargin<4 || isempty(flag)
        flag = 1; %The flag is 0 or 1 to specify normalization by n-1 or n.
    end
    if nargin<5 || isempty(overlap)
        overlap = 1;
    end
    
    NNx = double(abs(diff(RR))>x/1000);
    NNx(isnan(diff(RR)))=NaN;
    
    if num==0
        hrv_NNx = HRV.nansum(NNx);
        hrv_pNNx = hrv_NNx./(sum(~isnan(NNx))-1+flag);
    else 
        if ceil(num*(1-overlap))>1
            j=1;
            ts = NaN(length(ceil(num*(1-overlap)):ceil(num*(1-overlap)):length(NNx)),num);
            for i=ceil(num*(1-overlap)):ceil(num*(1-overlap)):length(NNx)
                ts(j,1:(1+i-max(1,(i-num+1)))) = NNx(max(1,(i-num+1)):i);
                j=j+1;
            end 
            samplesize = sum(~isnan(ts),2);
            
            hrv_NNx_tmp = HRV.nansum(ts,2);
            hrv_pNNx_tmp = hrv_NNx_tmp./(samplesize-1+flag);
            hrv_pNNx_tmp(samplesize<5) = NaN;
    
            hrv_NNx = NaN(length(RR),1);  
            hrv_NNx(ceil(num*(1-overlap))+1:ceil(num*(1-overlap)):length(NNx)+1) = hrv_NNx_tmp;        
            hrv_pNNx = NaN(length(RR),1);  
            hrv_pNNx(ceil(num*(1-overlap))+1:ceil(num*(1-overlap)):length(NNx)+1) = hrv_pNNx_tmp;  
        else
            ts = NaN(length(RR),num);
            for j=1:num
                ts(j+1:end,j) = NNx(1:end-j+1);
            end    
            samplesize = sum(~isnan(ts),2);

            hrv_NNx = HRV.nansum(ts,2);
            hrv_pNNx = hrv_NNx./(samplesize-1+flag);
            hrv_pNNx(samplesize<5) = NaN;
        end
    end
end

function hrv_pNN50 = pNN50(RR,num,flag,overlap)
%pNN50 Probability of intervals greater 50 ms or smaller -50 ms.
%   hrv_pNN50 = pNN50(RR,num) computes the proportion for which the
%   successive RR differences exceed 50 milliseconds.
%   RR is a vector containing RR intervals in seconds.
%   num specifies the number of successive values for which the local
%   measure will be retrospectively computed.
%   hrv_pNN50 is a column vector with the same length as RR. hrv_pNN50 has
%   NaN values at those positions for which the sample size is smaller 5.
%   If num equals 0, the global measure will be computed.
%   hrv_pNN50 is then a number.
%   For faster computation on local measures you can specify an overlap.
%   This is a value between 0 and 1. (default: 1)
%
%   [hrv_pNN50 = pNN50(RR,num,x,flag), where flag is 0 or 1 to
%   specify normalization by n-1 or n. (default: 1)
%
%   Example: If RR = repmat([1 .98 .9],1,3),
%      then HRV.pNN50(RR,6) is [NaN;NaN;NaN;NaN;NaN;0.6;.6667;.6667;.6667]
%      and HRV.pNN50(RR,6,0) is [NaN;NaN;NaN;NaN;NaN;0.75;.8;.8;.8]. 

    if nargin<2 || isempty(num)
        num = 0;
    end    
    if nargin<3 || isempty(flag)
        flag = 1; %The flag is 0 or 1 to specify normalization by n-1 or n.
    end  
    if nargin<4 || isempty(overlap)
        overlap = 1;
    end    
    hrv_pNN50 = HRV.pNNx(RR,num,50,flag,overlap);
end

function [TRI,TINN] = triangular_val(RR,num,w,overlap) 
%triangular_val Triangular Index and TINN.
%   [TRI,TINN] = triangular_val(RR,num) computes the triangular index (TRI)
%   and TINN value. TRI is the reciprocal of the probability of the
%   hightest bin of the histogram of RR intervals with bin size w.
%   TINN is the width of the trinangular function, which has the best fit
%   to the sample histogram.
%   RR is a vector containing RR intervals in seconds.
%   num specifies the number of successive values for which the local
%   measure will be retrospectively computed.
%   w is the bin size of the histogram.
%   TRI and TINN are column vectors with the same length as RR.
%   If num equals 0, the global measure will be computed.
%   Then, TRI and TINN are numbers.
%   For faster computation on local measures you can specify an overlap.
%   This is a value between 0 and 1. (default: 1)
%
%   [TRI,TINN] = triangular_val(RR,num,w), where w is the histogram bin
%   size. (default: w = 1/128)
%
%   Example: If RR = repmat([1 .98 .9],1,3),
%      then [TRI,TINN] = HRV.triangular_val(RR,6) is 
%      TRI = [1;2;3;2;2.5;3;3;3;3] and
%      TINN = [.0156;.0156;.0156;.0156;.0156;.0156;.0156;.0156;.0156;.0156] 
%      and HRV.triangular_val(RR,0,1/64) is 3. 
  
    RR = RR(:);
    if nargin<2 || isempty(num)
        num = 0;
    end
    if nargin<3 || isempty(w)
        w = 1/128; %recommended bin size
    end
    if nargin<4 || isempty(overlap)
        overlap = 1;
    end  
    
    TI_N  = @(N,h) sum((interp1([N length(h)],[0 max(h)],N:length(h))-h(N:length(h))).^2)+sum(h(1:N-1).^2);
    TI_M  = @(M,h) sum((interp1([1 M],[max(h) 0],1:M)-h(1:M)).^2)+sum(h(M+1:end).^2);
    
    if num==0
    	h = histcounts(RR,0:w:5);
        TRI = sum(h)/max(h);
        TRI_X = find(h==max(h),1);
        % search for N and M for triangular interpolation

        if find(h~=0,1)<TRI_X-1
            N = NaN(TRI_X-1,1);
            for i=1:TRI_X-1
                N(i) = TI_N(i,h(1:TRI_X));
            end
            N = find(N==HRV.nanmin(N),1);
        else
            N = TRI_X-1;
        end

        if TRI_X<find(h~=0,1,'last')
            M = NaN(length(h)-TRI_X,1);
            for i=1:(length(h)-TRI_X)
                M(i) = TI_M(i+1,h(TRI_X:end));
            end
            M = find(M==min(M),1,'last')+TRI_X;
        else
            M = TRI_X+1;
        end
        
        TINN = (M-N)*w;
        
    else
        TRI = NaN(size(RR));
        TINN = NaN(size(RR));
        
        if overlap==1
            steps = 1; 
        else
            steps = ceil(num*(1-overlap));
        end
        for j=steps:steps:length(RR)

            h = histcounts(RR(max([1 j-num+1]):j),0:w:5);
            TRI(j) = sum(h)/max(h);

            TRI_X = find(h==max(h),1);
            % search for N and M for triangular interpolation

            if find(h~=0,1)<TRI_X-1
                N = NaN(TRI_X-1,1);
                for i=find(h~=0,1):TRI_X-1
                    N(i) = TI_N(i,h(1:TRI_X));
                end
                N = find(N==HRV.nanmin(N),1);
            else
                N = TRI_X-1;
            end

            if TRI_X<find(h~=0,1,'last')
                M = NaN(length(h)-TRI_X,1);
                for i=1:find(h~=0,1,'last')-TRI_X
                    M(i) = TI_M(i+1,h(TRI_X:end));
                end
                M = find(M==min(M),1,'last')+TRI_X;
            else
                M = TRI_X+1;
            end
            
            TINN(j) = (M-N)*w;
        end   
    end
end

function tri = TRI(RR,num,w,overlap) 
%TRI Triangular Index.
%   tri = TRI(RR,num) computes the triangular index (TRI).
%   TRI is the reciprocal of the probability of the
%   hightest bin of the histogram of RR intervals with bin size w.
%   RR is a vector containing RR intervals in seconds.
%   num specifies the number of successive values for which the local
%   measure will be retrospectively computed.
%   w is the bin size of the histogram.
%   TRI is a column vector with the same length as RR.
%   If num equals 0, the global measure will be computed.
%   Then, TRI is a numbers.
%   For faster computation on local measures you can specify an overlap.
%   This is a value between 0 and 1. (default: 1)
%
%   tri = TRI(RR,num,w), where w is the histogram bin size.
%   (default: w=1/128)
%
%   Example: If RR = repmat([1 .98 .9],1,3),
%      then HRV.TRI(RR,6) is [1;2;3;2;2.5;3;3;3;3]
%      and HRV.TRI(RR,0,1/64) is 3. 

    if nargin<2 || isempty(num)
        num = 0;
    end
    if nargin<4 || isempty(overlap)
        overlap = 1;
    end 
    if nargin<3
        [tri,~] = HRV.triangular_val(RR,num);
    else
        [tri,~] = HRV.triangular_val(RR,num,w,overlap);
    end    
end

function tinn = TINN(RR,num,w,overlap) 
%TINN Triangular Interpolation of NN histogram.
%   tinn = TINN(RR,num) computes the TINN value.
%   TINN is the width of the trinangular function, which has the best fit
%   to the NN histogram with bin size w.
%   RR is a vector containing RR intervals in seconds.
%   num specifies the number of successive values for which the local
%   measure will be retrospectively computed.
%   w is the bin size of the histogram.
%   TINN is a column vectors with the same length as RR.
%   If num equals 0, the global measure will be computed.
%   Then, TINN is a number.
%   For faster computation on local measures you can specify an overlap.
%   This is a value between 0 and 1. (default: 1)
%
%   tinn = TINN(RR,num,w), where w is the histogram bin size.
%   (default: w=1/128)
%
%   Example: If RR = repmat([1 .98 .9],1,3),
%      then HRV.TINN(RR,6) is
%      [.0156;.0156;.0156;.0156;.0156;.0156;.0156;.0156;.0156;.0156]
%      and HRV.TINN(RR,0,1/64) is 0.0313.

    if nargin<2 || isempty(num)
        num = 0;
    end
    if nargin<4 || isempty(overlap)
        overlap = 1;
    end    
    if nargin<3
        [~,tinn] = HRV.triangular_val(RR,num);
    else
        [~,tinn] = HRV.triangular_val(RR,num,w,overlap);
    end 
end

function alpha = DFA(RR,boxsize_short,boxsize_long,grade,~) 
%DFA Detrended Fluctuation Analysis of NN histogram.
%    Examples: 
%       Ann = rdann('mitdb/100','atr');
%       RR = diff(Ann);
%       alpha = HRV.DFA(RR) 
%       alpha = HRV.DFA(RR,5:13,14:200) 
%       alpha = HRV.DFA(RR(2:100),5:16,16:32,2,1)
%
%       for i=1:100:500
%           alpha = HRV.DFA(RR(i:end))
%       end

    if nargin<5
        graph = false;
    else
        graph = true;        
    end
    if nargin<4 || isempty(grade)
        grade = 1;
    end     
    if nargin<3 || isempty(boxsize_long)
        boxsize_long = 16:64;
    end 
    if nargin<2 || isempty(boxsize_short)
        boxsize_short = 4:16;
    end    
    boxsize = [boxsize_short boxsize_long];
    
    
    y = cumsum(RR-HRV.nanmean(RR));

    trend = zeros(size(RR,1),length(boxsize));
    F = NaN(length(boxsize),1);
    for bs=1:size(trend,2)
        bs_tmp = boxsize(bs);
        for i=0:floor((size(RR,1)-2)/bs_tmp)
            if i==floor((size(RR,1)-2)/bs_tmp)
                x = i*bs_tmp+1:size(RR,1);
            else
                x = i*bs_tmp+1:(i+1)*bs_tmp;
            end
            [p,~,mu] = polyfit(x',y(x),grade);
            trend(x,bs) = polyval(p,(x - mu(1))/mu(2));
        end    
        F(bs) = sqrt(sum((y-trend(:,bs)).^2)/size(RR,1));
    end
   
    [p1,~,mu1] = polyfit(log(boxsize_short),log(F(1:length(boxsize_short)))',1);
    [p2,~,mu2] = polyfit(log(boxsize_long),log(F(length(boxsize_short)+1:end))',1);
    alpha = [p1(1)/mu1(2) p2(1)/mu2(2)];

    if graph
        figure
        ax(1) = subplot(3,2,1);
            plot(1:size(RR,1),RR-HRV.nanmean(RR)); axis tight; hold on;
            plot([0 size(RR,1)],[0 0],'k','linewidth',2)
        ax(2) = subplot(3,2,3);     
            plot(1:size(RR,1),y); hold on;
            plot(1:size(RR,1),trend(:,end)); axis tight;
            set(gca,'XTick',boxsize(end):boxsize(end):size(RR,1)); grid on
        ax(3) = subplot(3,2,5);   
            plot(1:size(RR,1),(y-trend(:,end)).^2); axis tight;
            set(gca,'XTick',boxsize(end):boxsize(end):size(RR,1)); grid on
        linkaxes(ax,'x');

        subplot(3,2,[2 4 6]);
            loglog(boxsize,F,'or'); axis tight; grid on; hold on;     
            plot(boxsize_short,exp(polyval(p1,(log(boxsize_short) - mu1(1))/mu1(2))),'k','linewidth',2)
            plot(boxsize_long,exp(polyval(p2,(log(boxsize_long) - mu2(1))/mu2(2))),'k','linewidth',2)
    end
end

function cdim = CD(RR,m,r,~) 
%CD Correlation Dimension.
%    Example: 
%       Ann = rdann('mitdb/100','atr');
%       RR = diff(Ann);
%       Fs = 250;
%       cdim = HRV.CD(RR,10,[1:20])
%       cdim = HRV.CD(RR/Fs,10,[1:20]/Fs) 
%       cdim = HRV.CD(RR,10,1:100) 

    if nargin<4
        graph = false;
    else
        graph = true;        
    end
    if nargin<3
        r = [50:100]/1000;
    end    
    if nargin<2
        m = 10;
    end 
    
    d = NaN(length(RR),2*length(RR));
    for i=1:length(RR)
        d(i,length(RR)+1-i:2*length(RR)-i) = (RR(i)-RR).^2;
    end 
    d = d(:,1:length(RR)-1);
    D = reshape(filter(ones(m,1),1,d(:)),length(RR),length(RR)-1);

    %correlation integral
    C = zeros(size(r));
    for i=1:length(r)
        C(i) = 2*sum(sum(D<=r(i)^2))/...
            ((length(RR)-m+1)*(length(RR)-m));
    end
    [p1,~,mu1] = polyfit(log10(r(C>0)),log10(C(C>0)),1);
    cdim = p1(1);
    
    if graph
        figure
        scatter(log10(r),log10(C)); axis tight;
        grid on; hold on;     
        plot(log10(r(C>0)),polyval(p1,(log10(r(C>0)) - mu1(1))/mu1(2)),'k','linewidth',2)
    end
end

function apen = ApEn(RR,num,m,r) 
%ApEn Approximate Entropy.
%   num specifies the number of successive values for which the local
%   measure will be retrospectively computed.
%    Example: 
%       Ann = rdann('mitdb/100','atr');
%       apen = HRV.ApEn(diff(Ann))
%       Ann = rdann('nsr2db/nsr001','ecg');
%       apen = HRV.ApEn(diff(Ann(1:1000)))

    if nargin<4 || isempty(r)
        r = .2*HRV.SDNN(RR);
    end    
    if nargin<3 || isempty(m)
        m = 2;
    end  
    if nargin<2 || isempty(num)
        num = 0;
    end 
    
    d = NaN(m+1,2*length(RR));  
    Cm = zeros(length(RR)-m+1,1);
    Cm1 = zeros(length(RR)-m,1);
    for i=1:m
        d(i,length(RR)+1-i:2*length(RR)-i) = abs(RR(i)-RR);
    end
    for i=m+1:length(RR)
        d(mod(i-1,m+1)+1,:) = NaN;
        d(mod(i-1,m+1)+1,length(RR)+1-i:2*length(RR)-i) = abs(RR(i)-RR);
        Dm = max(d(mod([i-m:i-1]-1,m+1)+1,:),[],'includenan');
        Dm1 = max(d,[],'includenan');
        Cm(i-m) = sum(Dm<=r,2);
        Cm1(i-m) = sum(Dm1<=r,2);  
    end
    i=i+1;
    Dm = max(d(mod([i-m:i-1]-1,m+1)+1,:),[],'includenan');
    Cm(i-m) = sum(Dm<=r,2);
    
    %correlation integral
    Cm  = Cm./(length(RR)-m+1);
    Cm1 = Cm1./(length(RR)-m);
     
% More clear procedure, but requires to much memory:
% tic   
%     d = NaN(length(RR),2*length(RR));
%     for i=1:length(RR)
%         d(i,length(RR)+1-i:2*length(RR)-i) = abs(RR(i)-RR);
%     end 
%     
%     Dm  = NaN(length(RR)-m+1,2*length(RR));
%     Dm1 = NaN(length(RR)-m,2*length(RR));
%     for i=1:length(RR)-m
%         Dm(i,:)  = max(d(i:i+m-1,:),[],'includenan');
%         Dm1(i,:) = max(d(i:i+m,:),[],'includenan');        
%     end
%     Dm(i+1,:) = max(d(i+1:i+m,:),[],'includenan');
%     
%     %correlation integral
%     Cm  = (sum(Dm <=r,2))./(length(RR)-m+1);
%     Cm1 = (sum(Dm1<=r,2))./(length(RR)-m);    
% toc

    if num==0
        apen = mean(log(Cm))/mean(log(Cm1));
    else
        apen = filter(ones(num,1)/num,1,[NaN(m-1,1); log(Cm)])./...
            filter(ones(num,1)/num,1,[NaN(m,1); log(Cm1)]);
    end
end


function [pLF,pHF,LFHFratio,VLF,LF,HF,f,Y,NFFT] = fft_val_fun(RR,Fs,type)
%fft_val_fun Spectral analysis of a sequence.
%   [pLF,pHF,LFHFratio,VLF,LF,HF,f,Y,NFFT] = fft_val_fun(RR,Fs,type)
%   uses FFT to compute the spectral density function of the interpolated
%   RR tachogram.  The density of very low, low and high frequency parts
%   will be estimated.
%   RR is a vector containing RR intervals in seconds.
%   Fs specifies the sampling frequency.
%   type is the interpolation type. Look up interp1 function of Matlab for
%   accepted types (default: 'spline').
%
%   Example: If RR = repmat([1 .98 .9],1,20),
%      then [pLF,pHF,LFHFratio,VLF,LF,HF] = HRV.fft_val_fun(RR,1000) yields
%      pLF = 5.4297 and pHF = 94.5703 and pHFratio = 0.0574 and
%      VLF = 0.0505 and LF = 0.1749 and HF = 3.0467.
%      [pLF,pHF,LFHFratio] = HRV.fft_val_fun(RR,1000,'linear') yields
%      pLF = 4.0484 and pHF = 95.9516 and LFHFratio = 0.0422.
%
%   See also INTERP1, FFT.

    RR = RR(:);
    if nargin<2 || isempty(Fs)
        error('HRV.fft_val_fun: wrong number or types of arguments');
    end   
    if nargin<3
        type = 'spline';
    end
    
    switch type
        case 'none'
            RR_rsmp = RR;
        otherwise
            if sum(isnan(RR))==0 && length(RR)>1
                ANN = cumsum(RR)-RR(1);
                % use interp1 methods for resampling
                RR_rsmp = interp1(ANN,RR,0:1/Fs:ANN(end),type);
            else
                RR_rsmp = [];
            end
    end
    
    % FFT
    L = length(RR_rsmp); 
    
    if L==0 
        pLF = NaN;
        pHF = NaN;
        LFHFratio = NaN;
        VLF = NaN;
        LF = NaN;
        HF = NaN;
        f = NaN;
        Y = NaN;
        NFFT = NaN;
    else
        NFFT = 2^nextpow2(L);
        Y = fft(HRV.nanzscore(RR_rsmp),NFFT)/L;
        f = Fs/2*linspace(0,1,NFFT/2+1);  

        YY = 2*abs(Y(1:NFFT/2+1));

        VLF = sum(YY(f<=.04));
        LF = sum(YY(f<=.15))-VLF;  
        HF = sum(YY(f<=.4))-VLF-LF;
        TP = sum(YY(f<=.4));

        pLF = LF/(TP-VLF)*100;
        pHF = HF/(TP-VLF)*100;    
        LFHFratio = LF/HF; 
    end
end

function [pLF,pHF,LFHFratio,VLF,LF,HF] = fft_val(RR,num,Fs,type,overlap) 
%fft_val Spectral analysis.
%   [pLF,pHF,LFHFratio,VLF,LF,HF] = fft_val(RR,num,Fs,type) uses FFT to
%   compute the spectral density function of the interpolated RR tachogram.
%   RR is a vector containing RR intervals in seconds.
%   num specifies the number of successive values for which the spectral
%   density function will be estimated. The density of very low, low and
%   high frequency parts will be computed.   
%   Fs specifies the sampling frequency.
%   type is the interpolation type. Look up interp1 function of Matlab for
%   accepted types (default: 'spline').
%   For faster computation on local measures you can specify an overlap.
%   This is a value between 0 and 1. (default: 1)
%
%   Example: If RR = repmat([1 .98 .9],1,20),
%      then [~,~,LFHFratio] = HRV.fft_val(RR,60,1000) results in
%      LFHFratio = [NaN;NaN;NaN;0;0; ... ;0.0933;0.0828;0.0574].
%
%   See also INTERP1, FFT.
    
    RR = RR(:);
    if nargin<3 || isempty(num) || isempty(Fs)
        error('HRV.fft_val: wrong number or types of arguments');
    end
    if nargin<4 || isempty(type)
        type = 'spline';
    end
    if nargin<5 || isempty(overlap)
        overlap = 1;
    end
    
    if num==0
        [pLF,pHF,LFHFratio,VLF,LF,HF,~,~,~] = HRV.fft_val_fun(RR,Fs,type);    
    else
        pLF = NaN(size(RR));
        pHF = NaN(size(RR));
        VLF = NaN(size(RR));
        LF = NaN(size(RR));
        HF = NaN(size(RR));
        LFHFratio = NaN(size(RR));
        
        if overlap==1
            steps = 1; 
        else
            steps = ceil(num*(1-overlap));
        end
        for j=steps:steps:length(RR)
            [pLF(j),pHF(j),LFHFratio(j),VLF(j),LF(j),HF(j),~,~,~] = ...
                HRV.fft_val_fun(RR(max([1 j-num+1]):j),Fs,type);
        end
    end
end

function [SD1,SD2,SD1SD2ratio] = returnmap_val(RR,num,flag,overlap)
%returnmap_val Results of the Poincare plot.
%   [SD1,SD2,SD1SD2ratio] = returnmap_val(RR,num) computes standard
%   deviations along the identity line and its perpendicular axis of the
%   return map of RR intervals, also known as Poincare map. This is done by
%   rotation of the coordinates. 
%   RR is a vector containing RR intervals in seconds.
%   num specifies the number of successive values for which the standard
%   deviations will be computed.  
%   If num equals 0, the global standard deviations will be computed.
%   SD1, SD2 and SD1SD2ratio are then numbers. Otherwise vectors of the
%   same length as RR.
%   For faster computation on local measures you can specify an overlap.
%   This is a value between 0 and 1. (default: 1)
%
%   [SD1,SD2,SD1SD2ratio] = returnmap_val(RR,num,flag), where flag is 0 or
%   1 to specify normalization by n-1 or n. (default: 1)
%
%   Example: If RR = repmat([1 .98 .9],1,3),
%      then [~,~,SD1SD2ratio] = HRV.returnmap_val(RR,6) results in
%      SD1SD2ratio = [NaN;NaN;0.6;1.7321;1.4354;1.4195;1.732;1.732;1.732].

    RR = RR(:);
    if nargin<2 || isempty(num)
        num = 0;
    end    
    if nargin<3 || isempty(flag)
        flag = 1; %The flag is 0 or 1 to specify normalization by n-1 or n.
    end
    if nargin<4 || isempty(overlap)
        overlap = 1;
    end
    
    X = [RR(1:end-1) RR(2:end)]';
    alpha = -45*pi/180;
    R = [cos(alpha) -sin(alpha); sin(alpha) cos(alpha)];
    XR = R*X;
    
    if num==0
        SD2 = HRV.nanstd(XR(1,:),flag,2);
        SD1 = HRV.nanstd(XR(2,:),flag,2);          
    else
        steps = ceil(num*(1-overlap));
        if steps>1
            j=1;
            ts1 = NaN(length(steps:steps:length(RR)-1),num);
            ts2 = ts1;            
            for i=steps:steps:length(RR)-1
                ts1(j,1:i-max(1,i-num+1)+1) = XR(1,max(1,i-num+1):i);
                ts2(j,1:i-max(1,i-num+1)+1) = XR(2,max(1,i-num+1):i);                
                j=j+1;
            end
            SD2_tmp = HRV.nanstd(ts1,flag,2);
            SD1_tmp = HRV.nanstd(ts2,flag,2); 
            
            SD2 = NaN(length(RR),1);
            SD1 = NaN(length(RR),1);
            SD2(steps+1:steps:length(RR)) = SD2_tmp;
            SD1(steps+1:steps:length(RR)) = SD1_tmp;
        else
            ts1 = NaN(length(RR),num);
            ts2 = NaN(length(RR),num);    
            for j=1:num
                ts1(j+1:end,j) = XR(1,1:end-j+1);
                ts2(j+1:end,j) = XR(2,1:end-j+1);        
            end
            SD2 = HRV.nanstd(ts1,flag,2);
            SD1 = HRV.nanstd(ts2,flag,2);
        end
    end
    SD1SD2ratio = SD1./SD2;
end

function hr = HR(RR,num) 
%HR Average heart rate.
%   hr = HR(RR,num) is the average heart rate of NN intervals.
%   RR is a vector containing RR intervals in seconds.
%   num specifies the number of successive values for which the local
%   average heart rate will be computed.
%   If num equals 0, the global haert rate will be computed.
%   hr is a column vector with the same length as RR.
%
%   Example: If RR = repmat([1 .9],1,5),
%      then HRV.HR(RR,7) is [60.0000;63.1579;62.0690;63.1579;62.5000;...
%      63.1579;62.6866;63.6364;62.6866;63.6364].
    
    RR = RR(:);
    if nargin<2 || isempty(num)
        num = 0;
    end   
    
    if num==0
        hr = 60*sum(double(~isnan(RR)))./HRV.nansum(RR); 
    else
        ts = NaN(length(RR),num);
        for j=1:num
            ts(j:end,j) = RR(1:end-j+1);
        end
        hr = 60*sum(double(~isnan(ts)),2)./HRV.nansum(ts,2); 
    end
end

function rr = rrx(RR,grade)
%rrx Relative RR intervals of grade x.
%   rr = rrx(RR) computes relative RR intervals of grade 1, which is the
%   the difference of consecutive RR intervals weighted by their mean. 
%   RR is a vector containing RR intervals in seconds.
%   rr is a vector of the same length as RR. rr(1) is NaN due to the fact,
%   that a predessor for the first RR interval is missing.
%
%   rr = rrx(RR,grade), to specify the grade for comparing RR(i) with
%   RR(i-grade). (default: 1)
%
%   Example: If RR = repmat([1 .98 .9],1,3),
%      then HRV.rrx(RR) is [NaN;-0.0202;-0.0851;0.1053;-0.0202;-0.0851;...
%      0.1053;-0.0202;-0.0851] and HRV.rrx(RR,3) is
%      [NaN;NaN;NaN;0;0;0;0;0;0;0] 

    RR = RR(:);
    if nargin<2
        grade = 1;
    end
    rr = [NaN(grade,1); 2*(RR((1+grade):end)-RR(1:(end-grade)))./...
        (RR((1+grade):end)+RR(1:(end-grade)))];
end

function [med,qr,shift] = rrHRV(RR,num,type,overlap,grade,tolerance)
%rrHRV HRV based on relative RR intervals.
%   [med,qr,shift] = rrHRV(RR,num) computes the euclidean distance to the
%   center point of the return map of relative RR intervals of grade 1.
%   RR is a vector containing RR intervals in seconds.
%   num specifies the number of successive values for which the local
%   average heart rate will be computed.
%   med and qr are vectors of the same length as RR which is median (HRV)
%   and the interquartile range (annular intensity) of the euclidean
%   distance. 
%   shift is a matrix with the coordinates of the center point.
%   If num equals 0, the global measures will be computed.
%   For faster computation on local measures you can specify an overlap.
%   This is a value between 0 and 1. (default: 1)
%
%   [med,qr,shift] = rrHRV(RR,num,type), to specify the type of distance
%   measure (experimental usage). (default: 'central')
%   'central': The center point is computed from coordinates between -20
%   and +20 percent.
%   'central_shiftfilter': The center point is moving average filtered of
%   all coordinates in shift. Distances will be renewed.
%   'point2point': Without the use of a center point. Uses the length of
%   connected coordinates of the return map (The euclidean distance of
%   (rr(i),rr(i+1)) with (rr(i+1),rr(i+2))).
%
%   Example: If RR = repmat([1 .98 .9],1,3),
%      then HRV.rrHRV(RR) is 10.846 and [med,qr,shift] = HRV.rrHRV(RR)
%      results in med = 10.846 and qr = 6.8389 and 
%      shift = [-0.2899 -1.2171].

    if nargin<2 || isempty(num)
        num = 0;
    end
    if nargin<3 || isempty(type)
        type = 'central';
    end
    if nargin<4 || isempty(overlap)
        overlap = 1;
    end
    if nargin<5 || isempty(grade)
        grade = 1;
    end
    if nargin<6 || isempty(tolerance)
        tolerance = 20;
    end    

    rr_pct = HRV.rrx(RR,grade)*100;
    valid = abs(rr_pct)<tolerance;
    valid = valid(1:end-1) & valid(2:end);
    
    rr_med  = @(rr,z,valid) HRV.nanmedian(sqrt(sum([rr([valid; false])-z(1) rr([false; valid])-z(2)].^2,2)));
    rr_iqr  = @(rr,z,valid) diff(HRV.nanquantile(sqrt(sum([rr([valid; false])-z(1) rr([false; valid])-z(2)].^2,2)),[.25 .75]));
   
    if num>0
        med = NaN(size(rr_pct));
        qr = NaN(size(rr_pct));
        shift = NaN(length(rr_pct),2);        
    end
    
    if overlap==1
        steps = 1; 
    else
        steps = ceil(num*(1-overlap));
    end
    
    switch type
        case 'central'
            % euclidean measure to the center point
            if num==0
                z = [mean(rr_pct([valid; false])) mean(rr_pct([false; valid]))];
                shift = z;
                med = rr_med(rr_pct,z,valid);
                qr = rr_iqr(rr_pct,z,valid); 
            else
                for i=max(3,steps):steps:length(rr_pct)
                    rr_pct_part = rr_pct(max(i-num+1,1):i);
                    valid_part = valid(max(i-num+1,1):(i-1));
                    if sum(valid_part)>4
                        z = [mean(rr_pct_part([valid_part; false])) mean(rr_pct_part([false; valid_part]))];
                        shift(i,:) = z;
                        med(i) = rr_med(rr_pct_part,z,valid_part);
                        qr(i) = rr_iqr(rr_pct_part,z,valid_part);
                    end
                end 
            end  
            
        case 'central_shiftfilter'
            % euclidean measure to the filtered center point
            if num==0
                z = [mean(rr_pct([valid; false])) mean(rr_pct([false; valid]))];
                shift = z;
                med = rr_med(rr_pct,z,valid);
                qr = rr_iqr(rr_pct,z,valid); 
            else
                for i=3:length(rr_pct)
                    rr_pct_part = rr_pct(max(i-num+1,1):i);
                    valid_part = valid(max(i-num+1,1):(i-1));
                    if sum(valid_part)>4
                        z = [mean(rr_pct_part([valid_part; false])) mean(rr_pct_part([false; valid_part]))];
                        shift(i,:) = z;
                    end
                end
                shift = filter(ones(9,1)/9,1,shift);
                for i=max(3,steps):steps:length(rr_pct)
                    rr_pct_part = rr_pct(max(i-num+1,1):i);
                    valid_part = valid(max(i-num+1,1):(i-1));
                    med(i) = rr_med(rr_pct_part,shift(i,:),valid_part);
                    qr(i) = rr_iqr(rr_pct_part,shift(i,:),valid_part); 
                end             
            end
            
        case 'point2point'
            % euclidean distance of successive points 
            p2p = [NaN; sqrt(filter(ones(2,1),1,diff(rr_pct).^2))];
            if num==0
                quant = HRV.nanquantile(p2p',[.25 .5 .75]);
                med = quant(2);
                qr = quant(3)-quant(1);
            else              
                ts = NaN(length(rr_pct),num);
                for j=1:num
                    ts(j:end,j) = p2p(1:(end-j+1));
                end
                quant = HRV.nanquantile(ts,[.25 .5 .75]);
                med = quant(:,2);
                qr = quant(:,3)-quant(:,1);
            end
            
%         case 'allpoints'
%             % distance of all points to eachother           
%             p2p = NaN(length(rr_pct),num-1);
%             for j=1:num-1            
%                 p2p(:,j) = [NaN(j,1); sqrt(filter(ones(2,1),1,(rr_pct(j+1:end)-rr_pct(1:end-j)).^2))];
%                 p2p(j+1,j) = NaN;
%             end
%             
%             ts = NaN(length(rr_pct),nchoosek(num,2));
%             tmp = 1;
%             for j=1:num
%                 ts(:,tmp:tmp+num-j-1) = p2p(:,1:(end-j+1));
%                 tmp = tmp+num-j;
%             end
%             quant = HRV.nanquantile(ts,[.25 .5 .75]);
%             med = quant(:,2);
%             qr = quant(:,3)-quant(:,1);
                     
        otherwise
            warning('HRV.m: Unknown rrHRV type.')
    end
   
end


function RR = RRfilter(RR,limit)
%RRfilter Artifact filtering from RR sequences.
%   RR = RRfilter(RR,limit) removes artifacts from RR sequences using
%   relative RR intervals. 
%   RR is a vector containing RR intervals in seconds.
%   limit is a number in percent which specifies the boundary of trusted
%   relative RR intervals. (default: 20)
%
%   Example: If RR = [1.0 .98 .9 .1 .4 1.0 .98 .9],
%      then HRV.RRfilter(RR) is [1.00;0.98;0.90;NaN;NaN;NaN;0.98;0.90].

    RR = RR(:);
    if nargin<2
        limit = 20;
    end
    
    RR(RR>4) = NaN; %RR interval more than 4 seconds
    rr_pct = 100*HRV.rrx(RR);

    % unreasonable beat differences
    RR(rr_pct>max([limit 50]) & [rr_pct(2:end)<-max([limit 50]); false]) = NaN; %one inrecognized beat
    rr_pct = 100*HRV.rrx(RR);

    for wbp_lim = [80:-10:limit]-rem(limit,10)
        wbp = find(abs(diff(rr_pct))>wbp_lim);    
        wbp = wbp(diff(wbp)==1);
        wbp = wbp(diff(wbp)==1);  
        RR(wbp+1) = NaN; RR(wbp+2) = NaN; %wrong beat positions
        rr_pct = 100*HRV.rrx(RR); 
    end

    postmp = find(isnan(RR(1:(end-2))));
    RR(postmp(abs(rr_pct(postmp+2))>15)+1) = NaN; %unreasonble differences after NaN-values
    rr_pct = 100*HRV.rrx(RR);

    postmp = find(abs(rr_pct)>max([limit 50]));
    RR(postmp-1) = NaN; RR(postmp) = NaN; %unreasonble rr_pct values

end


function p = pattern(RR,grades,num)
%pattern Recognition of patterns and regularities in data.

    hrv_grade = struct; j=1;
    p = zeros(10,length(grades));
    for i=grades
        hrv_grade.(['grade' num2str(i)])= HRV.rrHRV(RR,num,[],[],i);          
        for k=1:10
            p(k,j) = sum(hrv_grade.grade1./hrv_grade.(['grade' num2str(i)])>(1+k/10))/size(hrv_grade.grade1,1);
        end
        j=j+1;
    end
    
    figure
    for i=grades
        plot(1:length(RR),hrv_grade.grade1./hrv_grade.(['grade' num2str(i)]))
        hold on
    end
    legend(num2str(grades(:)))
end

function rrx_view(RR,grades,xl)

    rr = struct;
    figure
    j=1;
    n1 = ceil(sqrt(length(grades)));
    n2 = ceil(length(grades)/n1);
    for i=grades
        rr.(['grade' num2str(i)]) = HRV.rrx(RR,i);
        subplot(n2,n1,j)
        plot(rr.(['grade' num2str(i)])(xl),rr.(['grade' num2str(i)])(xl+1),'o-k')
        xlim([-.15 .15])
        ylim([-.15 .15])
        grid on
        title(['grade' num2str(i)])
        j=j+1;
    end
end




% The following functions are helper functions to be independent from
% matlab toolboxes 
function m = nanmin(x,y,varargin)
    if (nargin == 1) %one variable only
        xnan = isnan(x);
        x(xnan) = inf;
        m = min(x);
        m(all(xnan)) = NaN;
    elseif (nargin == 2) %two variables
        xnan = isnan(x); x(xnan) = inf;
        ynan = isnan(y); y(ynan) = inf;      
        m = min(x,y);
        m(xnan & ynan) = NaN;
    elseif (nargin >= 3)        
        dim = varargin{1};
        xnan = isnan(x); x(xnan) = inf;
        ynan = isnan(y); y(ynan) = inf;
        m = min(x, y, dim);
        if isempty(y) %one variable, dimension specified                  
            m(all(xnan,dim)) = nan;               
        else %two variables, dimension specified
            m(xnan & ynan) = nan;
        end
    end    
end


function m = nanmax(x,y,varargin)
    if (nargin == 1) %one variable only
        xnan = isnan(x);
        x(xnan) = inf;
        m = max(x);
        m(all(xnan)) = NaN;
    elseif (nargin == 2) %two variables
        xnan = isnan(x); x(xnan) = inf;
        ynan = isnan(y); y(ynan) = inf;      
        m = max(x,y);
        m(xnan & ynan) = NaN;
    elseif (nargin >= 3)        
        dim = varargin{1};
        xnan = isnan(x); x(xnan) = inf;
        ynan = isnan(y); y(ynan) = inf;
        m = max(x, y, dim);
        if isempty(y) %one variable, dimension specified                  
            m(all(xnan,dim)) = nan;               
        else %two variables, dimension specified
            m(xnan & ynan) = nan;
        end
    end    
end


function s = nansum(x, varargin)
    if (nargin < 2) % check input
        dim = find(size(x)>1, 1);
        if isempty(dim)
            dim=1;
        end
    else
        dim = varargin{1};
    end
    
    % replace nans with zeros and compute the sum
    x(isnan(x)) = 0;
    s = sum(x, dim);    
end


function med = nanmedian(x,varargin)
     if nargin < 2 % check input
         dim = find(size(x)>1, 1);
         if isempty(dim)
             dim=1;
         end
     else
         dim = varargin{:};
     end
 
     % determine number of regular (not nan) data points
     n = sum(not(isnan(x)), dim);
     if n==0 
         med = NaN;
     elseif isempty(n)
         med = [];
     else     
         % sort data (nans move to the end)
         x = sort(x, dim);

         % calculate median of regular data points only
         sx = size(x);
         step = prod(sx(1:dim-1)); %linear indexing step between consecutive points along dimension
         start = reshape((0:(prod(sx)/sx(dim)-1)), size(n));
         start = floor(start / prod(sx(1:dim-1))) * prod(sx(1:dim)) + ...
                    mod(start, prod(sx(1:dim-1))); %first point along dimension
         med = x(start + step*ceil(n./2-0.5)+1)/2 + x(start + step*floor(n./2-0.5)+1)/2;
     end
end


function x_quant = nanquantile(x,quantiles,varargin)
%nanquantile Computes empirical quantiles of each column or row of a matrix
%without any interpolation scheme.
%   x_quant = nanquantile(x,quantiles) computes quantiles of each column of
%   a matrix.
%   x is a matrix.
%   quantiles is a vector with probabilities.
%   dim specifies in which dimension the quantiles will be computed.
%   x_quant is a matrix containing desired quantiles.
%
%   Example: If x = [1 2 NaN; 3 4 5; 6 7 8] and quantiles=[.25 .50],
%      then HRV.nanquantile(x,quantiles) is [1.0 3.0 6.0; 1.5 4.0 7.0]
%      and HRV.nanquantile(x,quantiles,2) is [1.0 3.0; 2.0 4.0; 5.0 6.5].

    if (nargin < 3) % check input
        dim = find(size(x)==1, 1);
        if isempty(dim)
            dim=1;
        end
    else
        dim = varargin{1};
    end
    quantiles = quantiles(:);
    
    if isempty(x)
        x_quant = NaN(size(quantiles));
    else    
        if dim==1
            x = x';
        end

        x = sort(x,1);
        n = sum(~isnan(x),1);    
        q = repmat(quantiles,1,size(x,2)).*repmat(n,size(quantiles,1),1) + ...
            repmat((0:(size(x,2)-1))*size(x,1),size(quantiles,1),1);              

        q(q==0) = 1;
        x = x(:);

        x_quant1 = (x(ceil(q))+x(min(size(x,1),ceil(q)+1)))/2;
        x_quant = x(ceil(q));
        x_quant(floor(q)==ceil(q)) = x_quant1(floor(q)==ceil(q));
    end
    
    if dim>1
        x_quant = x_quant';
    end    
end


function m = nanmean(x, varargin)
    if (nargin < 2) % check input
        dim = find(size(x)>1,1);
        if isempty(dim)
            dim = 1;
        end
    else
        dim = varargin{1};
    end

    % determine number of regular (not nan) data points
    n = sum(not(isnan(x)),dim);

    % replace nans with zeros and compute mean value(s)
    x(isnan(x)) = 0;
    n(n==0) = nan;
    m = sum(x,dim)./n;
end


function s = nanstd(x, opt, varargin)
    if (nargin < 3) % check input
        dim = find(size(x)>1,1);
        if isempty(dim)
            dim = 1;
        end
    else
        dim = varargin{1};
    end
     
    if (nargin < 2) || isempty(opt)
        opt = 0;
    end
 
    % determine number of regular (not nan) data points and nans
    n = sum(not(isnan(x)),dim);
	nnan = sum(isnan(x),dim);
     
    % replace nans with zeros, remove mean value(s) and compute squared sums
    x(isnan(x)) = 0;
    m = sum(x, dim)./n;
    x = x-repmat(m, size(x)./size(m));
    s = sum(x.^2, dim);

    % remove contributions of added zeros
    s = s-(m.^2).*nnan;

    % normalization
    if (opt == 0)
        s = sqrt(s./max(n-1,1));
    elseif (opt == 1)
        s = sqrt(s./n);
    else
        error('HRV.nanstd: unkown normalization type');
    end
end


function [z,m,s] = nanzscore(x,opt,varargin)
    if (nargin < 3) % check input
        dim = find(size(x)>1,1);
        if isempty(dim)
            dim = 1;
        end
    else
        dim = varargin{1};
    end

    if (nargin < 2) || isempty(opt)
        opt = 0;
    end

    % compute mean value(s) and standard deviation(s)
    m = HRV.nanmean(x,dim);
    s = HRV.nanstd(x,opt,dim);    
    % computer z scores
    z = (x-repmat(m,size(x)./size(m)))./repmat(s,size(x)./size(s));
end




    end
    
end

