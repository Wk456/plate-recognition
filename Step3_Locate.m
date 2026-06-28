function imgLocated = Step3_Locate(imgPreprocessed, imgOriginal)
    % Step3_Locate: 车牌定位
    %
    % 方法：垂直投影定位行边界 + 水平投影定位列边界
    %
    % 输入：
    %   imgPreprocessed - 预处理后的二值图像
    %   imgOriginal     - 原始RGB图片矩阵
    %
    % 输出：
    %   imgLocated - 精确定位后的车牌二值图
    %
    % 使用方法：
    %   imgLocated = Step3_Locate(imgPreprocessed, imgOriginal);

    % 获取图像尺寸
    [imgHeight, imgWidth] = size(imgPreprocessed);
    imgDouble = double(imgPreprocessed);

    % --- Step 3.1: 垂直投影 ---
    projVertical = zeros(imgHeight, 1);

    for row = 1:imgHeight
        for col = 1:imgWidth
            if(imgPreprocessed(row, col) == 1)
                projVertical(row, 1) = projVertical(row, 1) + 1;
            end
        end
    end

    % 找到白色像素最多的行（车牌中心行）
    [~, maxRowIdx] = max(projVertical);

    % 绘制垂直投影图
    subplot(2, 2, 2);
    plot(0:imgHeight-1, projVertical);
    title('Step 3.1: 垂直投影');
    xlabel('行号 (Row)');
    ylabel('白色像素数 (White Pixels)');

    % 从中心行向上下扩展，确定车牌上下边界
    rowTop = maxRowIdx;
    while ((projVertical(rowTop, 1) >= 50) && (rowTop > 1))
        rowTop = rowTop - 1;
    end

    rowBottom = maxRowIdx;
    while ((projVertical(rowBottom, 1) >= 50) && (rowBottom < imgHeight))
        rowBottom = rowBottom + 1;
    end

    % --- Step 3.2: 水平投影 ---
    projHorizontal = zeros(1, imgWidth);

    for col = 1:imgWidth
        for row = rowTop:rowBottom
            if(imgDouble(row, col) == 1)
                projHorizontal(1, col) = projHorizontal(1, col) + 1;
            end
        end
    end

    % 绘制水平投影图
    subplot(2, 2, 4);
    plot(0:imgWidth-1, projHorizontal);
    title('Step 3.2: 水平投影');
    xlabel('列号 (Column)');
    ylabel('白色像素数 (White Pixels)');

    % 找到左右边界
    colLeft = 1;
    while ((projHorizontal(1, colLeft) < 3) && (colLeft < imgWidth))
        colLeft = colLeft + 1;
    end

    colRight = imgWidth;
    while ((projHorizontal(1, colRight) < 3) && (colRight > colLeft))
        colRight = colRight - 1;
    end

    % 裁剪出粗定位的车牌区域
    imgCoarseLocated = imgOriginal(rowTop:rowBottom, colLeft:colRight, :);

    subplot(2, 2, 3);
    imshow(imgCoarseLocated);
    title('Step 3: 粗定位结果');

    % --- Step 3.3: 精确定位 - 二值化 ---
    imgCoarseGray = rgb2gray(imgCoarseLocated);
    grayMax = double(max(max(imgCoarseGray)));
    grayMin = double(min(min(imgCoarseGray)));
    threshold = round(grayMax - (grayMax - grayMin) / 3);
    imgCoarseBinary = im2bw(imgCoarseGray, threshold / 256);

    figure('Name', 'Step 3: 精确定位');
    subplot(2, 2, 1);
    imshow(imgCoarseBinary);
    title('Step 3.3: 二值化图片');

    % 对二值图进行水平投影，用于去除边框
    [heightCoarse, widthCoarse] = size(imgCoarseBinary);
    imgForBorder = double(imgCoarseBinary);
    projForBorder = zeros(1, widthCoarse);

    for col = 1:widthCoarse
        for row = 1:heightCoarse
            if(imgForBorder(row, col) == 1)
                projForBorder(1, col) = projForBorder(1, col) + 1;
            end
        end
    end

    subplot(2, 2, 2);
    plot(0:widthCoarse-1, projForBorder);
    title('Step 3.3: 水平投影');
    xlabel('列号 (Column)');
    ylabel('白色像素数 (White Pixels)');

    % --- Step 3.4: 去除左边框 ---
    leftBorderWidth = 0;
    borderThreshold = 5;

    while sum(imgForBorder(:, leftBorderWidth + 1)) ~= 0
        leftBorderWidth = leftBorderWidth + 1;
    end

    if leftBorderWidth < borderThreshold
        imgForBorder(:, 1:leftBorderWidth) = 0;
        imgForBorder = QieGe(imgForBorder);
    end

    subplot(2, 2, 3);
    imshow(imgForBorder);
    title('Step 3.4: 去除左边框');

    % --- Step 3.5: 去除右边框 ---
    [~, widthCurrent] = size(imgForBorder);
    rightBorderWidth = 0;
    colIdx = widthCurrent;

    while sum(imgForBorder(:, colIdx - 1)) ~= 0
        rightBorderWidth = rightBorderWidth + 1;
        colIdx = colIdx - 1;
    end

    if rightBorderWidth < borderThreshold
        imgForBorder(:, (widthCurrent - rightBorderWidth):widthCurrent) = 0;
        imgForBorder = QieGe(imgForBorder);
    end

    % 显示精确定位结果
    imgLocated = imgForBorder;
    subplot(2, 2, 4);
    imshow(imgLocated);
    title('Step 3.5: 精确定位结果');
end

%% ========================================================================
%  局部函数：QieGe - 图像裁剪（去除空白边框）
%  ========================================================================
function e = QieGe(sbw)
    [m, n] = size(sbw);
    top = 1; bottom = m; left = 1; right = n;

    while sum(sbw(top, :)) == 0 && top <= m
        top = top + 1;
    end
    while sum(sbw(bottom, :)) == 0 && bottom >= 1
        bottom = bottom - 1;
    end
    while sum(sbw(:, left)) == 0 && left <= n
        left = left + 1;
    end
    while sum(sbw(:, right)) == 0 && right >= 1
        right = right - 1;
    end

    dd = right - left;
    hh = bottom - top;
    e = imcrop(sbw, [left, top, dd, hh]);
end
