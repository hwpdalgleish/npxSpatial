function [xy, dir, speed, times, jumpyPercent, n_leds, dir_disp] = postprocess_pos_data_OE(posdata,box_car,varargin)

% Perform postprocessing on position data
%
% [xy, dir, speed] = postprocess_pos_data(posdata, max_speed, box_car, setfile_header);
%
% posdata is in format of global tint{x}.pos, ie .led_pos(1:n_pos, 1:n_leds, 2),
%                                                .led_pix(1:n_pos, 1:n_leds)
%                                                .header
%
% Returns
% xy - position (in pixels - ij format),
% dir - direction in degrees anticlock wisefrom x axis,
% speed - in cm/s (using pixels_per_metre and position_sample_rate in posfile header).
% times - in s, vector of time of each pos sample starts with e.g. [1/50, 2/50, ...] 
% jumpyPercent - %of pos points that were excluded because of too high speed
% n_leds - number of LEDs used during recording
% dir_disp - direction (degs anti-clock from x-axis) derived from heading. In case of
%           n_leds == 1 then dir_disp==di

% read in settings and replace with any optional inputs
pix_per_metre = posdata.settings.pixelsPerMetre;
max_speed = posdata.settings.jumpMax;
pos_sample_rate = posdata.settings.posSampleRate;
for v = 1:numel(varargin)
    if strcmp(varargin{v},'pixelsPerMetre') || strcmp(varargin{v},'pix_per_metre')
        pix_per_metre = varargin{v+1};
    elseif strcmp(varargin{v},'maxSpeed') || strcmp(varargin{v},'max_speed')
        max_speed = varargin{v+1};
    elseif strcmp(varargin{v},'posSampleRate') || strcmp(varargin{v},'pos_sample_rate')
        pos_sample_rate = varargin{v+1};
    end
end

% convert npxOE --> axona format
led_pos(:,1,:) = double(posdata.xy);
led_pix = posdata.led_pix;

n_pos = size(led_pos,1); % Don't use led_pix because this is absent from the older format
n_leds = size(led_pos,2);
%Need following if statement as there are some instances in which led_pos apparently codes
%for 2 LEDS (actually 1 plus nans) but led_pix codes correctly for 1 led (i.e. size of
%led_pix is [nPts x 1]. There also appear to be situations in which the opposite
%is true i.e. led_pos correctly codes for a single led but led_pix apparently codes for
%two the second always have nPix 0.

% AJ: I've commented the following if statement that Caswell added as per his
% comments above. I believe this problem arises in read_pos_file.m and I've
% corrected it there. If you subsequently find an error, you might try
% these lines again.

% if isfield(posdata, 'led_pix')
%     n_leds=min( size(led_pix,2), size(led_pos,2));
% end
% AJ - 14/07/2010: I've added this line to be used later in order to do a
% weighted mean of the front and back LEDs. This is because some trials
% have one very badly tracked LED and this completely throws off xy, dir
% and speed data. Weights are the number of tracked positions on each LED.
weights = sum(~isnan(led_pos(:,:,1)))/length(led_pos);

% For 2 spot tracking, check for instances of swapping (often happens if one LED bright, one less bright).
if n_leds == 2 && not(isempty(led_pix)) % Only check if we actually have led_pix
    swap_list = led_swap_filter(led_pos, led_pix);
    dum = led_pos(swap_list, 1, :);
    led_pos(swap_list, 1, :) = led_pos(swap_list, 2, :);
    led_pos(swap_list, 2, :) = dum;
    dum = led_pix(swap_list, 1);
    led_pix(swap_list, 1) = led_pix(swap_list, 2);
    led_pix(swap_list, 2) = dum;
end

% Filter points for those moving impossibly fast and set led_pos_x to NaN
max_pix_per_sample = max_speed*pix_per_metre/pos_sample_rate;
for led = 1: n_leds
    [n_jumpy, led_pos] = led_speed_filter( led_pos, max_pix_per_sample, led);
    jumpyPercent = (n_jumpy/length(led_pos))*100;
    if( n_jumpy > n_pos/3 )
        warning(sprintf(' %d/%d positions rejected for led %d\n', n_jumpy, n_pos, led));
    end
end

% remove datapoints outside of allowable area
fl = false(size(led_pos,1),1);
for i = 1:size(led_pos,2)
    if isfield(posdata.settings,'TopBorder')
        fl = fl & led_pos(:,i,2) <= posdata.settings.TopBorder;
    end
    if isfield(posdata.settings,'BottomBorder')
        fl = fl & led_pos(:,i,2) >= posdata.settings.BottomBorder;
    end
    if isfield(posdata.settings,'LeftBorder')
        fl = fl & led_pos(:,i,1) <= posdata.settings.LeftBorder;
    end
    if isfield(posdata.settings,'RightBorder')
        fl = fl & led_pos(:,i,1) >= posdata.settings.RightBorder;
    end
    led_pos(fl,i,2) = nan;
end
% Interpolate to replace all NaN led positions
% 1/12/09 AJ: I've made changes to the following lines to make the pos.xy
% output more robust. interp1 ignores NaNs at the endpoints of a vector. So
% two lines have been added to take care of these. missing_pos is formed to
% reject poses where the system has failed to record either x OR y
% coordinate and ok_pos requires both x AND y coords to be present.
for led = 1:n_leds
        missing_pos = find(isnan(led_pos(:, led, 1)) | isnan(led_pos(:, led, 2)));
        ok_pos = find(~isnan(led_pos(:, led, 1)) & ~isnan(led_pos(:, led, 2)));
    for k = 1:2
        led_pos(missing_pos, led, k) = interp1(ok_pos, led_pos(ok_pos, led, k), missing_pos, 'linear');
        led_pos(missing_pos(missing_pos>max(ok_pos)), led, k) = led_pos(max(ok_pos), led, k);
        led_pos(missing_pos(missing_pos<min(ok_pos)), led, k) = led_pos(min(ok_pos), led, k);
    end
end

% Estimate position, direction and speed from led_pos, using smoothing
if( box_car > 0 )
    b = ones(ceil(box_car*pos_sample_rate), 1)./ceil(box_car*pos_sample_rate);
else
    b = 1;
end

% Need to know angles (and distances) of LEDs from rat (in bearing_colour_i in .pos header)
pos = 1:n_pos;
pos2 = 1:n_pos-1;
xy = ones(n_pos, 2)*NaN;
if n_leds == 1
    xy(pos, :) = led_pos(pos, 1, :);
    xy = imfilter(xy, b, 'replicate');
    % y from tracker increases downwards. dir is positive anticlockwise from X axis, 0<= dir <360
    %CB verified calc of dir in next line is correct & concords with tint
    dir(pos2) = mod((180/pi)*(atan2( -xy(pos2+1, 2)+xy(pos2, 2), xy(pos2+1, 1)-xy(pos2, 1) )), 360);
    dir(n_pos) = dir(n_pos-1);
    dir_disp=dir; %Return dir_disp for completness even though == dir
elseif n_leds == 2
    % 2 LEDs are assumed to be at 180deg to each other with their midpoint over the
    % animals head. Convention is that colbearings_set(1) is the large light (normally
    % at front) and (2) is the small light. Position of lights (defined in set
    % file header) is defined in degs with 0 being straight ahead of animal, values
    % increase anti-clockwise.
    colbearings_set = NaN*zeros(2,1);
    for i =1:2
        colbearings_set(i) = key_value(sprintf('lightBearing_%d',i), setfile_header, 'num'); %get led bearings from set file
    end
    
    % Smooth lights individually, then get direction. % TW, 12/09/08: This method replicates TINT.
    smLightFront(pos, :) = imfilter(led_pos(pos, 1, :), b, 'replicate');
    smLightBack(pos, :) = imfilter(led_pos(pos, 2, :), b, 'replicate');
    
    correction = colbearings_set(1); %To correct for light pos relative to rat subtract angle of large light
    dir = mod((180/pi)*( atan2(-smLightFront(pos,2)+smLightBack(pos,2), +smLightFront(pos,1)-smLightBack(pos,1)) ) - correction, 360);
    dir = dir(:);
    % Get position from smoothed individual lights %  % TW, 12/09/08
    xy(pos, :) = (weights(1)*smLightFront(pos, :) + weights(2)*smLightBack(pos, :))./sum(weights);  %% TODO: Allow for head positions other than 0.5.
    
    %Get heading from displacement too
    dir_disp(pos2) = mod((180/pi)*(atan2( -xy(pos2+1, 2)+xy(pos2, 2), xy(pos2+1, 1)-xy(pos2, 1) )), 360);
    dir_disp(n_pos) = dir_disp(n_pos-1);
    dir_disp=dir_disp(:);
end

%% Calculate speed, based on distance(sampleN+1-sampleN) %%
speed(pos2) = sqrt((xy(pos2+1,1)-xy(pos2,1)).^2+(xy(pos2+1,2)-xy(pos2,2)).^2);
speed(n_pos) = speed(n_pos-1);
speed = speed.*(100*pos_sample_rate/pix_per_metre);
speed = speed(:);

times = (1:n_pos)/pos_sample_rate;
times = times(:);