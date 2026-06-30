function imgPreprocessed = Step2_Preprocess(imgOriginal)
    % Step2_Preprocess: 图像预处理（颜色+边缘双重验证）
    %
    % 流程：颜色检测(蓝色) + Canny边缘检测 → 取交集 → 填充 → 过滤
    %
    % 输入：imgOriginal - 原始RGB图片矩阵
    % 输出：imgPreprocessed - 预处理后的二值图像

    imgBlue = detectBlue(imgOriginal);
    imgEdge = detectEdge(imgOriginal);
    imgClosed = imclose(imgEdge, strel('rectangle', [15, 15]));
    imgFilled = imfill(imgClosed, 'holes');
    imgFiltered = bwareaopen(imgFilled, 1000);
    imgCombined = imgFiltered & imgBlue;
    imgFiltered = bwareaopen(imgCombined, 1000);
    imgPreprocessed = imgFiltered;
end

function imgBlue = detectBlue(imgRGB)
    imgHSV = rgb2hsv(imgRGB);
    H = imgHSV(:,:,1);
    S = imgHSV(:,:,2);
    V = imgHSV(:,:,3);
    imgBlue = (H >= 0.50 & H <= 0.80) & (S > 0.15) & (V > 0.15);
    imgBlue = imfill(imgBlue, 'holes');
end

function imgEdge = detectEdge(imgRGB)
    imgGray = rgb2gray(imgRGB);
    imgEdge = edge(imgGray, 'canny', 0.5);
end
