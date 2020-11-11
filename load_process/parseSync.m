function [sync,contents] = parseSync(syncFile)
% imports sync_messages.txt file, parses it and returns recording start
% time

npxStr = 'Neuropix-PXI';
subProcRe = 'subProcessor: \d+';
idRe = 'Id: \d+';
startRe = 'start time: ';

contents = importdata(syncFile);
contents = contents(contains(contents,npxStr));
sync = struct;
for i = 1:numel(contents)
    sync(i).contents = contents{i};
    
    % processor id
    sync(i).Id = str2num(syncField2Val(sync(i).contents,idRe));
    
    % subprocessor id
    sync(i).subProcessor = str2num(syncField2Val(sync(i).contents,subProcRe));
    
    % start time and rate
    startRate = cellfun(@(x) strrep(x,'Hz',''),strsplit(sync(i).contents(regexp(sync(i).contents,startRe,'end')+1:end),'@'),'UniformOutput',0);
    sync(i).startTimeSamp = str2num(startRate{1});
    sync(i).sampleRate = str2num(startRate{2});
    sync(i).startTimeSec = sync(i).startTimeSamp / sync(i).sampleRate;
    sync(i).sampleDurSec = 1/sync(i).sampleRate;
end

%%
function val = syncField2Val(syncContents,fieldRe)
   [b,e] = regexp(syncContents,fieldRe);
   chunk = strsplit(syncContents(b:e),': ');
   val = chunk{end};
end

end

