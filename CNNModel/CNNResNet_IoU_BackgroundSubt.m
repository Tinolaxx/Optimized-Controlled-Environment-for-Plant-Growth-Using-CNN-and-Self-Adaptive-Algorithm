% Define paths to your image folders (Week 2 to Week 5)
week2Folder = 'C:\Users\chris\OneDrive\Documents\centered\S2';
week3Folder = 'C:\Users\chris\OneDrive\Documents\centered\S3';
week4Folder = 'C:\Users\chris\OneDrive\Documents\centered\S4';
week5Folder = 'C:\Users\chris\OneDrive\Documents\centered\S5';
weekFolders = {week2Folder, week3Folder, week4Folder, week5Folder};
predictedClassResults = {};

% Load images from each week folder
imds2 = imageDatastore(week2Folder, 'LabelSource', 'foldernames');
imds3 = imageDatastore(week3Folder, 'LabelSource', 'foldernames');
imds4 = imageDatastore(week4Folder, 'LabelSource', 'foldernames');
imds5 = imageDatastore(week5Folder, 'LabelSource', 'foldernames');

% Combine the image datastores
imds = imageDatastore([imds2.Files; imds3.Files; imds4.Files; imds5.Files], 'LabelSource', 'foldernames');

% Shuffle the data
imds = shuffle(imds);
totalImages = numel(imds.Files);
fprintf('Total images in dataset: %d\n', totalImages);

% Split dataset into training and validation (80% train, 20% validation)
[imdsTrain, imdsVal] = splitEachLabel(imds, 0.8, 'randomized');
fprintf('Training images: %d\n', numel(imdsTrain.Files));
fprintf('Validation images: %d\n', numel(imdsVal.Files));

% Resize images to ResNet-50 input size
inputSize = [224 224 3];
imdsTrain.ReadFcn = @(filename) imresize(imread(filename), inputSize(1:2));
imdsVal.ReadFcn = @(filename) imresize(imread(filename), inputSize(1:2));

% Load ResNet-50
net = resnet50;
lgraph = layerGraph(net);

% Modify layers for classification
numClasses = 4;  % Four weeks (Week 2 to Week 5)
newFcLayer = fullyConnectedLayer(numClasses, 'WeightLearnRateFactor', 10, 'BiasLearnRateFactor', 10, 'Name', 'new_fc');
newClassLayer = classificationLayer('Name', 'new_class');

% Replace final layers
lgraph = replaceLayer(lgraph, 'fc1000', newFcLayer);
lgraph = replaceLayer(lgraph, 'ClassificationLayer_fc1000', newClassLayer);

% Define training options
options = trainingOptions('sgdm', ...
    'InitialLearnRate', 0.001, ...
    'MaxEpochs', 15, ...
    'MiniBatchSize', 40, ...
    'Shuffle', 'every-epoch', ...
    'ValidationData', imdsVal, ...
    'ValidationFrequency', floor(numel(imdsTrain.Files) / 40), ...
    'ValidationPatience', 5, ...
    'Verbose', true, ...
    'Plots', 'training-progress', ...
    'OutputFcn', @(info) plotAccuracy(info));

% Train the model
netTransfer = trainNetwork(imdsTrain, lgraph, options);
save('IoUResNet.mat', 'netTransfer');

% Function to plot training and validation accuracy
function plotAccuracy(info)
    persistent trainAcc valAcc
    if info.State == "start"
        trainAcc = [];
        valAcc = [];
    end
    if info.State == "iteration"
        trainAcc = [trainAcc, info.TrainingLoss];
        valAcc = [valAcc, info.ValidationLoss];
    end
    if info.State == "done"
        figure;
        plot(1:length(trainAcc), trainAcc, '-o', 'DisplayName', 'Train Accuracy');
        hold on;
        plot(1:length(valAcc), valAcc, '-x', 'DisplayName', 'Validation Accuracy');
        xlabel('Epoch');
        ylabel('Accuracy');
        legend;
        title('Training and Validation Accuracy');
        grid on;
    end
end

% Evaluate the model
YPred = classify(netTransfer, imdsVal);
YValidation = imdsVal.Labels;
accuracy = mean(YPred == YValidation);
fprintf('Validation Accuracy: %.2f%%\n', accuracy * 100);

% Display confusion matrix
figure;
confusionchart(YValidation, YPred);
title('Confusion Matrix');

% ---------------- Background Subtraction ----------------
% Define output folder for subtracted images
outputFolder = 'C:\Users\chris\OneDrive\Documents\SubtractedImages';
iouImageFolder = 'C:\Users\chris\OneDrive\Documents\IoU_Images';
csvFolder = 'C:\Users\chris\OneDrive\Documents\CSV_Results';

if ~exist(outputFolder, 'dir')
    mkdir(outputFolder);
end
if ~exist(iouImageFolder, 'dir')
    mkdir(iouImageFolder);
end
if ~exist(csvFolder, 'dir')
    mkdir(csvFolder);
end

% Prepare CSV files
iouCsvFile = fullfile(csvFolder, 'IoU_Results.csv');
areaCsvFile = fullfile(csvFolder, 'WhiteArea_Results.csv');

% Get filenames from the first week's folder
imageFiles = dir(fullfile(weekFolders{1}, '*.png')); % Change extension if needed

% Store results in a cell array for sorting
results = {};  % IoU results
areaResults = {};  % White Area results

% Loop through each image and match filenames across weeks
for i = 1:length(imageFiles)
    baseFilename = imageFiles(i).name;

    % Subtract images from consecutive weeks
    for weekIdx = 1:length(weekFolders) - 1
        weekPrevPath = fullfile(weekFolders{weekIdx}, baseFilename);
        weekNextPath = fullfile(weekFolders{weekIdx + 1}, baseFilename);
        
        if exist(weekPrevPath, 'file') && exist(weekNextPath, 'file')
            imWeekPrev = imread(weekPrevPath);
            imWeekNext = imread(weekNextPath);
            
            % Convert to grayscale
            if size(imWeekPrev, 3) == 3
                imWeekPrev = rgb2gray(imWeekPrev);
            end
            if size(imWeekNext, 3) == 3
                imWeekNext = rgb2gray(imWeekNext);
            end

            % Histogram Equalization
            imWeekPrev = histeq(imWeekPrev);
            imWeekNext = histeq(imWeekNext);

            % Segment both images separately
            level1 = graythresh(imWeekPrev);
            binaryImage1 = imbinarize(imWeekPrev, level1);

            level2 = graythresh(imWeekNext);
            binaryImage2 = imbinarize(imWeekNext, level2);

            % Remove small objects
            cleanedImage1 = bwareaopen(binaryImage1, 80);
            cleanedImage2 = bwareaopen(binaryImage2, 80);

            % Morphological operations
            se = strel('disk', 3);
            cleanedImage1 = imopen(cleanedImage1, se);
            cleanedImage2 = imopen(cleanedImage2, se);

            % Classify the growth stage using CNN
            imageResized = imresize(imread(fullfile(weekFolders{weekIdx}, baseFilename)), [224 224]);
            predictedClass = classify(netTransfer, imageResized);

            % Store the predicted class
            imageLabel = sprintf('Week%d_and_Week%d_%s', weekIdx + 1, weekIdx + 2, baseFilename);
            predictedClassResults{end+1, 1} = imageLabel;
            predictedClassResults{end, 2} = char(predictedClass);

            % Compute IoU
            intersection = cleanedImage1 & cleanedImage2;
            union = cleanedImage1 | cleanedImage2;
            IoU = sum(intersection(:)) / sum(union(:));

            % Create IoU visualization
            intersectionRGB = cat(3, zeros(size(intersection)), intersection, zeros(size(intersection))); % Green for intersection
            unionRGB = cat(3, union, zeros(size(union)), zeros(size(union))); % Red for union
            iouVisualization = intersectionRGB + unionRGB;

            % Save IoU image
            iouImageFilename = sprintf('IoU_Week%d_Week%d_%s', weekIdx + 1, weekIdx + 2, baseFilename);
            iouImagePath = fullfile(iouImageFolder, iouImageFilename);
            imwrite(iouVisualization, iouImagePath);

            % Background subtraction
            diffImage = imabsdiff(imWeekPrev, imWeekNext);
            level = graythresh(diffImage);
            diffImage = imbinarize(diffImage, level);

            % Clean small noise
            cleanedImage3 = bwareaopen(diffImage, 500);
            cleanedImage3 = imopen(cleanedImage3, se);

            % Compute white area in cm²
            pixelToCmRatio = 0.000055;
            whitePixelCount = bwarea(cleanedImage3);
            whiteAreaCm2 = whitePixelCount * pixelToCmRatio;

            % Store results in the array (Replacing Week1 with Week2)
            imageLabel = sprintf('Week%d_and_Week%d_%s', weekIdx + 1, weekIdx + 2, baseFilename);
            results{end+1, 1} = imageLabel;
            results{end, 2} = IoU;
            areaResults{end+1, 1} = imageLabel;
            areaResults{end, 2} = whiteAreaCm2;

            % Save background subtracted image
            outputFilename = sprintf('Subtracted_Week%d_Week%d_%s', weekIdx + 1, weekIdx + 2, baseFilename);
            outputFilePath = fullfile(outputFolder, outputFilename);
            imwrite(cleanedImage3, outputFilePath);
        end
    end
end

% Sort results by image label
[~, sortedIdx] = sort(results(:, 1));
sortedResults = results(sortedIdx, :);
sortedAreaResults = areaResults(sortedIdx, :);

% Write sorted IoU results
iouFile = fopen(iouCsvFile, 'w');
fprintf(iouFile, 'Image Label,IoU Score\n');
for i = 1:size(sortedResults, 1)
    fprintf(iouFile, '%s,%.4f\n', sortedResults{i, 1}, sortedResults{i, 2});
end
fclose(iouFile);

% Write sorted White Area results
areaFile = fopen(areaCsvFile, 'w');
fprintf(areaFile, 'Image Label,White Area\n');
for i = 1:size(sortedAreaResults, 1)
    fprintf(areaFile, '%s,%.2f\n', sortedAreaResults{i, 1}, sortedAreaResults{i, 2});
end
fclose(areaFile);

predictedClassCsvFile = fullfile(csvFolder, 'PredictedClasses.csv');
predictedClassFile = fopen(predictedClassCsvFile, 'w');
fprintf(predictedClassFile, 'Image Label,Predicted Class\n');
for i = 1:size(predictedClassResults, 1)
    fprintf(predictedClassFile, '%s,%s\n', predictedClassResults{i, 1}, predictedClassResults{i, 2});
end
fclose(predictedClassFile);


fprintf('Processing completed.\n');
fprintf('IoU images saved in: %s\n', iouImageFolder);
fprintf('IoU scores saved in: %s\n', iouCsvFile);
fprintf('White area results saved in: %s\n', areaCsvFile);
fprintf('Subtracted images saved in: %s\n', outputFolder);
