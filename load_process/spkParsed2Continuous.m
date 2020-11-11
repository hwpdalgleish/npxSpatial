function [continuousSpks,continuousIds] = spkParsed2Continuous(parsedSpks,parsedIds)
% converts cell array of spike times (parsedSpks), where every cell
% corresponds to a numbered unit (parsedIds), into two linear arrays where
% elements are sequential spike times and the cluster index they belong to

continuousIds = parsedSpks;
for i = 1:numel(parsedIds)
    continuousIds{i} = parsedIds(i) + (0*continuousIds{i});
end
continuousIds = single(cell2mat(continuousIds));
[continuousSpks,order] = sort(cell2mat(parsedSpks),'Ascend');
continuousIds = continuousIds(order);

end

