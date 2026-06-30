function [imgLocated, imgGrayPlate] = Step3_Locate(imgPreprocessed, imgOriginal)
    % Step3_Locate: 车牌定位 + 倾斜校正（合并）
    %
    % 流程：粗定位(膨胀+连通域) → Hough倾斜校正 → 精确裁剪
    %
    % 输入：
    %   imgPreprocessed - 预处理后的二值图像（Step2输出）
    %   imgOriginal     - 原始RGB图片矩阵
    %
    % 输出：
    %   imgLocated   - 校正后的车牌二值图
    %   imgGrayPlate - 校正后的车牌灰度图

    disp('  [Step 3] 车牌定位 + 倾斜校正...');

    % --- Step 3.1: 粗定位 - 膨胀后找连通域 ---
    % 膨胀连接断开的区域，便于找到完整车牌
    imgDilated = imdilate(imgPreprocessed, strel('rectangle', [20, 20]));
    cc = bwconncomp(imgDilated);
    stats = regionprops(cc, 'Area', 'BoundingBox');

    if isempty(stats)
        warning('未检测到车牌区域');
        imgLocated = imgPreprocessed;
        imgGrayPlate = rgb2gray(imgOriginal);
        return;
    end

    % 找最大连通域（车牌通常是最大的蓝色区域）
    [~, maxIdx] = max([stats.Area]);
    bbox = stats(maxIdx).BoundingBox;

    % 扩大 bounding box 以包含完整车牌
    [imgH, imgW] = size(imgPreprocessed);
    padX = round(bbox(3) * 0.1);
    padY = round(bbox(4) * 0.3);
    x1 = max(1, round(bbox(1)) - padX);
    y1 = max(1, round(bbox(2)) - padY);
    x2 = min(imgW, round(bbox(1) + bbox(3)) + padX);
    y2 = min(imgH, round(bbox(2) + bbox(4)) + padY);

    % 从原始图像裁剪出粗定位区域
    imgCropRGB = imgOriginal(y1:y2, x1:x2, :);
    imgCropGray = rgb2gray(imgCropRGB);
    imgCropBinary = imgPreprocessed(y1:y2, x1:x2);

    figure('Name', 'Step 3: 车牌定位');
    subplot(2, 2, 1);
    imshow(imgCropRGB);
    title('Step 3.1: 粗定位裁剪');

    % --- Step 3.2: Hough变换检测倾斜角度 ---
    imgEdge = edge(imgCropGray, 'canny');
    [H, theta, rho] = hough(imgEdge);
    peakThreshold = ceil(0.15 * max(H(:)));
    peaks = houghpeaks(H, 20, 'Threshold', peakThreshold);

    [cropH, cropW] = size(imgCropGray);
    minLen = max(10, round(cropW * 0.15));
    lines = houghlines(imgEdge, theta, rho, peaks, ...
        'FillGap', round(cropW * 0.05), 'MinLength', minLen);

    % 如果没检测到直线，降低阈值重试
    if isempty(lines)
        peaks = houghpeaks(H, 30, 'Threshold', ceil(0.08 * max(H(:))));
        lines = houghlines(imgEdge, theta, rho, peaks, ...
            'FillGap', round(cropW * 0.08), 'MinLength', max(8, round(cropW * 0.1)));
    end

    skewAngle = 0;
    if ~isempty(lines)
        % 只保留接近水平的直线
        horizontalLines = lines(abs([lines.theta]) < 45);
        if isempty(horizontalLines)
            horizontalLines = lines;
        end

        angles = zeros(1, length(horizontalLines));
        weights = zeros(1, length(horizontalLines));
        for k = 1:length(horizontalLines)
            angles(k) = horizontalLines(k).theta;
            weights(k) = norm(horizontalLines(k).point1 - horizontalLines(k).point2);
        end

        % 加权中位数角度
        [~, sortIdx] = sort(angles);
        sortedAngles = angles(sortIdx);
        sortedWeights = weights(sortIdx);
        cumWeight = cumsum(sortedWeights);
        medianIdx = find(cumWeight >= cumWeight(end) / 2, 1);
        skewAngle = sortedAngles(medianIdx);
    end

    disp(['    检测到倾斜角度: ' num2str(skewAngle) ' 度']);

    % 角度过大认为不是车牌
    if abs(skewAngle) > 30
        disp('    角度过大，可能非车牌，跳过校正');
        skewAngle = 0;
    end

    % --- Step 3.3: 旋转校正 ---
    if abs(skewAngle) > 0.5
        imgCropBinary = imrotate(imgCropBinary, skewAngle, 'bilinear', 'crop');
        imgCropGray = imrotate(imgCropGray, skewAngle, 'bilinear', 'crop');
        disp(['    已校正 ' num2str(skewAngle) ' 度']);
    else
        disp('    倾斜角度很小，无需校正');
    end

    subplot(2, 2, 2);
    imshow(imgCropGray);
    title('Step 3.2: 倾斜校正后');

    % --- Step 3.4: 精确裁剪 - 去除边框 ---
    % 水平投影找左右边界
    projHorizontal = sum(imgCropBinary, 1);
    projThreshold = max(projHorizontal) * 0.05;

    colLeft = 1;
    while colLeft <= length(projHorizontal) && projHorizontal(colLeft) < projThreshold
        colLeft = colLeft + 1;
    end

    colRight = length(projHorizontal);
    while colRight >= colLeft && projHorizontal(colRight) < projThreshold
        colRight = colRight - 1;
    end

    % 垂直投影找上下边界
    projVertical = sum(imgCropBinary, 2);
    projVThreshold = max(projVertical) * 0.05;

    rowTop = 1;
    while rowTop <= length(projVertical) && projVertical(rowTop) < projVThreshold
        rowTop = rowTop + 1;
    end

    rowBottom = length(projVertical);
    while rowBottom >= rowTop && projVertical(rowBottom) < projVThreshold
        rowBottom = rowBottom - 1;
    end

    % 用二值图的投影坐标裁剪灰度图，再二值化（保留字符信息）
    if colLeft < colRight && rowTop < rowBottom
        imgGrayPlate = imgCropGray(rowTop:rowBottom, colLeft:colRight);
    else
        imgGrayPlate = imgCropGray;
    end

    % Otsu 自适应二值化（字符白、背景黑）
    level = graythresh(imgGrayPlate);
    imgLocated = im2bw(imgGrayPlate, level);

    % 如果字符是黑色背景是白色，取反
    if sum(imgLocated(:)) > numel(imgLocated) / 2
        imgLocated = ~imgLocated;
    end

    subplot(2, 2, 3);
    imshow(imgLocated);
    title('Step 3.3: 精确裁剪（二值）');

    subplot(2, 2, 4);
    imshow(imgGrayPlate);
    title('Step 3.4: 精确裁剪（灰度）');
end
