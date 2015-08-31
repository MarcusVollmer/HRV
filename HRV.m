classdef HRV
%Heart Rate Variability
%Continuous measurement for long and short term ECG recordings. All
%available methods uses matrix operations as possible, to obtain local HRV
%measures for long sequences of RR intervals. Missing values are accepted.
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
%       fft_val_fun - Spectral analysis of sequence (LF,HF,ratio)
%       fft_val - Continuous spectral analysis (LF,HF,ratio)
%       returnmap_val - Results of the Poincare plot (SD1,SD2,ratio)
%       HR - Compute the average heart rate
%       rrx - Compute relative RR intervals
%       rrHRV - Compute HRV based on relative RR intervals
%       myquantile - Compute quantiles of each row of a matrix 
%       RRfilter - Remove artifacts from RR sequences using rrx
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
%      [1] Vollmer, M. (2015) A robust, simple and reliable measure of
%      Heart Rate Variability using relative RR intervals,
%      submitted to Computing in Cardiology,
%      preprint: coming soon
%
%   
%   MIT License (MIT) Copyright (c) 2015 Marcus Vollmer,
%   marcus.vollmer@uni-greifswald.de
%   Feel free to contact me for discussion, proposals and issues.
%   last modified: 03 July 2015
%   version: 0.12

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
    if nargin<3
        flag = 1; %The flag is 0 or 1 to specify normalization by n-1 or n.
    end
    if nargin<4
        overlap = 1;
    end
    
    dRR = diff(RR);
    if num==0
        hrv_sdsd = nanstd(dRR,flag,1);        
    else
        if ceil(num*(1-overlap))>1
            j=1;
            ts = NaN(length(ceil(num*(1-overlap)):ceil(num*(1-overlap)):length(dRR)),num);
            for i=ceil(num*(1-overlap)):ceil(num*(1-overlap)):length(dRR)
                ts(j,1:(1+i-max(1,(i-num+1)))) = dRR(max(1,(i-num+1)):i);
                j=j+1;
            end
            samplesize = sum(~isnan(ts),2);
            hrv_sdsd_tmp = nanstd(ts,flag,2); 
            hrv_sdsd_tmp(samplesize<5) = NaN;
            
            hrv_sdsd = NaN(length(RR),1);  
            hrv_sdsd(ceil(num*(1-overlap))+1:ceil(num*(1-overlap)):length(RR)) = hrv_sdsd_tmp;
        else
            ts = NaN(length(RR),num);            
            for j=1:num
                ts(j+1:end,j) = dRR(1:end-j+1);
            end
            samplesize = sum(~isnan(ts),2);
            hrv_sdsd = nanstd(ts,flag,2); 
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
%   hrv_sdnn is a column vector with the same length as RR.
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
    if nargin<3
        flag = 1; %The flag is 0 or 1 to specify normalization by n-1 or n.
    end
    if nargin<4
        overlap = 1;
    end
    
    if num==0
        hrv_sdnn = nanstd(RR,flag,1);
    else
        if ceil(num*(1-overlap))>1
            j=1;
            ts = NaN(length(ceil(num*(1-overlap)):ceil(num*(1-overlap)):length(RR)),num);
            for i=ceil(num*(1-overlap)):ceil(num*(1-overlap)):length(RR)
                ts(j,1:(1+i-max(1,(i-num+1)))) = RR(max(1,(i-num+1)):i);
                j=j+1;
            end
            samplesize = sum(~isnan(ts),2);
            hrv_sdnn_tmp = nanstd(ts,flag,2); 
            hrv_sdnn_tmp(samplesize<5) = NaN;
            
            hrv_sdnn = NaN(length(RR),1);  
            hrv_sdnn(ceil(num*(1-overlap)):ceil(num*(1-overlap)):length(RR)) = hrv_sdnn_tmp;              
        else
            ts = NaN(length(RR),num);
            for j=1:num
                ts(j:end,j) = RR(1:end-j+1);
            end
            hrv_sdnn = nanstd(ts,flag,2);
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
    if nargin<3
        flag = 1; %The flag is 0 or 1 to specify normalization by n-1 or n.
    end 
    if nargin<4
        overlap = 1;
    end
    
    dRR = diff(RR).^2;
    if num==0
        hrv_rmssd = sqrt(nansum(dRR)./(sum(~isnan(dRR))-1+flag));
    else
        if ceil(num*(1-overlap))>1
            j=1;
            ts = NaN(length(ceil(num*(1-overlap)):ceil(num*(1-overlap)):length(dRR)),num);
            for i=ceil(num*(1-overlap)):ceil(num*(1-overlap)):length(dRR)
                ts(j,1:(1+i-max(1,(i-num+1)))) = dRR(max(1,(i-num+1)):i);
                j=j+1;
            end 
            samplesize = sum(~isnan(ts),2);
            hrv_rmssd_tmp = sqrt(nansum(ts,2)./(samplesize-1+flag)); 
            hrv_rmssd_tmp(samplesize<5) = NaN;
            
            hrv_rmssd = NaN(length(RR),1);  
            hrv_rmssd(ceil(num*(1-overlap))+1:ceil(num*(1-overlap)):length(RR)) = hrv_rmssd_tmp;  
        else
            ts = NaN(length(RR),num);
            for j=1:num
                ts(j+1:end,j) = dRR(1:end-j+1);
            end    
            samplesize = sum(~isnan(ts),2);
            hrv_rmssd = sqrt(nansum(ts,2)./(samplesize-1+flag));

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
    if nargin<4
        flag = 1; %The flag is 0 or 1 to specify normalization by n-1 or n.
    end
    if nargin<5
        overlap = 1;
    end
    
    NNx = double(abs(diff(RR))>x/1000);
    NNx(isnan(diff(RR)))=NaN;
    
    if num==0
        hrv_NNx = nansum(NNx);
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
            
            hrv_NNx_tmp = nansum(ts,2);
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

            hrv_NNx = nansum(ts,2);
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
    
    if nargin<3
        flag = 1; %The flag is 0 or 1 to specify normalization by n-1 or n.
    end  
    if nargin<4
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
    if nargin<3
        w = 1/128; %recommended bin size
    end
    if nargin<4
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
            N = find(N==nanmin(N),1);
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
                N = find(N==nanmin(N),1);
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

    if nargin<4
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

    if nargin<4
        overlap = 1;
    end    
    if nargin<3
        [~,tinn] = HRV.triangular_val(RR,num);
    else
        [~,tinn] = HRV.triangular_val(RR,num,w,overlap);
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
        Y = fft(zscore(RR_rsmp),NFFT)/L;
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
    if nargin<4
        type = 'spline';
    end
    if nargin<5
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
    if nargin<3
        flag = 1; %The flag is 0 or 1 to specify normalization by n-1 or n.
    end
    if nargin<4
        overlap = 1;
    end
    
    X = [RR(1:end-1) RR(2:end)]';
    alpha = -45*pi/180;
    R = [cos(alpha) -sin(alpha); sin(alpha) cos(alpha)];
    XR = R*X;
    
    if num==0
        SD2 = nanstd(XR(1,:),flag,2);
        SD1 = nanstd(XR(2,:),flag,2);          
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
            SD2_tmp = nanstd(ts1,flag,2);
            SD1_tmp = nanstd(ts2,flag,2); 
            
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
            SD2 = nanstd(ts1,flag,2);
            SD1 = nanstd(ts2,flag,2);
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
    
    if num==0
        hr = 60*sum(double(~isnan(RR)))./nansum(RR); 
    else
        ts = NaN(length(RR),num);
        for j=1:num
            ts(j:end,j) = RR(1:end-j+1);
        end
        hr = 60*sum(double(~isnan(ts)),2)./nansum(ts,2); 
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

function [med,qr,shift] = rrHRV(RR,num,type,overlap)
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
%      then HRV.rrHRV(RR,0) is 10.8142 and [med,qr,shift] = HRV.rrHRV(RR,0)
%      results in med = 10.8142 and qr = 5.9494 and 
%      shift = [-0.2857 -1.2143].

    if nargin<3
        type = 'central';
    end
    if nargin<4
        overlap = 1;
    end

    rr_pct = round(HRV.rrx(RR,1)*1000)/10;
    valid = abs(rr_pct)<20;
    valid = valid(1:end-1)&valid(2:end);
    
    rr_med  = @(rr,z) nanmedian(sqrt(sum([rr(1:end-1)-z(1) rr(2:end)-z(2)].^2,2)));
    rr_iqr  = @(rr,z) iqr(sqrt(sum([rr(1:end-1)-z(1) rr(2:end)-z(2)].^2,2)));
   
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
                med = rr_med(rr_pct,z);
                qr = rr_iqr(rr_pct,z); 
            else
                for i=max(3,steps):steps:length(rr_pct)
                    rr_pct_part = rr_pct(max(i-num+1,1):i);
                    valid_part = valid(max(i-num+1,1):(i-1));
                    if sum(valid_part)>4
                        z = [mean(rr_pct_part([valid_part; false])) mean(rr_pct_part([false; valid_part]))];
                        shift(i,:) = z;
                        med(i) = rr_med(rr_pct_part,z);
                        qr(i) = rr_iqr(rr_pct_part,z);
                    end
                end 
            end  
            
        case 'central_shiftfilter'
            % euclidean measure to the filtered center point
            if num==0
                z = [mean(rr_pct([valid; false])) mean(rr_pct([false; valid]))];
                shift = z;
                med = rr_med(rr_pct,z);
                qr = rr_iqr(rr_pct,z); 
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
                    med(i) = rr_med(rr_pct_part,shift(i,:));
                    qr(i) = rr_iqr(rr_pct_part,shift(i,:)); 
                end             
            end
            
        case 'point2point'
            % euclidean distance of successive points 
            p2p = [NaN; sqrt(filter(ones(2,1),1,diff(rr_pct).^2))];
            if num==0
                quant = HRV.myquantile(p2p',[.25 .5 .75]);
                med = quant(2);
                qr = quant(3)-quant(1);
            else              
                ts = NaN(length(rr_pct),num);
                for j=1:num
                    ts(j:end,j) = p2p(1:(end-j+1));
                end
                quant = HRV.myquantile(ts,[.25 .5 .75]);
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
%             quant = HRV.myquantile(ts,[.25 .5 .75]);
%             med = quant(:,2);
%             qr = quant(:,3)-quant(:,1);
                     
        otherwise
            warning('Unknown rrHRV type.')
    end
   
end

function x_quant = myquantile(x,quantiles)
%myquantile Quantiles of each row of a matrix.
%   x_quant = myquantile(x,quantiles) computes quantiles of each row of a
%   matrix.
%   x is a matrix.
%   quantiles is a row vector with probabilities.
%   x_quant is a matrix containing desired quantiles.
%
%   Example: If x = [1 2 NaN; 3 4 5; 6 7 8] and quantiles=[.25 .50],
%      then HRV.myquantile(x,quantiles) is [1.0 1.5; 3.0 4.0; 6.0 7.0].

    x = sort(x,2);
    
    n = sum(~isnan(x),2);
    
    q = repmat(quantiles,size(x,1),1).*repmat(n,1,size(quantiles,2)) + ...
       repmat((0:size(x,1)-1)'*size(x,2),1,size(quantiles,2));
    q(q==0) = 1;
    
    x = x'; x = x(:);
    
    x_quant1 = (x(ceil(q))+x(ceil(q)+1))/2;
    x_quant = x(ceil(q));
    x_quant(floor(q)==ceil(q)) = x_quant1(floor(q)==ceil(q));
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


    end
    
end

