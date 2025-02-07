clear;
saveloc = 'Z:\BigHold';
if ~exist(saveloc,'dir')
    disp('saveloc doesn''t exist')
    error('who raised you?')
end

if isempty(getenv('CEDS64ML'))
    setenv('CEDS64ML', 'C:\CEDMATLAB\CEDS64ML');
end
cedpath = getenv('CEDS64ML'); %grabs the CEDS64 environment
addpath(cedpath); %adds the library functions to the path
CEDS64LoadLib(cedpath); % Loads in libraries... I think...

% Checking if this file is legit
%filepath = 'Z:\Dayvihd\spike2 files\400 untemplated.smrx';
% A1916400, mei 23X- fixed.smrx was already converted
basePath = 'Y:\Dayvihd\spike2_files\SingleHold\';
smrxName = 'A471 SCN April 7 (converted)';
filepath = [basePath, smrxName, '.smrx'];
if ~exist(filepath,'file') 
    error('This shit doesnt exist, homie');
end


% Opens up the file
fhand1 = CEDS64Open([filepath]);
if fhand1 < 0 
    disp('couldnt load in the goddamn smrx or smr file')
    error('fuck');
end

% Let's load in some metadata now, yeah?
maxChannels1 = CEDS64MaxChan(fhand1); %Get the number of channels this file supports
channelswelookinat = 1:maxChannels1;
maxTimeTicks1 = CEDS64ChanMaxTime(fhand1, channelswelookinat(1) )+1; %gets max time in ticks (assumes that all channels are same rec length)
maxTimeSecs1 = CEDS64TicksToSecs(fhand1,maxTimeTicks1); %Converts max tick time to seconds
maxChannels1 = CEDS64MaxChan(fhand1); %Get the number of channels this file supports
[~, startTime1] = CEDS64TimeDate(fhand1); % Gets the time the recording starts

%Now let's load in actual waveforms
cd(saveloc)
if ~exist(saveloc,'dir')
    disp('saveloc doesn''t exist')
    error('who raised you?')
end

datFileNames = cell(length(channelswelookinat), 1);
datNumChans = zeros(length(channelswelookinat), 1);

%Now let's load in actual waveforms
cd(saveloc)
for i = 1:length(channelswelookinat)
    [iRead, fVals, i64Time] = CEDS64ReadWaveF( fhand1, i, maxTimeTicks1, 0, maxTimeTicks1 );
    fVals = fVals * 10.^6;
    
    %save dat file for this channel
    datFileName = fullfile(saveloc, ['waveform', chardex(i), '_', num2str(i), '.dat']);
    fileID = fopen(datFileName, 'w');
    fwrite(fileID, fVals, 'int16');
    fclose(fileID);

    %save dat path and # of channels
    datFileNames{i} = datFileName;
    datNumChans(i) = 1;
end

mergeFileName = fullfile(saveloc, [smrxName, '.dat']);
MergeDats(datFileNames, mergeFileName, datNumChans);


% This is a function that ensures that with alphabetizing, all the channels
% will retain their positions
function [charizard] = chardex(integer)
    if integer <= 26
        charizard = char('a' + integer - 1);
    else 
        charizard = ['z',chardex(integer-26)];
    end
end

