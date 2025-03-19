% Define input and output folders
inputFolder = 'C:\Users\chris\Downloads\Optimized-Controlled-Environment-for-Plant-Growth-Using-CNN-and-Self-Adaptive-Algorithm-main\Optimized-Controlled-Environment-for-Plant-Growth-Using-CNN-and-Self-Adaptive-Algorithm-main\Datasets\S2'; % Replace with your input folder path
bwOutputFolder = 'C:\Users\chris\Downloads\Optimized-Controlled-Environment-for-Plant-Growth-Using-CNN-and-Self-Adaptive-Algorithm-main\Optimized-Controlled-Environment-for-Plant-Growth-Using-CNN-and-Self-Adaptive-Algorithm-main\Datasets\Images\S2\BW_uncleaned'; % Binary masks output folder
maskedOutputFolder = 'C:\Users\chris\Downloads\Optimized-Controlled-Environment-for-Plant-Growth-Using-CNN-and-Self-Adaptive-Algorithm-main\Optimized-Controlled-Environment-for-Plant-Growth-Using-CNN-and-Self-Adaptive-Algorithm-main\Datasets\Images\S2\Masked_uncleaned'; % Masked images output folder

% Check if the output folders exist, if not, create them
if ~exist(bwOutputFolder, 'dir')
    mkdir(bwOutputFolder);
end
if ~exist(maskedOutputFolder, 'dir')
    mkdir(maskedOutputFolder);
end

% Get list of all image files in the input folder
imageFiles = dir(fullfile(inputFolder, '*.jpg')); % Modify the extension if needed

% Loop through all the image files
for i = 1:length(imageFiles)
    % Read the image
    RGB = imread(fullfile(inputFolder, imageFiles(i).name)); 

    % Segment the binary and masked image
    [BW, maskedImage] = segmentImage(RGB);

    % Save the results
    [~, fileName, ~] = fileparts(imageFiles(i).name);
    imwrite(BW, fullfile(bwOutputFolder, [fileName, '_BW.png'])); % Save binary mask
    imwrite(maskedImage, fullfile(maskedOutputFolder, [fileName, '_masked.png'])); % Save masked image
end

% Function to segment the image
function [BW, maskedImage] = segmentImage(RGB)

    % Convert RGB image into L*a*b* color space
    X = rgb2lab(RGB);

    % Auto clustering (properly cluster the plant)
    s = rng;
    rng('default');
    L = imsegkmeans(single(X), 2, 'NumAttempts', 2);
    rng(s);
    BW = L == 2;
   % BW = imcomplement(BW);
    % Given parameters
    radius = 1;
    decomposition = 0;
    se = strel('disk', radius, decomposition);

    BW = imdilate(BW, se); % Dilate
    BW = imerode(BW, se); % Erode
    BW = imopen(BW, se); % Open Mask
    BW = imclose(BW, se); % Close Mask

    % Create masked image
    maskedImage = RGB;
    maskedImage(repmat(~BW, [1 1 3])) = 0;
end
