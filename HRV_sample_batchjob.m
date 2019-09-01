% Sample Batch Job for the Analysis of Heart Rate Variability with HRV.m
%
% This file shows sample code for batch processing. It includes the heart
% beat detection in a loop of patients/records, computes some HRV measures
% using function from HRV.m, and saves results into an Excel spreadsheet.
%
%   MIT License (MIT) Copyright (c) 2019 Marcus Vollmer,
%   marcus.vollmer@uni-greifswald.de
%   Feel free to contact me for discussion, proposals and issues.
%   last modified: 01 September 2019
%   version: 0.01


%set the path to your working directory
  path = 'C:\Users\yourpath';
% set your output file
  outputfile = 'results.xlsx';

n = 10; % set the number of recordings
for id = 1:n
    
  % settings for automated beat detection
    load('qrs_settings.mat')
    s = 1;    % s=1 for human ECG settings
    Fs = 256; % set your sampling frequency
    Beat_min = qrs_settings.Beat_min(s);
    Beat_max = qrs_settings.Beat_max(s);
    wl_tma = ceil(qrs_settings.wl_tma(s)*Fs);
    wl_we  = ceil(qrs_settings.wl_we(s,:).*Fs);
    d_fs = Fs;

  % Import waveform (ECG) - use an appropriate import function
    sig_waveform = loadwaveform;
    Ann = [];

  % Heart beat detection
    seg = ceil(length(sig_waveform)/(300*Fs));
    if seg>2        
        for i=0:seg
            sig_waveform_tmp = sig_waveform(max(300*Fs*i-10*Fs,1):min(300*Fs*(i+1),length(sig_waveform)));
            if sum(isnan(sig_waveform_tmp)) ~= length(sig_waveform_tmp)
                Ann_tmp = singleqrs(sig_waveform_tmp,Fs,'downsampling',d_fs,'Beat_min',Beat_min,'Beat_max',Beat_max,'wl_tma',wl_tma,'wl_we',wl_we); 
                Ann = [Ann; Ann_tmp+max(300*Fs*i-10*Fs,1)];
            end
        end
        Ann = Ann(Ann>0 & Ann<=length(sig_waveform));
        Ann = unique(sort(Ann));
        Ann(diff(Ann)<.05*Fs)=[];
    else
        Ann = singleqrs(sig_waveform,Fs,'downsampling',d_fs,'Beat_min',Beat_min,'Beat_max',Beat_max,'wl_tma',wl_tma,'wl_we',wl_we);
    end 
    Ann = Ann/Fs;


  % RR intervals and filtering of artifacts
    RR = diff(Ann);
    RR_filt = HRV.RRfilter(RR,20);

  % Computation of local HRV measures
	RR_loc = RR_filt;

	rrHRV_loc = HRV.rrHRV(RR_loc,0);
	SDNN_loc  = HRV.SDNN(RR_loc,0)*1000;
	RMSSD_loc = HRV.RMSSD(RR_loc,0)*1000;
	pNN50_loc = HRV.pNN50(RR_loc,0)*100;
	HR_loc    = HRV.HR(RR_loc,0);

  % Save results in an Excel spreadsheet
	Column = calc_xls_idx(1+2);
	xlRange_HR    = ([Column  num2str(id+3)]);
	xlRange_SDNN  = ([Column  num2str(id+4)]);
	xlRange_RMSSD = ([Column  num2str(id+5)]);
	xlRange_pNN50 = ([Column  num2str(id+6)]);
	xlRange_rrHRV = ([Column  num2str(id+7)]);
	xlswrite([path filesep outputfile], rrHRV_loc, [xlRange_rrHRV ':' xlRange_rrHRV]);
	xlswrite([path filesep outputfile], SDNN_loc,  [xlRange_SDNN  ':' xlRange_SDNN]);
	xlswrite([path filesep outputfile], RMSSD_loc, [xlRange_RMSSD ':' xlRange_RMSSD]);
	xlswrite([path filesep outputfile], pNN50_loc, [xlRange_pNN50 ':' xlRange_pNN50]);
	xlswrite([path filesep outputfile], HR_loc,    [xlRange_HR    ':' xlRange_HR]);           

end
