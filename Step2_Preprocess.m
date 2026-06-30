function imgPreprocessed = Step2_Preprocess(imgOriginal)
    % Step2_Preprocess: 图像预处理（颜色+边缘双重验证）
    %
    % 流程：颜色检测(蓝色) + Canny边缘检测 → 取交集 → 填充 → 过滤
    %
    % 输入：
    %   imgOriginal - 原始RGB图片矩阵
    %
    % 输出：
    %   imgPreprocessed - 预处理后的二值图像
    %
    % 使用方法：
    %   imgPreprocessed = Step2_Preprocess(imgOriginal);

    % --- Step 2.1: 颜色检测 ---
    imgBlue = detectBlue(imgOriginal);

    subplot(2, 2, 1);
    imshow(imgBlue);
    title('Step 2.1: HSV颜色检测');

    % --- Step 2.2: Canny边缘检测 ---
    imgEdge = detectEdge(imgOriginal);

    subplot(2, 2, 2);
    imshow(imgEdge);
    title('Step 2.2: Canny边缘检测');

    % --- Step 2.3: 对Canny边缘做闭运算 + 填充 ---
    imgClosed = imclose(imgEdge, strel('rectangle', [15, 15]));
    imgFilled = imfill(imgClosed, 'holes');
    imgFiltered = bwareaopen(imgFilled, 1000);

    subplot(2, 2, 3);
    imshow(imgFiltered);
    title('Step 2.3: Canny闭运算+填充');

    % --- Step 2.4: 与HSV蓝色检测取交集 ---
    imgCombined = imgFiltered & imgBlue;
    imgFiltered = bwareaopen(imgCombined, 1000);

    subplot(2, 2, 4);
    imshow(imgFiltered);
    title('Step 2.4: Canny填充 ∩ HSV蓝色');

    % 直接将交集作为预处理结果（形状过滤留给后续步骤）
    imgPreprocessed = imgFiltered;
end

%% ==================== 局部函数 ====================

function imgBlue = detectBlue(imgRGB)
    % detectBlue: 基于 HSV 颜色空间检测蓝色区域
    % 输入：imgRGB - RGB图像
    % 输出：imgBlue - 二值图，白色=蓝色区域
    imgHSV = rgb2hsv(imgRGB);
    H = imgHSV(:,:,1);
    S = imgHSV(:,:,2);
    V = imgHSV(:,:,3);
    imgBlue = (H >= 0.50 & H <= 0.80) & (S > 0.15) & (V > 0.15);
    imgBlue = imfill(imgBlue, 'holes');
end

function imgEdge = detectEdge(imgRGB)
    % detectEdge: Canny 边缘检测
    % 输入：imgRGB - RGB图像
    % 输出：imgEdge - 二值图，白色=边缘点
    imgGray = rgb2gray(imgRGB);
    imgEdge = edge(imgGray, 'canny', 0.5);
end