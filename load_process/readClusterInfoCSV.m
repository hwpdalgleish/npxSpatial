

function [clustInfo] = readClusterInfoCSV(filename)
% read in cluster_info.tsv

clustInfo = tdfread(filename);
nId = numel(clustInfo.id);
[group,KSLabel] = deal(cell(nId,1));
for i = 1:nId
    group{i} = strtrim(clustInfo.group(i,:));
    KSLabel{i} = strtrim(clustInfo.KSLabel(i,:));
end
clustInfo.group = group;
clustInfo.KSLabel = KSLabel;
clustInfo = DataFrame(struct2table(clustInfo),'Index','id');