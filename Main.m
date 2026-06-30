%% 初始化环境
close all;clc;clear
%% 调用各步骤

% Step 1: 读取原始图片
disp('========================================');
disp('  [Step 1] 读取图片...');
disp('========================================');
imgOriginal = Step1_ReadImage();
disp('  图片读取完成');
disp(' ');

% Step 2: 图像预处理
disp('========================================');
disp('  [Step 2] 图像预处理...');
disp('========================================');
imgPreprocessed = Step2_Preprocess(imgOriginal);
disp('  预处理完成');
disp(' ');

% Step 3: 车牌定位 + 倾斜校正
disp('========================================');
disp('  [Step 3] 车牌定位...');
disp('========================================');
[imgLocated, imgGrayPlate] = Step3_Locate(imgPreprocessed, imgOriginal);
disp('  车牌定位完成');
disp(' ');

% Step 4: 字符分割
disp('========================================');
disp('  [Step 4] 字符分割...');
disp('========================================');
Step4_Segment(imgLocated);
disp('  字符分割完成');
disp(' ');

% Step 5: 字符识别
disp('========================================');
disp('  [Step 5] 字符识别...');
disp('========================================');
charImgs = cell(1, 7);
for i = 1:7
    charImgs{i} = imread(fullfile('temp_segments', [int2str(i) '.jpg']));
end
plateResult = Step5_Recognize(charImgs);

disp('========================================');
disp('  全部流程完成');
disp('========================================');
