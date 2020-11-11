function [lfp] = loadNpxLfp(lfpFilename,nChansInFile)

d = dir(lfpFilename);
nSamps = d.bytes/2/nChansInFile;
lfp = memmapfile(lfpFilename, 'Format', {'int16', [nChansInFile nSamps], 'x'});
lfp = lfp.Data.x;

end

