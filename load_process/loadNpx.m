function [npx] = loadNpx(in,varargin)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Written by HWPD 20200717
%
% loads all relevant data for npx recordings during spatial navigation.
%
% Parameters can be specified either as fields of an input structure,
% optional keyword arguments or in the default settings file. Hierarchy for
% what will be used is in that order.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Inputs (required):
% in = string (top directory of npx recording, i.e. date/time stamped
% folder containing experiment 1) or struct which must contain at least a
% field ".dir" which is the top directory of npx recording. This structure
% can also have fields for optional keyword arguments for this recording
% (see below)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Inputs (optional):
% pixelsPerMetre = pixels per metre of the position recording
%
% jumpMax = maximum jump in position between sequential position samples
% (in m/s). This is used to filter our bad position samples (impossibly
% fast movement). These positions will be interpolated over (see
% "postprocess_pos_data_OE.m")
%
% posSampleRate = sample rate for position recording (Hz)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Output:
% npx = structure containing directory, spike, lfp, position and settings
% info that has been loaded. Note this should be processed (processNpx) and
% potentially converted to tetrode format (npx2tet) if easy interfacing
% with the rest of the Barry Lab Universal_Matlab repo is required. See
% documentation of those functions for more info.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% read in optional arguments
[pixelsPerMetre,jumpMax,posSampleRate] = deal([]);
for v = 1:numel(varargin)
    if strcmp(varargin{v},'pixelsPerMetre')
        pixelsPerMetre = varargin{v+1};
    elseif strcmp(varargin{v},'jumpMax')
        jumpMax = varargin{v+1};
    elseif strcmp(varargin{v},'posSampleRate')
        posSampleRate = varargin{v+1};
    end
end

% read input. NB if a structure then 
if ischar(in)
    KsDir           = in;
elseif isstruct(in)
    KsDir           = in.dir;
    pixelsPerMetre  = getOr(in,'pixelsPerMetre');
    jumpMax         = getOr(in,'jumpMax');
    posSampleRate   = getOr(in,'posSampleRate');
end

% read in default settings and compare with optional inputs
settings            = ReadYaml('npxSettings.yml');
if isempty(pixelsPerMetre)
    pixelsPerMetre  = settings.pixelsPerMetre;
end
if isempty(jumpMax)
    jumpMax         = settings.jumpMax;
end
if isempty(posSampleRate)
    posSampleRate   = settings.posSampleRate;
end

% return subdirectory list
subDirs             = genPath(KsDir,{'.phy'});
subDirs             = strsplit(subDirs,pathsep);
    
% find relevant directories
[settingsDir,posDir,syncDir,] ...
                    = deal(false(numel(subDirs),1));
for i = 1:numel(subDirs)
    d               = dir(subDirs{i});
    settingsDir(i)  = any(strcmp({d(:).name},settings.settingsFile));
    posDir(i)       = any(strcmp({d(:).name},settings.posFile));
    syncDir(i)      = any(strcmp({d(:).name},settings.syncFile));
end
settingsDirStr      = subDirs{settingsDir};
posDirStr           = subDirs{posDir};
syncDirStr          = subDirs{syncDir};

% load sync file
if ~isempty(syncDirStr)
    d = dir(syncDirStr);
    syncFile        = [syncDirStr filesep d(contains({d(:).name},settings.syncFile)).name];
    sync            = parseSync(syncFile);
else
    sync            = [];
    spkSync         = [];
    lfpSync         = [];
end

% read in spk lfp probe directories
nSpk                = numel(settings.spkId);
nLfp                = numel(settings.lfpId);
[spkDirStr,lfpDirStr] = deal(cell(nSpk,1));
for s = 1:nSpk
    re              = [settings.spkRe '.' num2str(settings.spkId(s))];
    spkDirStr(s)    = parseDirFile(subDirs,re,settings.spkFile);
    if ~isempty(sync)
        spkSync(s)  = sync([sync(:).subProcessor]==settings.spkId(s));
    end
end
for l = 1:nLfp
    re              = [settings.lfpRe '.' num2str(settings.lfpId(l))];
    lfpDirStr(l)    = parseDirFile(subDirs,re,settings.lfpFile);
    if ~isempty(sync)
        lfpSync(l)  = sync([sync(:).subProcessor]==settings.lfpId(l));
    end
end

% read in OE settings file
npxSettings = [];
if ~isempty(settingsDirStr)
    d               = dir(settingsDirStr);
    settingsFile    = [settingsDirStr filesep d(contains({d(:).name},settings.settingsFile)).name];
    xml             = myXml2struct(settingsFile);
    npxSettings     = parseSettingsXML(xml);
    posFlag         = cellfun(@(x) any(x),cellfun(@(x) contains(x,'Pos Tracker'),{npxSettings.name},'UniformOutput',0));
    spkFlag         = cellfun(@(x) any(x),cellfun(@(x) contains(x,'Neuropix'),{npxSettings.name},'UniformOutput',0));
    fields2convert  = {'BottomBorder' 'LeftBorder' 'RightBorder' 'TopBorder'};
    for f = 1:numel(fields2convert)
        npxSettings(posFlag).parameters{1}.(fields2convert{f}) ...
                    = str2num(npxSettings(posFlag).parameters{1}.(fields2convert{f}));
    end
end

% load in ks/phy data, convert spk t to seconds and align to master clock
if ~isempty(spkDirStr)
    for i = 1:numel(spkDirStr)
        spk(i)      = loadKSdirNpx(spkDirStr{i});
        if ~isempty(spkSync(i))
            spk(i).st = spk(i).st + spkSync(i).startTimeSec;
            %spkSync(i).npxSampleTimes = [0:spkSync(i).sampleDurSec:spk(i).st(end)] + spkSync(i).startTimeSec;
        end
    end
else
    spk = [];
end
for i = 1:numel(spk)
    spk(i).sync     = spkSync(i);
end

% load in LFP data, at sample times in seconds (aligned to master clock)
if ~isempty(lfpDirStr)
    for i = 1:numel(lfpDirStr)
        lfpFile     = [lfpDirStr{i} filesep settings.lfpFile];
        lfp(i).data = loadNpxLfp(lfpFile,settings.nChannels);
        if ~isempty(lfpSync(i))
            nSamples = size(lfp(i).data,2);
            endT    = nSamples * lfpSync(i).sampleDurSec;
            lfp(i).st = [0:lfpSync(i).sampleDurSec:endT]' + lfpSync(i).startTimeSec;
            lfp(i).st = lfp(i).st(1:nSamples);
        end
    end
else
    lfp = [];
end
for i = 1:numel(lfp)
    lfp(i).sync = lfpSync(i);
end

% load pos xy and t files, convert pos t to seconds
if ~isempty(posDirStr)
    d               = dir(posDirStr);
    posFile         = [posDirStr filesep d(contains({d(:).name},settings.posFile)).name];
    posTFile        = [posDirStr filesep d(contains({d(:).name},settings.posTFile)).name];
    pos             = loadPos(posFile,posTFile,posSampleRate);
else
    pos             = [];
end

% save into structure
% directorys
npx.dirs.KsDir                  = KsDir;
npx.dirs.settingsDir            = settingsDirStr;
npx.dirs.syncDir                = syncDirStr;
npx.dirs.spkDir                 = spkDirStr;
npx.dirs.posDir                 = posDirStr;
npx.dirs.syncDir                = syncDirStr;
npx.dirs.lfpDir                 = lfpDirStr;
% files
npx.dirs.settingsFile           = settingsFile;
npx.dirs.syncFile               = syncFile;
npx.dirs.posFile                = posFile;
npx.dirs.posTFile               = posTFile;
npx.dirs.lfpFile                = lfpFile;
% spk recording
npx.spk                         = spk;
% lfp recording
npx.lfp                         = lfp;
% position recording
npx.pos                         = pos;
npx.pos.led_pix                 = []; % unused for now
npx.pos.settings                = npxSettings(posFlag).parameters{1};
npx.pos.settings.pixelsPerMetre = pixelsPerMetre;
npx.pos.settings.jumpMax        = jumpMax;
npx.pos.settings.posSampleRate  = posSampleRate;
npx.pos.device                  = npxSettings(posFlag).devices{1};
% YAML settings
npx.settingsYML                 = settings;

end

%% subfunctions
%     function d = parseDirFile(subDirs,DirRe,fileName)
%         toSearch = subDirs(cellfun(@(x) ~isempty(regexp(x,DirRe,'once')),subDirs'));
%         flag = false(numel(toSearch),1);
%         for j = 1:numel(toSearch)
%             d = dir(toSearch{j});
%             flag(j) = any(strcmp({d(:).name},fileName));
%         end
%         d = toSearch(flag);
%     end




