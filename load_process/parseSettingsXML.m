function [settings] = parseSettingsXML(xml)
%UNTITLED6 Summary of this function goes here
%   Detailed explanation goes here


nChain = numel(xml.SETTINGS.SIGNALCHAIN);
settings = struct;
for a = 1:nChain
    nProc = numel(xml.SETTINGS.SIGNALCHAIN{a}.PROCESSOR);
    for b = 1:nProc
        if iscell(xml.SETTINGS.SIGNALCHAIN{a}.PROCESSOR)
            tmp = xml.SETTINGS.SIGNALCHAIN{a}.PROCESSOR{b};
        else
            tmp = xml.SETTINGS.SIGNALCHAIN{a}.PROCESSOR;
        end
        try
            settings(a).name{b} = tmp.Attributes.pluginName;
        catch
            settings(a).name{b} = [];
        end
        try
            settings(a).parameters{b} = tmp.Parameters.Attributes;
        catch
            settings(a).parameters{b} = [];
        end
        try
            settings(a).devices{b} = tmp.Devices.Attributes;
        catch
            settings(a).devices{b} = [];
        end
    end
end

end

