clc; close all;
fprintf('Beginning to run %s.m ...\n', mfilename);

% googlenet
net = googlenet;

% Read the image
RGB = imread('1-7.jpg'); 

% Segment the binary and masked image
[BW, maskedImage] = segmentImage(RGB);

% resize for CNN Input
inputSize = net.Layers(1).InputSize(1:2);
imgForCNN = imresize(repmat(BW, [1, 1, 3]), inputSize);

% feature Extraction using CNN
imgForCNN = repmat(BW, [1, 1, 3]);  % Convert Mask to 3-channel for CNN
imgForCNN = imresize(imgForCNN, inputSize);  % Resize to Fit CNN

features = activations(net, imgForCNN, 'conv1-7x7_s2');  % Extract CNN Features
features = squeeze(features);  % Flatten the features for use in regression

disp('CNN Features extracted:');
disp(features);

leafAreaCm2 = 42.12;
disp(['Leaf Area (cm²): ', num2str(leafAreaCm2)]);

save('leaf_features.mat', 'features', 'leafAreaCm2');

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
[label, num_leaves] = bwlabel(BW);

% Create masked image
maskedImage = RGB;
maskedImage(repmat(~BW,[1 1 3])) = 0;
end

% leaf area
leafAreaPixels = sum(BW(:));
disp(['Total Leaf Area (in Pixels): ', num2str(leafAreaPixels)]);
pixelToCmRatio = 0.026;
leafAreaCm2 = leafAreaPixels * pixelToCmRatio;
disp(['Total Leaf Area (in cm²): ', num2str(leafAreaCm2)]);

% Display the results
figure;
subplot(1, 3, 1), imshow(RGB); title('Original Image');
subplot(1, 3, 2); imshow(BW); title('Binary Mask');
subplot(1, 3, 3), imshow(maskedImage); title('Masked Image');
