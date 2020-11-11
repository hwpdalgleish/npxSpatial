function [pos] = processPos(pos,ppm,jumpmax)
%UNTITLED13 Summary of this function goes here
%   Detailed explanation goes here

dPos = [0 0 ; diff(double(npx.pos.xy),[],1)];
dPos = hypot(dPos(:,1),dPos(:,2));
pos.xy(dPos > jumpmax,:) = nan;

end

