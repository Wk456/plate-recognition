function Step4_Segment(imgLocated)
    % Step4_Segment: 字符分割
    %
    % 方法：水平投影分割法
    % 中国车牌格式：[省份汉字][字母][5个数字/字母]
    %
    % 输入：
    %   imgLocated - 精确定位后的车牌二值图
    %
    % 输出：
    %   temp_segments/1.jpg ~ 7.jpg（7个分割后的字符图片）

    % 创建临时文件夹存放分割结果
    if ~exist('temp_segments', 'dir')
        mkdir('temp_segments');
    end

    % 对定位结果进行形态学滤波（去除小噪声）
    imgSegmentReady = bwareaopen(imgLocated, 20);

    figure('Name', 'Step 4: 字符分割');
    subplot(1, 2, 1);
    imshow(imgSegmentReady);
    title('Step 4: 形态学滤波');

    imgSegmentDouble = double(imgSegmentReady);
    [segHeight, segWidth] = size(imgSegmentDouble);

    % --- 阶段一：动态宽度计算 + 中缝圆点擦除 ---
    charWidthThresh = segWidth / 13;

    % 圆点区域硬遮罩（横向26%-31%，纵向40%-60%）
    dotRowTop = max(1, round(segHeight * 0.4));
    dotRowBottom = min(segHeight, round(segHeight * 0.6));
    dotColLeft = max(1, round(segWidth * 0.26));
    dotColRight = min(segWidth, round(segWidth * 0.31));
    imgSegmentReady(dotRowTop:dotRowBottom, dotColLeft:dotColRight) = 0;
    imgSegmentDouble = double(imgSegmentReady);

    % --- 计算水平投影 ---
    projSegment = zeros(1, segWidth);

    for col = 1:segWidth
        for row = 1:segHeight
            if(imgSegmentDouble(row, col) == 1)
                projSegment(1, col) = projSegment(1, col) + 1;
            end
        end
    end

    % 绘制水平投影图
    subplot(1, 2, 2);
    plot(0:segWidth-1, projSegment);
    title('Step 4.1: 水平投影');
    xlabel('列号 (Column)');
    ylabel('白色像素数 (White Pixels)');

    % --- 阶段二：从右向左分割右侧5个数字/字母（charIdx 1~5） ---
    charRight = segWidth;
    charLeft = segWidth;

    figure('Name', 'Step 4: 分割结果');

    for charIdx = 1:5
        % 找字符右边界
        while((projSegment(1, charRight) < 3) && (charRight > 0))
            charRight = charRight - 1;
        end
        charLeft = charRight;

        % 找字符左边界（宽度兜底改为 charWidthThresh）
        while(charLeft > 0 && (((projSegment(1, charLeft) >= 3)) || ((charRight - charLeft) < charWidthThresh)))
            charLeft = charLeft - 1;
        end

        % 裁剪出单个字符
        imgChar = imgSegmentReady(:, charLeft+1:charRight, :);

        % 显示分割结果
        subplot(1, 7, 8 - charIdx);
        imshow(imgChar);
        title(int2str(8 - charIdx));

        % 保存为图片文件
        imwrite(imgChar, fullfile('temp_segments', strcat(int2str(8 - charIdx), '.jpg')));

        charRight = charLeft;
    end

    % --- 阶段三：城市字母超宽拦截与局部二次强切（charIdx = 6）---
    % 先按常规方法找右边界和左边界
    while((projSegment(1, charRight) < 3) && (charRight > 0))
        charRight = charRight - 1;
    end
    charLeft = charRight;

    while(charLeft > 0 && (((projSegment(1, charLeft) >= 3)) || ((charRight - charLeft) < charWidthThresh)))
        charLeft = charLeft - 1;
    end

    % 超宽拦截：如果色块宽度超过标准宽度的1.5倍，判定粘连
    W = charRight - charLeft;
    if W > charWidthThresh * 1.5
        % 在局部区间内找波谷（向内收缩避免边缘干扰）
        searchLeft = min(segWidth, charLeft + 5);
        searchRight = max(1, charRight - 5);

        if searchLeft < searchRight
            localProj = projSegment(searchLeft:searchRight);
            [~, minOffset] = min(localProj);
            minIdx = searchLeft + minOffset - 1;
            charLeft = minIdx;
        end
    end

    % 裁剪城市字母
    imgChar6 = imgSegmentReady(:, charLeft+1:charRight, :);
    subplot(1, 7, 2);
    imshow(imgChar6);
    title('2');
    imwrite(imgChar6, fullfile('temp_segments', '2.jpg'));

    charRight = charLeft;

    % --- 阶段四：省份汉字裁剪（字符1）---
    % 直接取从最左端到第二个字符起始位置的整块区域
    cropLeft1 = 1;
    cropRight1 = max(1, charRight - 1);

    % 裁剪并保存第1个字符
    imgChar1 = imgSegmentDouble(:, cropLeft1:cropRight1, :);

    subplot(1, 7, 1);
    imshow(logical(imgChar1));
    title('1');

    imwrite(logical(imgChar1), fullfile('temp_segments', '1.jpg'));

    % 显示完成信息
    disp(' ');
    disp('========================================');
    disp('  字符分割完成！(Segmentation Complete!)');
    disp('========================================');
    disp('');
    disp('输出文件说明：');
    disp('  temp_segments/1.jpg - 省份汉字');
    disp('  temp_segments/2.jpg - 字母');
    disp('  temp_segments/3.jpg - 数字或字母');
    disp('  temp_segments/4.jpg - 数字或字母');
    disp('  temp_segments/5.jpg - 数字或字母');
    disp('  temp_segments/6.jpg - 数字或字母');
    disp('  temp_segments/7.jpg - 数字或字母');
    disp('========================================');
end
