function imgPreprocessed = Step2_Preprocess(imgOriginal)
    % Step2_Preprocess: 图像预处理
    %
    % 流程：灰度化 → 边缘检测 → 形态学腐蚀 → 闭运算填充 → 去除小区域
    %
    % 输入：
    %   imgOriginal - 原始RGB图片矩阵
    %
    % 输出：
    %   imgPreprocessed - 预处理后的二值图像
    %
    % 使用方法：
    %   imgPreprocessed = Step2_Preprocess(imgOriginal);

    % --- Step 2.1: 灰度化 ---
    imgGray = rgb2gray(imgOriginal);

    subplot(3, 2, 2);
    imshow(imgGray);
    title('Step 2.1: 灰度图片');

    % --- Step 2.2: Canny边缘检测 ---
    imgEdge = edge(imgGray, 'canny', 0.5);

    subplot(3, 2, 3);
    imshow(imgEdge);
    title('Step 2.2: Canny边缘检测');

    % --- Step 2.3: 形态学腐蚀 ---
    seErode = [1; 1; 1];
    imgEroded = imerode(imgEdge, seErode);

    subplot(3, 2, 4);
    imshow(imgEroded);
    title('Step 2.3: 腐蚀边缘图片');

    % --- Step 2.4: 闭运算填充 ---
    seClose = strel('rectangle', [25, 25]);
    imgClosed = imclose(imgEroded, seClose);

    subplot(3, 2, 5);
    imshow(imgClosed);
    title('Step 2.4: 闭运算填充');

    % --- Step 2.5: 去除小区域 ---
    imgPreprocessed = bwareaopen(imgClosed, 2000);

    % 显示预处理结果
    figure('Name', 'Step 2: 预处理结果');
    subplot(2, 2, 1);
    imshow(imgPreprocessed);
    title('Step 2: 预处理结果');
end