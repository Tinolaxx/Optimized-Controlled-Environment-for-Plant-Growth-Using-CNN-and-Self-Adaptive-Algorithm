% Define paths to your image folders (Week 2 to Week 5)
week2Folder = 'C:\Users\chris\OneDrive\Desktop\CNNCode\InputImage_WhiteBG\S2';
week3Folder = 'C:\Users\chris\OneDrive\Desktop\CNNCode\InputImage_WhiteBG\S3';
week4Folder = 'C:\Users\chris\OneDrive\Desktop\CNNCode\InputImage_WhiteBG\S4';
week5Folder = 'C:\Users\chris\OneDrive\Desktop\CNNCode\InputImage_WhiteBG\S5';
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

% Define input size for ResNet-50
inputSize = [224 224 3];
imds.ReadFcn = @(filename) imresize(imread(filename), inputSize(1:2));

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

% Number of folds for cross-validation
K = 5;
indices = crossvalind('Kfold', imds.Labels, K);
accuracyList = zeros(K,1);

for fold = 1:K
    fprintf('Starting Fold %d/%d...\n', fold, K);
    
    % Create train-validation split for the current fold
    trainIdx = (indices ~= fold);
    valIdx = (indices == fold);
    
    imdsTrain = subset(imds, find(trainIdx));
    imdsVal = subset(imds, find(valIdx));
    
    fprintf('Training images: %d\n', numel(imdsTrain.Files));
    fprintf('Validation images: %d\n', numel(imdsVal.Files));

    % Training options
    options = trainingOptions('sgdm', ...
        'InitialLearnRate', 0.001, ...
        'MaxEpochs', 15, ...
        'MiniBatchSize', 40, ...
        'Shuffle', 'every-epoch', ...
        'ValidationData', imdsVal, ...
        'ValidationFrequency', floor(numel(imdsTrain.Files) / 40), ...
        'ValidationPatience', 5, ...
        'Verbose', true, ...
        'Plots', 'training-progress');

    % Train model
    netTransfer = trainNetwork(imdsTrain, lgraph, options);

    % Evaluate model
    YPred = classify(netTransfer, imdsVal);
    YValidation = imdsVal.Labels;
    foldAccuracy = mean(YPred == YValidation);
    accuracyList(fold) = foldAccuracy;
    fprintf('Fold %d Accuracy: %.2f%%\n', fold, foldAccuracy * 100);
end

% Compute final average accuracy
finalAccuracy = mean(accuracyList);
fprintf('Final 5-Fold Cross-Validation Accuracy: %.2f%%\n', finalAccuracy * 100);

% Save the trained model
save('IoUResNet.mat', 'netTransfer');

% Display confusion matrix
figure;
confusionchart(YValidation, YPred);
title('Confusion Matrix');

fprintf('Processing completed.\n');
