qrs_settings = table;
qrs_settings.Name(1:3,1) = {'Human ECG','Human Pulsatile','Rat ECG'};

i=1; qrs_settings.Beat_min(i)=50 ; qrs_settings.Beat_max(i)=220; qrs_settings.wl_tma(i)=.2; qrs_settings.wl_we(i,1:2)=[1/3 1/3];
i=2; qrs_settings.Beat_min(i)=50 ; qrs_settings.Beat_max(i)=220; qrs_settings.wl_tma(i)=1; qrs_settings.wl_we(i,1:2)=[1/2 1/3];
i=3; qrs_settings.Beat_min(i)=250 ; qrs_settings.Beat_max(i)=500; qrs_settings.wl_tma(i)=.04; qrs_settings.wl_we(i,1:2)=[1/15 1/15];
