% Read the two images
img1 = imread('C:\Users\chris\OneDrive\Desktop\CNNCode\InputImage_WhiteBG\S2\4.png');
img2 = imread('C:\Users\chris\OneDrive\Desktop\CNNCode\InputImage_WhiteBG\S3\4.png');

% Convert to grayscale if images are RGB
if size(img1, 3) == 3
    img1 = rgb2gray(img1);
end
if size(img2, 3) == 3
    img2 = rgb2gray(img2);
end

% Histogram Equalization to improve image uniformity
img1 = histeq(img1);
img2 = histeq(img2);

% Segment both images separately
level1 = graythresh(img1);
binaryImage1 = imbinarize(img1, level1);

level2 = graythresh(img2);
binaryImage2 = imbinarize(img2, level2);

% Remove small objects/noise
cleanedImage1 = bwareaopen(binaryImage1, 80);  
cleanedImage2 = bwareaopen(binaryImage2, 80);

% Morphological operations for refinement
se = strel('disk', 3);
cleanedImage1 = imopen(cleanedImage1, se);
cleanedImage2 = imopen(cleanedImage2, se);

% Compute IoU
intersection = cleanedImage1 & cleanedImage2;  % Common area
union = cleanedImage1 | cleanedImage2;  % Total area

IoU = sum(intersection(:)) / sum(union(:));  % Compute IoU score
fprintf('IoU between Week 4 and Week 5: %.4f\n', IoU);

% Convert masks to RGB for visualization
intersectionRGB = cat(3, zeros(size(intersection)), intersection, zeros(size(intersection))); % Green for intersection
unionRGB = cat(3, union, zeros(size(union)), zeros(size(union))); % Red for union

            % Perform absolute difference
            diffImage = imabsdiff(img1, img2);
            
            % Threshold (adjust if necessary)
            level = graythresh(diffImage);  % This finds the optimal threshold value
            diffImage = imbinarize(diffImage, level);
            
            % Clean up small objects/noise using bwareaopen (removes objects smaller than 500 pixels, adjust as needed)
            cleanedImage3 = bwareaopen(diffImage, 500);  % Adjust size threshold

            % Alternatively, use morphological operations to clean up small dots
            se = strel('disk', 3);  % Create a disk-shaped structuring element (size 3)
            cleanedImage3 = imopen(cleanedImage3, se);  % Opening removes small noise

            % Calculate the area of white regions (changed areas)
             pixelToCmRatio = 0.000055;
            whitePixelCount = bwarea(cleanedImage3); % Count white pixels
            whiteAreaCm2 = whitePixelCount * pixelToCmRatio;
            fprintf('Area of detected changes (white regions): %.2f cm^2\n', whiteAreaCm2);

% Display results
figure;
subplot(3,2,1); imshow(img1); title('Past Image');
subplot(3,2,2); imshow(img2); title('Present Image');
subplot(3,2,3); imshow(diffImage); title('Background subtraction');
subplot(3,2,4); imshow(intersectionRGB + unionRGB); 
title(sprintf('IoU Visualization (IoU = %.4f)', IoU));

% Save result
outputFolder = "C:\Users\chris\OneDrive\Desktop\CNNCode\OneImageOnly";
if ~exist(outputFolder, 'dir')
    mkdir(outputFolder);
end
outputFilePath = fullfile(outputFolder, 'IoU_Visualization_W4_W5.jpg');
imwrite(intersectionRGB + unionRGB, outputFilePath);

fprintf('IoU visualization saved: %s\n', outputFilePath);
