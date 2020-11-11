function [pos] = loadPos(posFile,posTFile,posSampleRate)
%UNTITLED12 Summary of this function goes here
%   Detailed explanation goes here

pos.xy = readNPY(posFile);
pos.xy = pos.xy(:,1:2);
pos.st = readNPY(posTFile);
pos.st = double(pos.st) / posSampleRate / 1000;
[pos.st,order] = sort(pos.st,'Ascend'); % sometimes pos samples get mixed up in time
pos.xy = pos.xy(order,:);

end

