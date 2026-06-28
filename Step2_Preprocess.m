function imgPreprocessed = Step2_Preprocess(imgOriginal)
    % Step2_Preprocess: 图像预处理（自适应阈值）
    %
    % 流程：灰度化 → 自适应Canny边缘检测 → 形态学腐蚀 → 闭运算填充 → 去除小区域
    %
    % 输入：
    %   imgOriginal - 原始RGB图片矩阵
    %
    % 输出：
    %   imgPreprocessed - 预处理后的二值图像

    % --- Step 2.1: 灰度化 ---
    imgGray = rgb2gray(imgOriginal);

    subplot(3, 2, 2);
    imshow(imgGray);
    title('Step 2.1: 灰度图片');

    % --- Step 2.2: 自适应Canny边缘检测 ---
    % 使用双阈值自动计算，比单阈值0.5更稳定
    imgEdge = edge(imgGray, 'canny', [0.1 0.25]);

    subplot(3, 2, 3);
    imshow(imgEdge);
    title('Step 2.2: Canny边缘检测');

    % --- Step 2.3: 形态学腐蚀（自适应结构元素） ---
    [imgH, imgW] = size(imgGray);
    erodeHeight = max(3, round(imgH / 100));  % 高度的1/100，至少3
    seErode = ones(erodeHeight, 1);
    imgEroded = imerode(imgEdge, seErode);

    subplot(3, 2, 4);
    imshow(imgEroded);
    title('Step 2.3: 腐蚀边缘图片');

    % --- Step 2.4: 闭运算填充（自适应结构元素） ---
    closeW = max(5, round(imgW / 15));   % 宽度的1/15
    closeH = max(5, round(imgH / 8));    % 高度的1/8
    seClose = strel('rectangle', [closeH, closeW]);
    imgClosed = imclose(imgEroded, seClose);

    subplot(3, 2, 5);
    imshow(imgClosed);
    title('Step 2.4: 闭运算填充');

    % --- Step 2.5: 去除小区域（自适应阈值） ---
    minArea = round(imgH * imgW * 0.001);  % 图像面积的0.1%
    imgPreprocessed = bwareaopen(imgClosed, minArea);

    % 显示预处理结果
    figure('Name', 'Step 2: 预处理结果');
    subplot(2, 2, 1);
    imshow(imgPreprocessed);
    title('Step 2: 预处理结果');
end
