clear;
saveloc = 'Z:\Dayvihd\spike2_files\BigHold';
if ~exist(saveloc, 'dir')
    error('Save location does not exist!');
end

cedpath = getenv('CEDS64ML'); % Get the CEDS64 environment path
addpath(cedpath); % Add library functions to the path
CEDS64LoadLib(cedpath); % Load libraries

% Filepath setup
filepath = 'Z:\Dayvihd\spike2_files\SingleHold\A471 SCN April 7 (converted).smrx';
if ~exist(filepath, 'file')
    error('SMRX file does not exist!');
end

% Open the file
fhand1 = CEDS64Open(filepath);
if fhand1 < 0
    error('Failed to load SMRX file!');
end

% Metadata
maxChannels1 = CEDS64MaxChan(fhand1); % Get the number of channels
channelsToProcess = 1:maxChannels1; % Adjust based on desired channels
maxTimeTicks1 = CEDS64ChanMaxTime(fhand1, channelsToProcess(1)) + 1; % Max time in ticks
maxTimeSecs1 = CEDS64TicksToSecs(fhand1, maxTimeTicks1); % Convert max tick time to seconds

% Processing parameters
chunkSize = 1e8; % Adjust chunk size (samples per chunk)
timeStep = CEDS64ChanDiv(fhand1, channelsToProcess(1)); % Sampling interval in ticks
chunkTicks = chunkSize * timeStep; % Ticks per chunk

% Loop through each channel
for chanIdx = channelsToProcess
    fprintf('Processing channel %d...\n', chanIdx);
    matfileName = fullfile(saveloc, sprintf('waveform_channel_%d.mat', chanIdx));
    matObj = matfile(matfileName, 'Writable', true);
    matObj.fVals = []; % Preallocate storage for waveform data
    matObj.times = []; % Preallocate storage for timestamps
    
    % Initialize reading parameters
    currentTick = 0;
    allData = []; % Accumulator for data in current channel
    allTimes = []; % Accumulator for time stamps
    
    while currentTick < maxTimeTicks1
        % Define chunk range
        nextTick = min(currentTick + chunkTicks, maxTimeTicks1);
        
        % Read chunk
        [nRead, fVals, startTime] = CEDS64ReadWaveF(fhand1, chanIdx, chunkSize, currentTick, nextTick);
        if nRead <= 0
            fprintf('No more data to read for channel %d. Stopping.\n', chanIdx);
            break;
        end
        
        % Generate timestamps for this chunk
        chunkTimes = double(startTime) + (0:nRead-1)' * double(timeStep);
        
        % Detect gaps and fill with NaN
        if ~isempty(allTimes) && ~isempty(chunkTimes)
            gapSize = chunkTimes(1) - allTimes(end) - timeStep;
            if gapSize > 0
                fprintf('Gap detected in channel %d. Filling with NaN...\n', chanIdx);
                nGapPoints = round(gapSize / timeStep);
                gapTimes = (allTimes(end) + timeStep):timeStep:(chunkTimes(1) - timeStep);
                gapData = NaN(nGapPoints, 1);
                allTimes = [allTimes; gapTimes']; %#ok<AGROW>
                allData = [allData; gapData]; %#ok<AGROW>
            end
        end
        
        % Append current chunk data
        allTimes = [allTimes; chunkTimes]; %#ok<AGROW>
        allData = [allData; fVals]; %#ok<AGROW>
        
        % Write accumulated data to the mat file
        matObj.fVals = [matObj.fVals; allData];
        matObj.times = [matObj.times; allTimes];
        
        % Clear accumulators
        allData = [];
        allTimes = [];
        
        % Update tick
        currentTick = nextTick;
    end
    
    fprintf('Finished processing channel %d. Data saved to %s.\n', chanIdx, matfileName);
end

% Cleanup
CEDS64Close(fhand1);
CEDS64UnloadLib();
fprintf('All channels processed.\n');
