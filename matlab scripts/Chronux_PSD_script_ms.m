% %  author: SK
% %  date: 28/03/2024
% %  reference :"Neural effects of dopaminergic compounds revealed by multi-site electrophysiology in mice and interpretable machine-learning"

clear all; close all; clc;

%%Specify the path of chronux toolbox
addpath(genpath('-----EEG_AnalysisMatlabToolBox\chronux_2_12')) % Chronux toolbox path
%%Specify the directory to save data
save_dir = 'path to save power mat files';


%%Provide directory for Raw Ephys mat files
[FileList] = dir(fullfile('paht to matlab files', '*.mat'));

    
%% loop through all raw files one by one 
%%compute PSD and save it back to specified directory
for Fname = 1:length(FileList)  
    
    %%%Load mat file
    load(strcat(FileList(Fname).folder, '\', FileList(Fname).name));
    
    %%%Get data from array
    data = Ephys.PP_Data.data'; %% data dim should be [Times X Channels]
    
    
    %% params for spectral analysis 
    params.Fs     = 1000;     % sampling frequency
    params.fpass  = [0 200];  % frequency range for which to analyse
    params.pad    = -1;       % -1 is No pad, etc
    movingwin     = [20 20];  % takes a 20s segment of data to generate the power (this is slid along a 20s moving window)
    params.tapers = [1,20,1]; % uses a 20s window
    params.err    = [2 0.05]; % jackknife error bars (required for the coherence plots)
     
    %% Collect timestamps for pre-injection and post-injection time points 
    Pre_Inj_Start  = Ephys.TimeStamps.Pre_Inj_Start;
    Post_Inj_Start = Ephys.TimeStamps.Post_Inj_Start;

    %% Cut the data according to time stamps and create one array
    pre_inj_data  = data(Pre_Inj_Start:(Pre_Inj_Start+round(1000*60*10)-1),:);   %%% 10 mins(1000*60*10)
    post_inj_data = data(Post_Inj_Start:Post_Inj_Start+round((1000*60*50)-1),:); %%% 50 mins(1000*60*50)
    data = cat(1, pre_inj_data,post_inj_data);

    Power = [];
    %% loop through channels one by one and concat data to array
    for Chn =1:size(data,2)
        [S,t,f] = mtspecgramc(data(:,Chn),movingwin, params);                  
        Power.PSD(Chn,:,:) = S;           
        Power.freqs = f;
        Power.times = t;
        Power.dims  = 'Chn X Times X Freqs';

    end  
    
    Ephys.Chronux = Power;
    %% optional to remove all the unwanted data array
    Ephys.RawData = [];
    Ephys.Data = [];
    Ephys.Coherence = [];
    Ephys.PP_Data = [];
    Ephys.TTL     = [];

    FileName = strcat(Ephys.MouseID,'_',Ephys.ExptDetails.Experiment,...
        '_ChronuxPSD_20s20s_', Ephys.ExptDetails.Day);
    save(fullfile(save_dir,FileName),'Ephys', '-v7.3')    

end



