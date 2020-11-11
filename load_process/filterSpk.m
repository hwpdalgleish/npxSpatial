function [filteredSpk,gdId] = filterSpk(spk)
%UNTITLED5 Summary of this function goes here
%   Detailed explanation goes here

filteredSpk = spk;
gd = spk.cgs == 2;
gdId = spk.cids(gd);
gdSpks = ismember(spk.clu,gdId);

% remove bad units
filteredSpk.st(~gdSpks) = [];
filteredSpk.spikeTemplates(~gdSpks) = [];
filteredSpk.clu(~gdSpks) = [];
filteredSpk.tempScalingAmps(~gdSpks) = [];
filteredSpk.cgs(~gd) = [];
filteredSpk.cids(~gd) = [];
toKeep = ismember(filteredSpk.cluInfo.index,gdId);
filteredSpk.cluInfo = filteredSpk.cluInfo(toKeep,:);
% filteredSpk.temps(:,:,~gd) = [];
% filteredSpk.winv(~gd,:) = [];
% filteredSpk.winv(:,~gd) = [];

end

