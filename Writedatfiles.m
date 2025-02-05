%edit test.dat
%save A1925187aug2.dat
%% Manual Section: You have to make a variable called waveforms...
%cd('/analysis/Dayvihd/spike2_files/BigHold') on balrog
cd('BigHold/')
a = dir('*.mat');

% This is hardcoded in to avoid unneeded channels. It's smoothbrain as
% fuck, but for now, it should work okay.
k = 1;
for i = 1:length(a)
    if a(i).bytes > 2*10^9 && a(i).bytes < 3.8*10^9 % if the filesize is larger than around 5kb
    waveformStructs{k} = load(a(i).name); 
    k = k + 1;
    end
end

for i = 1:length(waveformStructs)
    waveforms{i} = waveformStructs{1,i}.waveform{2,1};
end

datname = 'A533 test.dat';
if ~exist(datname,'file')
    save(datname)
end

%fileID = fopen('test.dat','w+'); %remember that 'a' is for appending writing, and 'w' is for overwriting... if that makes sense...
icleID = fopen(datname,'w');



%fwrite(icleID,[1:40000],"int16") %I think this works

if ~exist("waveforms","var")
    error('dude... Like... What the fuck are you doing?');
end

whatWeTrynaConvert = makeaBigStringfromChannelsNamSayin(waveforms(1,:));

fwrite(icleID,whatWeTrynaConvert,'int16');

%fclose(fileID)
fclose(icleID)


%% Okay, so I'm imagining that you will feed this function a cell of channels  
% of data... It then basically riffles the cells to make a gigantic ass dat
% file thing... (Use waveforms(2,:))
function [riffles] = makeaBigStringfromChannelsNamSayin(cellChan)
    for i = 1:length(cellChan)
        haha(:,i) = cellChan{1,i};
    end
    lengthoriffles = size(haha,1);
    riffles = zeros(1,lengthoriffles*size(haha,2));
    for i = 1:size(haha,1)
        for j = 1:size(haha,2)
            riffles(i*size(haha,2)+j) = haha(i,j);
        end
    end
end