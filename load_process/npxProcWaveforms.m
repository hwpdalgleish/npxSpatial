function [meanWaveform,amps] = npxProcWaveforms(waveforms)
%UNTITLED3 Summary of this function goes here
%   Detailed explanation goes here

blWindow = 1:30;
meanWaveform = squeeze(nanmean(waveforms,1));
meanWaveform = meanWaveform - nanmedian(meanWaveform(blWindow,:),1);
amps = reshape(nanmax(meanWaveform,[],1) - nanmin(meanWaveform,[],1),[],1);

end

