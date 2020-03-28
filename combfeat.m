function feature = combfeat(im, opticFlow)

feature = zeros( size(im,1), size(im,2), 3 );
feature = uint8(feature);
%% intensity
if(size(im,3)>1)
    im = rgb2gray(im);    
end
feature(:,:,1) = im;

%% texture
% image = double(im) / 255;
% feature(:,:,2)  = SILTP(image, 0.3, 5, 4);
feature(2:end-1,2:end-1,2) = lbp(im);

%% context
flow = estimateFlow(opticFlow,im);
% temp = mapminmax(flow.Orientation, 0, 1);
temp = mapminmax(flow.Magnitude, 0, 1);
% temp = flow.Magnitude/max(max(flow.Magnitude));
feature(:,:,3) = uint8(temp*255);


% se = strel('disk',7);
% feature(:,:,3) = imtophat(im,se);
% temp = mapminmax(double(temp), 0, 1);
% feature(:,:,3) = uint8(temp*255);


% feature = feature(:,:,1);
r=2;
% feature(r+1:end-r,r+1:end-r,1) = lbp(im,r,8,0,'i');
r=3;
% feature(r+1:end-r,r+1:end-r,3) = lbp(im,r,8,0,'i');