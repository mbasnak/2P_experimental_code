function [smoothed] = singleTrialVelocityAnalysis9mm(data, sampleRate)
% This function processes the raw position data obtained from FicTrac to
% give back the velocity in degrees.

% It takes the rawData (data) and the sample rate (sampleRate) as inputs
% and gives back a struct names "smoothed" with the 3 final velocities for
% x, y and angular velocity.  


%% Tranform signal from voltage to radians for unwrapping

    dataRad.Intx = data.Intx .* 2 .* pi ./ 10; %10 is for the max voltage outputed by the daq
    dataRad.Inty = data.Inty .* 2 .* pi ./ 10;
    dataRad.angularPosition = data.angularPosition .* 2 .* pi ./ 10;
    

% Now the position is going between 0 and 2 pi.

%% Unwrapping 

    unwrapped.Intx = unwrap(dataRad.Intx);
    unwrapped.Inty = unwrap(dataRad.Inty);
    unwrapped.angularPosition = unwrap(dataRad.angularPosition);

% Now the position is unwrapped, so it doesn't jump when moving from 0 to
% 2pi and vice versa


%% Downsample the position data to match FicTrac's output


    % Downsample to match FicTrac's output
    downsampled.Intx = resample_new(unwrapped.Intx,25,sampleRate); %For a 1000 rate acquisition frame rate from the NiDaq, downsampling to 25 Hz equals taking 1 every 40 frames
    downsampled.Inty = resample_new(unwrapped.Inty,25,sampleRate); %For a 1000 rate acquisition frame rate from the NiDaq, downsampling to 25 Hz equals taking 1 every 40 frames  
    downsampled.angularPosition = resample_new(unwrapped.angularPosition,25,sampleRate);
    
        
% The output is downsampled. It isn't noticeable when plotting solid lines, and
% it is barely noticeable when plotting dotted lines.
%% Smooth the data

    smoothed.Intx = smoothdata(downsampled.Intx,'rlowess',25); 
    smoothed.Inty = smoothdata(downsampled.Inty,'rlowess',25); 
    smoothed.angularPosition = smoothdata(downsampled.angularPosition,'rlowess',25);
    
     
%% Transform to useful systems 
    
    deg.Intx = smoothed.Intx * 4.5; % wer tranform the pos to mm by scaling the value by the sphere's radius
    deg.Inty = smoothed.Inty * 4.5;
    deg.angularPosition = (smoothed.angularPosition / (2*pi)) * 360; % we transform the angular position to degrees
    %subtract the initial angle from the set up (the positon 1 is actually
    %3 pixels to the right of the fly)
    initialPx = 3; %my x=1 positon is 3 pixels to the right of the animal
    initialAngle = initialPx*360/96;
    %shift according to the panels pos
    shifted_data = deg.angularPosition - initialAngle;
    %wrap
    deg.angularPosition = wrapTo360(shifted_data);
    smoothed.degAngularPosition = deg.angularPosition;
     smoothed.angularPosition = deg2rad(deg.angularPosition);
    
    %add position for x and y in degrees to later compute total movement
    deg.IntxDeg = rad2deg(smoothed.Intx);
    deg.IntyDeg = rad2deg(smoothed.Inty);    
    
%% Take the derivative

    diff.Intx = gradient(deg.Intx).* 25; %we multiply by 25 because we have downsampled to 25 Hz
    diff.Inty = gradient(deg.Inty).* 25; 
    diff.angularPosition = gradient(deg.angularPosition).* 25;
    
    %%add the x and y in deg/s
    diff.IntxDeg = gradient(deg.IntxDeg).* 25; %we multiply by 25 because we have downsampled to 25 Hz
    diff.IntyDeg = gradient(deg.IntyDeg).* 25;

%% Calculate the distribution and take away values that are below 2.5% and above 97.5%
    
    percentile25AV = prctile(diff.angularPosition,2.5);
    percentile975AV = prctile(diff.angularPosition,97.5);
    boundedDiffAngularPos = diff.angularPosition;
    boundedDiffAngularPos(diff.angularPosition<percentile25AV | diff.angularPosition>percentile975AV) = NaN;
    
    percentile25FV = prctile(diff.Intx,2.5);
    percentile975FV = prctile(diff.Intx,97.5);
    boundedDiffIntx = diff.Intx;
    boundedDiffIntx(boundedDiffIntx<percentile25FV | boundedDiffIntx>percentile975FV) = NaN;
    
    percentile25SV = prctile(diff.Inty,2.5);
    percentile975SV = prctile(diff.Inty,97.5);
    boundedDiffInty = diff.Inty;
    boundedDiffInty(boundedDiffInty<percentile25SV | boundedDiffInty>percentile975SV) = NaN;
    
    %add the deg/s components
    percentile25FVDeg = prctile(diff.IntxDeg,2.5);
    percentile975FVDeg = prctile(diff.IntxDeg,97.5);
    boundedDiffIntxDeg = diff.IntxDeg;
    boundedDiffIntxDeg(boundedDiffIntxDeg<percentile25FVDeg | boundedDiffIntxDeg>percentile975FVDeg) = NaN;
    
    percentile25SVDeg = prctile(diff.IntyDeg,2.5);
    percentile975SVDeg = prctile(diff.IntyDeg,97.5);
    boundedDiffIntyDeg = diff.IntyDeg;
    boundedDiffIntyDeg(boundedDiffIntyDeg<percentile25SVDeg | boundedDiffIntyDeg>percentile975SVDeg) = NaN;

 %% Linearly interpolate to replace the NaNs with values.
 
    [pointsVectorAV] = find(~isnan(boundedDiffAngularPos));
    valuesVectorAV = boundedDiffAngularPos(pointsVectorAV);
    xiAV = 1:length(boundedDiffAngularPos);
    interpAngVel = interp1(pointsVectorAV,valuesVectorAV,xiAV);
    
    [pointsVectorFV] = find(~isnan(boundedDiffIntx));
    valuesVectorFV = boundedDiffIntx(pointsVectorFV);
    xiFV = 1:length(boundedDiffIntx);
    interpxVel = interp1(pointsVectorFV,valuesVectorFV,xiFV);
    
    [pointsVectorSV] = find(~isnan(boundedDiffInty));
    valuesVectorSV = boundedDiffInty(pointsVectorSV);
    xiSV = 1:length(boundedDiffInty);
    interpyVel = interp1(pointsVectorSV,valuesVectorSV,xiSV);
    
    [pointsVectorFVDeg] = find(~isnan(boundedDiffIntxDeg));
    valuesVectorFVDeg = boundedDiffIntxDeg(pointsVectorFVDeg);
    xiFVDeg = 1:length(boundedDiffIntxDeg);
    interpxVelDeg = interp1(pointsVectorFVDeg,valuesVectorFVDeg,xiFVDeg);
    
    [pointsVectorSVDeg] = find(~isnan(boundedDiffIntyDeg));
    valuesVectorSVDeg = boundedDiffIntyDeg(pointsVectorSVDeg);
    xiSVDeg = 1:length(boundedDiffIntyDeg);
    interpyVelDeg = interp1(pointsVectorSVDeg,valuesVectorSVDeg,xiSVDeg);
       
 %%  Smooth again
 
    smoothed.xVel = smoothdata(interpxVel,'rlowess',15);
    smoothed.yVel = smoothdata(interpyVel,'rlowess',15);
    smoothed.angularVel = smoothdata(interpAngVel,'rlowess',15);
    % add the deg/s components
    smoothed.xVelDeg = smoothdata(interpxVelDeg,'rlowess',15);
    smoothed.yVelDeg = smoothdata(interpyVelDeg,'rlowess',15);
    %add total movement
    smoothed.total_mvt = abs(smoothed.angularVel)+abs(smoothed.xVelDeg)+abs(smoothed.yVelDeg);


end