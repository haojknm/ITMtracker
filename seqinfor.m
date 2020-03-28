function seq = seqinfor(sequence)

seq.name = sequence;
sequence_path = ['E:\Project\tracking\∫ÏÕ‚\staple-master\sequences\',sequence,'\']
seq.path = [sequence_path 'imgs2\'];

%% Read files
text_files = dir([sequence_path 'frames.txt']);
f = fopen([sequence_path text_files(1).name]);
frames = textscan(f, '%f,%f');
seq.startFrame = frames{1};
seq.endFrame = frames{2};
fclose(f);

seq.nz = 4;
seq.ext = 'bmp';

load([sequence_path sequence '.mat']);
gtdata(:,1) = gtdata(:,1) - gtdata(:,3)/2 +1;
gtdata(:,2) = gtdata(:,2) - gtdata(:,4)/2 +1;

seq.rect_anno = gtdata(seq.startFrame:seq.endFrame,:);
seq.init_rect = seq.rect_anno(1,:); 
seq.len = seq.endFrame - seq.startFrame + 1;
seq.s_frames = cell(seq.len,1);

dir_content = dir(seq.path);
% skip '.' and '..' from the count
n_imgs = length(dir_content) - 2;
img_files = cell(n_imgs, 1);
for ii = 1:n_imgs
    img_files{ii} = dir_content(ii+2).name;
end
img_files(seq.endFrame+1:end)=[];   
img_files(1: seq.startFrame-1)=[];

for ii = 1:length(img_files)
    seq.s_frames{ii} = [seq.path img_files{1}];
end