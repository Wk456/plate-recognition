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
    %
    % 使用方法：
    %   Step4_Segment(imgLocated);

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

    % --- Step 4.1: 计算水平投影 ---
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

    % --- Step 4.2: 从右向左分割后6个字符 ---
    charRight = segWidth;
    charLeft = segWidth;

    figure('Name', 'Step 4: 分割结果');

    for charIdx = 1:6
        % 找字符右边界
        while((projSegment(1, charRight) < 3) && (charRight > 0))
            charRight = charRight - 1;
        end
        charLeft = charRight;

        % 找字符左边界
        while(((projSegment(1, charLeft) >= 3) && (charLeft > 0)) || ((charRight - charLeft) < 15))
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

    % --- Step 4.3: 特别处理第1个字符（省份汉字）---
    char1Right = charLeft;

    while((projSegment(1, char1Right) < 3) && (char1Right > 0))
        char1Right = char1Right - 1;
    end

    % 添加边距（右边扩展3像素）
    padding = 3;
    cropRight1 = min(segWidth, char1Right + padding);

    % 裁剪并保存第1个字符
    imgChar1 = imgSegmentDouble(:, 1:cropRight1, :);

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
