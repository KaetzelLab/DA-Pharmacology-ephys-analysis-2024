%%%  author: SK
%%%  date: 28/03/2024
%%%  reference :"Neural effects of dopaminergic compounds revealed by multi-site electrophysiology in mice and interpretable machine-learning"

clear all; close all; clc;

%%Specify the directory to save data
save_dir = '\\preprocessed';

%%Specify the path of chronux toolbox
addpath(genpath('D:\EEG_AnalysisMatlabToolBox\eeglab2020_0'))

%%Provide directory for Raw Ephys mat files
[FileList] = dir(fullfile('\\RawMatFiles', '*.mat'));


%% loop through all raw files one by one 
%% remove line noise and save it back to specified directory

for Fname = 1:length(FileList)  
    %%%Load mat file
    load(strcat(FileList(Fname).folder, '\', FileList(Fname).name));
  
    data = Ephys.RawData';
    Ephys.PP_Data = [];

    StimList       = {'Continuous'};
    EpochRange     = [0 size(data,1)];

    frames  = EpochRange(1)+EpochRange(2);
    tlimits = [-EpochRange(1) EpochRange(2)];

    dataformat = 'matlab';      %%Input data format array is a Matlab array in the global workspace.
    srate      = 1000;          %%Data sampling rate in Hz {default: 1Hz}
    subject    = Ephys.MouseID; %%{default: none -> each dataset from a different subject}
    condition  = 'Continuous';  %%task condition. For example, Targets{default: none -> all datasets from one condition}
    group      = '';            %%subject group. For example Patients or Control.{default: none -> all subjects in one group}
    session    = '';            %%session number (from the same subject). All datasets from the same subject and session will be assumed to use the
    nbchan     = size(data,1);  %%Number of data channels. 
    xmin       = 0;             %%Data epoch start time (in seconds).{default: 0}
    pnts       = size(data,2);  %%Number of data points per data epoch. The number of trial

    %%%%%%%%%%%%%%%%%-------------------------------------------------------------------------------------------------------------
    
    %% Create EEG lab data stracture from mat array
    EEG = pop_importdata( 'data',data, 'dataformat','matlab', 'subject',subject,...
        'condition',condition, 'group',group, 'nbchan',nbchan,...
        'xmin',xmin, 'pnts',pnts, 'session',session, 'srate',srate);% 
    EEG = eeg_checkset(EEG); 
    
    signal      = struct('data', EEG.data, 'srate', EEG.srate);
    
    %% parameters for line noise
    lineNoiseIn = struct('lineNoiseMethod', 'clean', ...
                         'lineNoiseChannels', 1:EEG.nbchan,...
                         'Fs', EEG.srate, ...
                         'lineFrequencies', [50 100 150 200 250],...%% Change 60, 120, 180 depending on grid power
                         'p', 0.01, ...
                         'fScanBandWidth', 2, ...
                         'taperBandWidth', 2, ...
                         'taperWindowSize', 4, ...
                         'taperWindowStep', 1, ...
                         'tau', 100, ...
                         'pad', 2, ...
                         'fPassBand', [0 EEG.srate/2], ...
                         'maximumIterations', 10);

    [clnOutput, lineNoiseOut] = cleanLineNoise(signal, lineNoiseIn);
       

    Ephys.PP_Data = clnOutput;
   
    FileName = append(Ephys.MouseID,'_',Ephys.ExptDetails.Experiment, '_', Ephys.ExptDetails.Day);
    
    save(fullfile(save_dir,FileName),'Ephys', '-v7.3');  
    disp(Ephys.MouseID)         
end

