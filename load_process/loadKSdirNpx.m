function spikeStruct = loadKSdirNpx(ksDir,varargin)
% based on Nick Steinmetz's loadKSdir.m function but with some added
% functionality for OE recordings.

if ~isempty(varargin)
    params = varargin{1};
else
    params = [];
end

if ~isfield(params, 'excludeNoise')
    params.excludeNoise = true;
end
if ~isfield(params, 'loadPCs')
    params.loadPCs = false;
end
if ~isfield(params, 'convertIndex')
    params.convertIndex = false;
end

% load params
if exist(fullfile(ksDir, 'params.py'),'file')
    spikeStruct = loadParamsPy(fullfile(ksDir, 'params.py'));
end

% spike times
[ss,loaded] = tryLoad(fullfile(ksDir, 'spike_times.npy'));
if loaded
    st = double(ss)/spikeStruct.sample_rate;
else
    st = [];
end

% spike templates
spikeTemplates = tryLoad(fullfile(ksDir, 'spike_templates.npy'));

% spike clusters
[clu,loaded] = tryLoad(fullfile(ksDir, 'spike_clusters.npy'));
if ~loaded
    clu = spikeTemplates;
end

% spike amplitudes
tempScalingAmps = tryLoad(fullfile(ksDir, 'amplitudes.npy'));

% PCs
if params.loadPCs
    pcFeat = tryLoad(fullfile(ksDir, 'pc_features.npy')); % nSpikes x nFeatures x nLocalChannels
    pcFeatInd = tryLoad(fullfile(ksDir, 'pc_feature_ind.npy')); % nTemplates x nLocalChannels
else
    [pcFeat,pcFeatInd] = deal([]);
end

% cluster groups
cgsFile = '';
if exist(fullfile(ksDir, 'cluster_groups.csv')) 
    cgsFile = fullfile(ksDir, 'cluster_groups.csv');
end
if exist(fullfile(ksDir, 'cluster_group.tsv')) 
   cgsFile = fullfile(ksDir, 'cluster_group.tsv');
end 
if ~isempty(cgsFile)
    [cids, cgs] = readClusterGroupsCSV(cgsFile);
    if params.excludeNoise
        noiseClusters = cids(cgs==0);

        st = st(~ismember(clu, noiseClusters));
        spikeTemplates = spikeTemplates(~ismember(clu, noiseClusters));
        tempScalingAmps = tempScalingAmps(~ismember(clu, noiseClusters));        
        
        if params.loadPCs
            pcFeat = pcFeat(~ismember(clu, noiseClusters), :,:);
            pcFeatInd = pcFeatInd(~ismember(cids, noiseClusters),:);
        end
        
        clu = clu(~ismember(clu, noiseClusters));
        cgs = cgs(~ismember(cids, noiseClusters));
        cids = cids(~ismember(cids, noiseClusters));  
    end
else
    clu = spikeTemplates;
    cids = unique(spikeTemplates);
    cgs = 3*ones(size(cids));
end
  
% cluster info
if exist(fullfile(ksDir, 'cluster_info.tsv'),'file')
    clusterInfo = readClusterInfoCSV(fullfile(ksDir, 'cluster_info.tsv'));
else
    clusterInfo = [];
end

% channel map
channelMap = tryLoad(fullfile(ksDir, 'channel_map.npy'));

% channel co-ordinates
if exist(fullfile(ksDir, 'channel_positions.npy'),'file')
    channelPos = readNPY(fullfile(ksDir, 'channel_positions.npy'));
    ycoords = channelPos(:,2); xcoords = channelPos(:,1);
else
    [xcoords,ycoords,channelPos] = deal([]);
end

% convert channel channel ID to channel no. on probe
% (ID --> map --> position)
if ~isempty(clusterInfo) && ~isempty(channelMap) && ~isempty(channelPos)
    chId = zeros(clusterInfo.height,1);
    for i = 1:numel(chId)
        chId(i) = find(channelMap==clusterInfo{i,'ch'});
    end
    clusterInfo.chanX = channelPos(chId,1);
    clusterInfo.chanY = channelPos(chId,2);
end

% templates
temps = tryLoad(fullfile(ksDir, 'templates.npy'));

% whitening matrix
winv = tryLoad(fullfile(ksDir, 'whitening_mat_inv.npy'));

% assign to structure
spikeStruct.st = st;
spikeStruct.spikeTemplates = spikeTemplates;
spikeStruct.clu = clu;
spikeStruct.tempScalingAmps = tempScalingAmps;
spikeStruct.cgs = cgs;
spikeStruct.cids = cids;
spikeStruct.xcoords = xcoords;
spikeStruct.ycoords = ycoords;
spikeStruct.channelPos = channelPos;
spikeStruct.channelMap = channelMap;
spikeStruct.temps = temps;
spikeStruct.winv = winv;
spikeStruct.pcFeat = pcFeat;
spikeStruct.pcFeatInd = pcFeatInd;
spikeStruct.cluInfo = clusterInfo;

% convert 0-indexes to 1-indexes
if params.convertIndex
    spikeStruct.clu                 = spikeStruct.clu+1;
    spikeStruct.cids                = spikeStruct.cids+1;
    if ~isempty(spikeTemplates)
        spikeStruct.spikeTemplates  = spikeStruct.spikeTemplates+1;
    end
    if ~isempty(channelMap)
        spikeStruct.channelMap      = spikeStruct.channelMap+1;
    end
    if ~isempty(clusterInfo)
        spikeStruct.cluInfo.ch      = spikeStruct.cluInfo.ch+1;
        spikeStruct.cluInfo.set_index(spikeStruct.cluInfo.index+1);
    end
end

% Create mappedChannels dataframe. The index of this dataframe is the
% channel id and it returns the xy positions. This can be accessed via the
% .loc indexing method (see DataFrame documentation. So to find the xy
% positions of channels with IDs 5 and 20: 
% mappedChannels.loc([5 20],:)
if ~isempty(spikeStruct.channelPos) && ~isempty(spikeStruct.channelMap)
    spikeStruct.mappedChannels = ...
        DataFrame(spikeStruct.channelPos(:,1),spikeStruct.channelPos(:,2),...
        'VariableNames',{'x','y'},...
        'Index',spikeStruct.channelMap);
end

end

function varargout = tryLoad(filePath)
    success = exist(filePath,'file');
    if success
        data = readNPY(filePath);
    else
        data = [];
    end
    if nargout == 1
        varargout{1} = data;
    elseif nargout == 2
        varargout{1} = data;
        varargout{2} = success;
    end
end