function [npx] = processNpx(npx,varargin)
%UNTITLED10 Summary of this function goes here
%   Detailed explanation goes here

filterUnits = true;
boxCar = true;
for v = 1:numel(varargin)
    if strncmpi(varargin{v},'filterUnits',6)
        filterUnits = varargin{v+1};
    elseif strncmpi(varargin{v},'boxCar',3)
        boxCar = varargin{v+1};
    end
end

% only include good clusters
if filterUnits
    for s = 1:numel(npx.spk)
        [npx.spk(s),gd] = filterSpk(npx.spk(s));
        npx.spk(s).gdId = gd;
    end
end

% post-process position data
if ~isempty(npx.pos)
   [xy,dir,speed,~,jumpyPercent,n_leds,dir_disp] = postprocess_pos_data_OE(npx.pos,boxCar);
   npx.pos.xy = xy;
   npx.pos.dir = dir;
   npx.pos.dir_disp = dir_disp;
   npx.pos.speed = speed;
   npx.pos.procSettings.jumpyPercent = jumpyPercent;
   npx.pos.procSettings.n_leds = n_leds;
end

% only include recording periods where spk, pos and lfp being recorded
recTypes = {'pos' 'spk' 'lfp'};
[minAllT,maxAllT] = deal([]);
for i = 1:numel(recTypes)
    for j = 1:numel(npx.(recTypes{i}))
        minAllT = [minAllT min(npx.(recTypes{i})(j).st)];
        maxAllT = [maxAllT max(npx.(recTypes{i})(j).st)];
    end
end
minAllT = max(minAllT);
maxAllT = min(maxAllT);
% pos
bothRecordingPos = npx.pos.st>=minAllT & npx.pos.st<=maxAllT;
npx.pos.st = npx.pos.st(bothRecordingPos);
% spk
fields = {'st','spikeTemplates','clu','tempScalingAmps'};
for s = 1:numel(npx.spk)
    bothRecordingSpks = npx.spk(s).st>=minAllT & npx.spk(s).st<=maxAllT;
    for f = 1:numel(fields)
        npx.spk(s).(fields{f}) = npx.spk(s).(fields{f})(bothRecordingSpks);
    end
end
% lfp
for l = 1:numel(npx.lfp)
    bothRecordingLfp = npx.lfp(l).st>=minAllT & npx.lfp(l).st<=maxAllT;
    npx.lfp(l).data = npx.lfp(l).data(:,bothRecordingLfp);
    npx.lfp(l).st = npx.lfp(l).st(bothRecordingLfp);
end

% find pos samples for each spike
npx.spk.spkPos = single(searchsorted(npx.pos.st,npx.spk.st));

% find lfp samples for each spike
npx.spk.spkLfp = single(searchsorted(npx.lfp.st,npx.spk.st));

% find pos samples for each lfp sample
npx.lfp.lfpPos = single(searchsorted(npx.pos.st,npx.lfp.st));

end

