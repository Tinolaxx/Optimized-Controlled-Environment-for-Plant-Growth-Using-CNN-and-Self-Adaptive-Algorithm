% Define the source folder containing the images and the target label folder
sourceFolder = 'C:\Users\chris\Downloads\Optimized-Controlled-Environment-for-Plant-Growth-Using-CNN-and-Self-Adaptive-Algorithm-main\Optimized-Controlled-Environment-for-Plant-Growth-Using-CNN-and-Self-Adaptive-Algorithm-main\Datasets\Images\S2\WhiteBG';
labelFolder = 'C:\Users\chris\Downloads\Optimized-Controlled-Environment-for-Plant-Growth-Using-CNN-and-Self-Adaptive-Algorithm-main\Optimized-Controlled-Environment-for-Plant-Growth-Using-CNN-and-Self-Adaptive-Algorithm-main\Datasets\Images\S2\labelFolder';

% Create the 'Week2' folder if it does not exist
week2Folder = fullfile(labelFolder, 'Week2');
if ~exist(week2Folder, 'dir')
    mkdir(week2Folder);
end

% Get a list of all image files in the source folder (e.g., .jpg, .png)
imageFiles = dir(fullfile(sourceFolder, '*.jpg')); % Adjust extension if needed
% Or use '*.png' if your images are PNG files, or '*.*' for all files

% Loop through each image and move it to the 'Week2' folder
for i = 1:length(imageFiles)
    % Get the full file path of the image
    sourceFile = fullfile(imageFiles(i).folder, imageFiles(i).name);
    % Define the target file path in the 'Week2' folder
    targetFile = fullfile(week2Folder, imageFiles(i).name);
    
    % Move the image to the 'Week2' folder
    movefile(sourceFile, targetFile);
    
    % Optionally, you can also display a message for each moved file
    disp(['Moved: ', imageFiles(i).name]);
end

% Confirmation message
disp('All images have been labeled as Week 2 and moved.');
