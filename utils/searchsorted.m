function [b2a] = searchsorted(a,b,varargin)
% Find indices where elements should be inserted to maintain order.

% Finds indices b2a in sorted array a where if elements of b were inserted
% into a at b2a then the sorted order of the resultant vector would be
% preserved. 

% i.e. for each element in b finds the index of the closest following
% element in a

sortFlag = false;
if ~isempty(varargin)
    sortFlag = varargin{v+1};
end
if sortFlag
    a = sort(a,'Ascend');
end

edges = [-Inf a' +Inf]';
[~,~,b2a] = histcounts(b, edges);
b2a(end) = b2a(end-1);

end