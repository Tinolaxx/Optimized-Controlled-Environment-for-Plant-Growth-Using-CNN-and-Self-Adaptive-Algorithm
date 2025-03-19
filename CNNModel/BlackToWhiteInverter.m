clc; clear; close all;

% Define input and output folders
inputFolder = 'C:\Users\chris\Downloads\Optimized-Controlled-Environment-for-Plant-Growth-Using-CNN-and-Self-Adaptive-Algorithm-main\Optimized-Controlled-Environment-for-Plant-Growth-Using-CNN-and-Self-Adaptive-Algorithm-main\Datasets\Images\S5\Week 5 masked';  % Change this to your input folder path
outputFolder = 'C:\Users\chris\Downloads\Optimized-Controlled-Environment-for-Plant-Growth-Using-CNN-and-Self-Adaptive-Algorithm-main\Optimized-Controlled-Environment-for-Plant-Growth-Using-CNN-and-Self-Adaptive-Algorithm-main\Datasets\Images\S5\Week 5 masked'; % Change this to your output folder path

% Create output folder if it does not exist
if ~exist(outputFolder, 'dir')
    mkdir(outputFolder);
end

% Get all image files in the folder
imageFiles = dir(fullfile(inputFolder, '*.png')); % Change to '*.jpg' or other formats if needed

% Process each image
for i = 1:length(imageFiles)
    % Read image
    imgPath = fullfile(inputFolder, imageFiles(i).name);
    img = imread(imgPath);
    
    % Convert to double for processing (0-255 range)
    imgDouble = im2double(img);
    
    % Define a threshold to detect black pixels (adjust if necessary)
    blackThreshold = 0.05; % Pixels where all RGB values are <= this threshold
    
    % Create a mask for black pixels
    blackMask = all(imgDouble <= blackThreshold, 3);
    
    % Check if the image is grayscale or RGB
    if size(imgDouble, 3) == 3  % RGB image
        % Apply mask to all channels for RGB image
        imgDouble(:,:,1) = imgDouble(:,:,1) + blackMask; % Red channel
        imgDouble(:,:,2) = imgDouble(:,:,2) + blackMask; % Green channel
        imgDouble(:,:,3) = imgDouble(:,:,3) + blackMask; % Blue channel
    else  % Grayscale image
        % Apply mask to grayscale image (single channel)
        imgDouble = imgDouble + blackMask;
    end
    
    % Convert back to uint8 (0-255 range)
    outputImg = im2uint8(imgDouble);
    
    % Save the processed image
    outputFileName = fullfile(outputFolder, imageFiles(i).name);
    imwrite(outputImg, outputFileName);
    
    fprintf('Processed: %s\n', imageFiles(i).name);
end

disp('All images processed successfully.');
