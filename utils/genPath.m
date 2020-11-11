function [p] = genPath(d,varargin)
%%
% modified version of matlab's genpath function with the option to exclude
% specific directories. For example, can be used to return full directory
% tree of open ephys neuropixels recordings for searching to find relevant
% files.
%
% Inputs:
% - d = parent directory for which to generate directory tree.

% (optional) add a string, cell array of strings of comma-separated list of
% strings to be excluded from the output.
%
% Output:
% - p = directory tree as cell array of strings 
%
% HWPD 20200617
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%

% initialise variables
classsep = '@';  % qualifier for overloaded class directories
packagesep = '+';  % qualifier for overloaded package directories
p = '';           % path to be returned
if ~isempty(varargin)
    exclude = varargin{1};
else
    exclude = '';
end
    
% Generate path based on given root directory
files = dir(d);
if isempty(files)
  return
end

% Add d to the path even if it is empty.
p = [p d pathsep];

% set logical vector for subdirectory entries in d
isdir = logical(cat(1,files.isdir));
%
% Recursively descend through directories which are neither
% private nor "class" directories.
% excluded = cellfun(@(x) any(strcmp(exclude,x)),{files(:).name});
% if any(excluded)
%     keyboard
% end
% isdir(excluded) = false;
dirs = files(isdir); % select only directory entries from the current listing

for i=1:length(dirs)
   dirname = dirs(i).name;
   if    ~strcmp( dirname,'.') && ...
         ~strcmp( dirname,'..') && ...
         ~strncmp( dirname,classsep,1) && ...
         ~strncmp( dirname,packagesep,1) && ...
         ~strcmp( dirname,'private') && ...
         ~any(strcmp(exclude, dirname))
      p = [p genPath([d filesep dirname],exclude)]; % recursive calling of this function.
   end
end


end

