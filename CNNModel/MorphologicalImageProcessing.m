% Read the image
RGB = imread('P40-3.jpg'); 

% Segment the binary and masked image
[BW, maskedImage] = segmentImage(RGB);

% Display the binary mask and masked image side by side
function [BW,maskedImage] = segmentImage(RGB)

% Convert RGB image into L*a*b* color space
X = rgb2lab(RGB);

% Auto clustering (properly cluster the plant)
s = rng;
rng('default');
L = imsegkmeans(single(X),2,'NumAttempts',2);
rng(s);
BW = L == 2;

% Given parameters
radius = 1;
decomposition = 0;
se = strel('disk', radius, decomposition);

BW = imdilate(BW, se); % Dilate
BW = imerode(BW, se); % Erode
BW = imopen(BW, se); % Open Mask
BW = imclose(BW, se); % Close Mask
BW = imfill(BW, 'holes'); % Fill holes

% Create masked image
maskedImage = RGB;
maskedImage(repmat(~BW,[1 1 3])) = 0;

% Display the results
figure;
subplot(1, 2, 1); imshow(BW); title('Binary Mask');
subplot(1, 2, 2); imshow(maskedImage); title('Masked Image');
end
