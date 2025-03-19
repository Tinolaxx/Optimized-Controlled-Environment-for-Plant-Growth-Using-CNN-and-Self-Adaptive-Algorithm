clc; close all; clear;

% Define dataset paths
datasetPath = "C:\Users\chris\Downloads\Optimized-Controlled-Environment-for-Plant-Growth-Using-CNN-and-Self-Adaptive-Algorithm-main\Optimized-Controlled-Environment-for-Plant-Growth-Using-CNN-and-Self-Adaptive-Algorithm-main\Datasets\S3"; % Update this path
outputPath = "C:\Users\chris\Downloads\Optimized-Controlled-Environment-for-Plant-Growth-Using-CNN-and-Self-Adaptive-Algorithm-main\Optimized-Controlled-Environment-for-Plant-Growth-Using-CNN-and-Self-Adaptive-Algorithm-main\Datasets\S3Labeling"; % Folder for labeled images
if ~exist(outputPath, 'dir')
    mkdir(outputPath);
end

imds = imageDatastore(datasetPath, 'IncludeSubfolders', false);

% Define pixel-to-cm² ratio (you may need to calibrate this)
pixelToCmRatio = 0.026;  

% Create table to store filenames and estimated areas
numImages = numel(imds.Files);
leafAreas = zeros(numImages, 1);
fileNames = strings(numImages, 1);
classLabels = strings(numImages, 1); % Stores the class labels

% Define leaf size categories
smallThreshold = 10;   % Small: < 10 cm²
mediumThreshold = 30;  % Medium: 10 cm² ≤ x < 30 cm²
largeThreshold = 30;   % Large: ≥ 30 cm²

for i = 1:numImages
    % Read image
    RGB = imread(imds.Files{i});
    
    % Segment the binary mask using L*a*b* color space and k-means clustering
    [BW, maskedImage] = segmentImage(RGB);
    
    % Compute leaf area
    leafAreaPixels = sum(BW(:));
    leafAreaCm2 = leafAreaPixels * pixelToCmRatio;
    
    % Determine class label
    if leafAreaCm2 < smallThreshold
        classLabel = "Small";
    elseif leafAreaCm2 < largeThreshold
        classLabel = "Medium";
    else
        classLabel = "Large";
    end
    
    % Create label folder if it doesn't exist
    labelFolder = fullfile(outputPath, classLabel);
    if ~exist(labelFolder, 'dir')
        mkdir(labelFolder);
    end

    % Move image to labeled folder
    [~, filename, ext] = fileparts(imds.Files{i});
    fileNames(i) = strcat(filename, ext);
    leafAreas(i) = leafAreaCm2;
    classLabels(i) = classLabel;

    % Copy image to labeled folder
    destFile = fullfile(labelFolder, strcat(filename, ext));
    copyfile(imds.Files{i}, destFile);

    disp(['Processed: ', fileNames(i), ' | Leaf Area: ', num2str(leafAreaCm2), ' cm² | Class: ', classLabel]);
end

% Save estimated labels to CSV
labelsTable = table(fileNames, leafAreas, classLabels, 'VariableNames', {'Filename', 'LeafArea', 'ClassLabel'});
csvFilePath = fullfile(outputPath, "leaf_area_labels.csv");
writetable(labelsTable, csvFilePath);

disp("Labels saved successfully at: " + csvFilePath);
disp("Labeled dataset prepared successfully!");

% ----------- Function for Image Segmentation -----------
function [BW, maskedImage] = segmentImage(RGB)

    % Convert RGB image into L*a*b* color space
    X = rgb2lab(RGB);

    % Auto clustering (properly cluster the plant)
    s = rng;
    rng('default');
    L = imsegkmeans(single(X), 2, 'NumAttempts', 2);
    rng(s);
    BW = L == 2;

    % Morphological processing
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
    maskedImage(repmat(~BW, [1 1 3])) = 0;
end
