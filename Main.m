%% ========================================================================
%  车牌识别主程序 (License Plate Recognition Main Program)
%  ========================================================================

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

% Step 3: 车牌定位
disp('========================================');
disp('  [Step 3] 车牌定位...');
disp('========================================');
imgLocated = Step3_Locate(imgPreprocessed, imgOriginal);
disp('  车牌定位完成');
disp(' ');

% Step 4: 字符分割
disp('========================================');
disp('  [Step 4] 字符分割...');
disp('========================================');
charCount = Step4_Segment(imgLocated);
disp(' ');

% Step 4 校验
if charCount ~= 7
    disp('========================================');
    disp(['  警告：切割数量为 ' num2str(charCount) '，不是7个字符']);
    disp('  识别结果可能不准确');
    disp('========================================');
end

% Step 5: 字符识别
disp('========================================');
disp('  [Step 5] 字符识别...');
disp('========================================');
% 读取分割后的字符图片
charImgs = cell(1, 7);
for i = 1:7
    imgPath = fullfile('temp_segments', [int2str(i) '.jpg']);
    if exist(imgPath, 'file')
        charImgs{i} = imread(imgPath);
    else
        disp(['  警告：找不到 ' imgPath]);
        charImgs{i} = zeros(40, 20);  % 创建空白图片占位
    end
end
plateResult = Step5_Recognize(charImgs);
disp(' ');
disp('========================================');
disp('  所有步骤完成！');
disp('========================================');
disp(['  最终识别结果: ' plateResult]);
disp('========================================');
