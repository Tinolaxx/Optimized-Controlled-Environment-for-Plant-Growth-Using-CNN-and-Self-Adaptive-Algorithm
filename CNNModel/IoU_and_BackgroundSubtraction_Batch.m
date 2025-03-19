% Define folders
week2Folder = 'C:\Users\chris\OneDrive\Desktop\CNNCode\InputImage_WhiteBG\S2';
week3Folder = 'C:\Users\chris\OneDrive\Desktop\CNNCode\InputImage_WhiteBG\S3';
week4Folder = 'C:\Users\chris\OneDrive\Desktop\CNNCode\InputImage_WhiteBG\S4';
week5Folder = 'C:\Users\chris\OneDrive\Desktop\CNNCode\InputImage_WhiteBG\S5';
weekFolders = {week2Folder, week3Folder, week4Folder, week5Folder};

% Define output folders
outputFolder = 'C:\Users\chris\OneDrive\Desktop\CNNCode\SubtractedImages';
iouImageFolder = 'C:\Users\chris\OneDrive\Desktop\CNNCode\IoU_Images';
csvFolder = 'C:\Users\chris\OneDrive\Desktop\CNNCode\CSV_Results';

% Create directories if they do not exist
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

% Get filenames from the first week's folder (Week2)
imageFiles = dir(fullfile(weekFolders{1}, '*.png'));

% Store results in a cell array for sorting
results = {};  % IoU results
areaResults = {};  % White Area results

% Loop through each image and process
for i = 1:length(imageFiles)
    baseFilename = imageFiles(i).name;

    % Process images from consecutive weeks
    for weekIdx = 1:length(weekFolders) - 1
        weekPrevPath = fullfile(weekFolders{weekIdx}, baseFilename);
        weekNextPath = fullfile(weekFolders{weekIdx + 1}, baseFilename);

        if exist(weekPrevPath, 'file') && exist(weekNextPath, 'file')
            imWeekPrev = imread(weekPrevPath);
            imWeekNext = imread(weekNextPath);

            % Convert to grayscale if necessary
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

fprintf('Processing completed.\n');
fprintf('IoU images saved in: %s\n', iouImageFolder);
fprintf('IoU scores saved in: %s\n', iouCsvFile);
fprintf('White area results saved in: %s\n', areaCsvFile);
fprintf('Subtracted images saved in: %s\n', outputFolder);
