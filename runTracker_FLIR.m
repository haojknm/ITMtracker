function runTracker_FLIR(sequence, start_frame, end_frame)
% RUN_TRACKER  is the external function of the tracker - does initialization and calls trackerMain

    addpath('.\rstEval\')
    %% Read params.txt
    params = readParams('params.txt');    
        
	%% load video info
	sequence_path = ['./sequences/',sequence,'/'];
    img_path = [sequence_path 'imgs2/'];
    %% Read files
    text_files = dir([sequence_path 'frames.txt']);
    f = fopen([sequence_path text_files(1).name]);
    frames = textscan(f, '%f,%f');
    if exist('start_frame')
        frames{1} = start_frame;
    else
        start_frame = frames{1};
    end    
    if exist('end_frame')
        frames{2} = end_frame;
    else
        end_frame = frames{2};
    end    
    fclose(f);
    
    %     params.bb_VOT = csvread([sequence_path 'groundtruth.txt']);
    load([sequence_path sequence '.mat']);
    gtdata(:,1) = gtdata(:,1) - gtdata(:,3)/2 +1;
    gtdata(:,2) = gtdata(:,2) - gtdata(:,4)/2 +1;
    params.bb_VOT = gtdata;
    clear gtdata;
    region = params.bb_VOT(frames{1},:);

    %%%%%%%%%%%%%%%%%%%%%%%%%
    % read all the frames in the 'imgs' subfolder
    dir_content = dir([sequence_path 'imgs2/']);
    % skip '.' and '..' from the count
    n_imgs = length(dir_content) - 2;
    img_files = cell(n_imgs, 1);
    for ii = 1:n_imgs
        img_files{ii} = dir_content(ii+2).name;
    end
    
    img_ref = imread([img_path img_files{start_frame-1}]);
    img_files(end_frame+1:end)=[];   
    img_files(1:start_frame-1)=[];

    im = imread([img_path img_files{1}]);
    %%%%%%%%%%%%%%%%%%%%%%%%%%% 
    opticFlow = opticalFlowHS; %opticalFlowLKDoG('NumFrames',3);
    flow = estimateFlow(opticFlow,img_ref);
    im = combfeat(im, opticFlow);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % is a grayscale sequence ?
    if(size(im,3)==1)
        params.grayscale_sequence = true;
    end

    params.img_files = img_files;
    params.img_path = img_path;

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if(numel(region)==8)
        % polygon format
        [cx, cy, w, h] = getAxisAlignedBB(region);
    else
        x = region(1);
        y = region(2);
        w = region(3);
        h = region(4);
        cx = x+w/2;
        cy = y+h/2;
    end

    % init_pos is the centre of the initial bounding box
    params.init_pos = [cy cx];
    params.target_sz = round([h w]);
    [params, bg_area, fg_area, area_resize_factor] = initializeAllAreas(im, params);
	if params.visualization
		params.videoPlayer = vision.VideoPlayer('Position', [100 100 [size(im,2), size(im,1)]+30]);
	end
    % in runTracker we do not output anything
	params.fout = -1;
	% start the actual tracking
	results = trackerMain(params, im, bg_area, fg_area, area_resize_factor, opticFlow);
%     results = trackerMain2(params, im, bg_area, fg_area, area_resize_factor, opticFlow);

    
    anno =  params.bb_VOT(start_frame:end_frame,:);   
    [perf.aveCoverage, perf.aveErrCenter, perf.errCoverage, perf.errCenter] = calcSeqErrRobust(results, anno);
    
    fclose('all');
    mean(perf.errCenter)
%     save(['.\rlt\' sequence '_rlt_comb3_0.2.mat'],'results','perf') ;

end