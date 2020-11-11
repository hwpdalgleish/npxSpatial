function d = parseDirFile(subDirs,dirRe,fileName)
% Searches through neuropixels spatial directory tree (subDirs) for
% specific file (fileName) in a specific directory (dirRe) Returns full
% filepath of that file. 
% Generate directory tree using genPath.m
%
% Inputs:
% - subDirs = directory tree to search (cell array of strings)
% - dirRe = regex of folder name to search in
% - fileName = string file name to search for

toSearch = subDirs(cellfun(@(x) ~isempty(regexp(x,dirRe,'once')),subDirs'));
flag = false(numel(toSearch),1);
for j = 1:numel(toSearch)
    d = dir(toSearch{j});
    flag(j) = any(strcmp({d(:).name},fileName));
end
d = toSearch(flag);

end


