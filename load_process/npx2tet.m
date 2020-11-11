function [npx] = npx2tet(npx)
% creates axona/tetrode-like fields for npx recordings to interface with
% CB lab spatial analysis repo

% make fake axona header
if isfield(npx.pos,'settings')
    npx.pos.header = {'pixels_per_metre' num2str(npx.pos.settings.pixelsPerMetre) ; ...
                      'sample_rate' num2str(npx.pos.settings.posSampleRate) ;
                      'window_max_x' num2str(npx.pos.settings.RightBorder) ; ...
                      'window_min_x' num2str(npx.pos.settings.LeftBorder) ; ...
                      'window_max_y' num2str(npx.pos.settings.BottomBorder) ; ...
                      'window_min_y' num2str(npx.pos.settings.TopBorder)};
end

% justify pos data to min xy edge
if isfield(npx.pos,'settings') && isfield(npx.pos.settings,'RightBorder') && isfield(npx.pos.settings,'BottomBorder')
    min_x = min([npx.pos.settings.LeftBorder npx.pos.settings.RightBorder]);
    min_y = min([npx.pos.settings.TopBorder npx.pos.settings.BottomBorder]);
    npx.pos.xy = npx.pos.xy - [min_x min_y];
end
 
% make fake tetrode structure
for i = 1:numel(npx.spk)
    npx.tetrode(i).clusterIDs = npx.spk(i).clu;       % cluster id for each spike
    npx.tetrode(i).pos_sample = npx.spk(i).spkPos;    % spatial position for each spike
end

end

