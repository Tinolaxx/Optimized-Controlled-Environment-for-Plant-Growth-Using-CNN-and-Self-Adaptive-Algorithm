fprintf('Beginning to run %s.m ...\n', mfilename);

% Load ResNet-50 (instead of GoogLeNet)
net = resnet50;

imageFolder = 'C:\Users\chris\OneDrive\Documents\matlab-cnn\lettucedataset\Images\trainingvalidation'; 
labelFile = 'C:\Users\chris\OneDrive\Documents\matlab-cnn\lettucedataset\Labels\leaf_area_labels.csv';

% Load the labels (filename, leafarea, classlabel)
opts = detectImportOptions(labelFile);
labelsTable = readtable(labelFile, opts);

% Store features and leaf area
features = [];
leafAreas = [];

% Loop over each image and extract features
for i = 1:height(labelsTable)
    % Get the filename and leaf area of the labels
    filename = labelsTable.Filename{i};
    leafArea = labelsTable.LeafArea(i);

    % Read images in training/validation dataset
    RGB = imread(fullfile(imageFolder, filename));

    % Call function from below to proceed with image processing
    [BW, maskedImage] = segmentImage(RGB);
    
    % Extract features 
    inputSize = net.Layers(1).InputSize(1:2); % Input size of ResNet-50 (224, 224 image size)
    imgForCNN = imresize(repmat(BW, [1, 1, 3]), inputSize); % Resize and convert to 3-channel
    cnnFeatures = activations(net, imgForCNN, 'res5c_branch2c'); % Extract features from ResNet-50 (last convolution block)
    
    % Flatten the features
    cnnFeatures = squeeze(cnnFeatures); 
    
    % Store the extracted features and corresponding leaf area
    features = [features; cnnFeatures(:)'];  % Flatten features and store
    leafAreas = [leafAreas; leafArea];  % Use the leaf area directly from the labels
end

% Split the dataset into training (80%) and validation (20%) 
cv = cvpartition(length(leafAreas), 'HoldOut', 0.2);
trainIdx = cv.training; % Indexes for training set
valIdx = cv.test; % Indexes for validation set

% Training data
trainFeatures = features(trainIdx, :);
trainLeafAreas = leafAreas(trainIdx);

% Validation data
valFeatures = features(valIdx, :);
valLeafAreas = leafAreas(valIdx);

% Train the regression model using the training set
regModel = fitrsvm(trainFeatures, trainLeafAreas, 'Standardize', true, 'KernelFunction', 'gaussian');

% Validate the model using the validation set
predictedLeafArea = predict(regModel, valFeatures);

% Calculate evaluation metrics

mse = mean((predictedLeafArea - valLeafAreas).^2);  % Mean squared error
mae = mean(abs(predictedLeafArea - valLeafAreas));  % Mean absolute error
rmse = sqrt(mse);  % Root mean squared error

% R² (coefficient of determination)
ssTotal = sum((valLeafAreas - mean(valLeafAreas)).^2);  % Total sum of squares
ssResidual = sum((valLeafAreas - predictedLeafArea).^2);  % Residual sum of squares
rSquared = 1 - (ssResidual / ssTotal);  % R-squared

% Display the evaluation metrics
disp(['Validation Metrics:']);
disp(['Mean Squared Error (MSE): ', num2str(mse)]);
disp(['Mean Absolute Error (MAE): ', num2str(mae)]);
disp(['Root Mean Squared Error (RMSE): ', num2str(rmse)]);
disp(['R² (R-Squared): ', num2str(rSquared)]);

% Calculate leaf area from binary mask (BW)
function leafArea = calculateLeafArea(BW)
    % Calculate leaf area in pixels and convert to cm²
    leafAreaPixels = sum(BW(:));
    pixelToCmRatio = 0.026;  
    leafArea = leafAreaPixels * pixelToCmRatio;  % Leaf area in cm²
end

function [BW, maskedImage] = segmentImage(RGB)
    X = rgb2lab(RGB);

    % Auto clustering using k-means (separate plant from the background)
    s = rng;
    rng('default');
    L = imsegkmeans(single(X), 2, 'NumAttempts', 2); % k-means segmentation with 2 clusters
    rng(s);
    
    % Binary mask for the plant region (assuming the plant is the second cluster)
    BW = L == 2;

    % Morphological operations to clean the binary mask
    radius = 1;
    decomposition = 0;
    se = strel('disk', radius, decomposition);
    BW = imdilate(BW, se);  % Dilate
    BW = imerode(BW, se);   % Erode
    BW = imopen(BW, se);    % Open Mask
    BW = imclose(BW, se);   % Close Mask
    BW = imfill(BW, 'holes');  % Fill holes in the mask

    % Create the masked image (RGB with the plant area highlighted)
    maskedImage = RGB;
    maskedImage(repmat(~BW, [1, 1, 3])) = 0;
end
