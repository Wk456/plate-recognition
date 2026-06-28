function charCount = Step4_Segment(imgLocated)
    % Step4_Segment: 字符分割（自适应阈值 + 切割校验）
    %
    % 方法：水平投影分割法
    % 中国车牌格式：[省份汉字][字母][5个数字/字母]
    %
    % 输入：
    %   imgLocated - 精确定位后的车牌二值图
    %
    % 输出：
    %   charCount - 切割出的字符数量（应为7）
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

    % 最小字符宽度：车牌宽度的1/15
    minCharWidth = max(5, round(segWidth / 15));

    %% 自适应切割 + 校验重试
    charCount = 0;
    retryCount = 0;
    maxRetry = 3;
    thresholdScale = 1.0;  % 阈值缩放因子，重试时逐步降低

    while charCount ~= 7 && retryCount < maxRetry
        retryCount = retryCount + 1;

        % 计算水平投影
        projSegment = zeros(1, segWidth);
        for col = 1:segWidth
            for row = 1:segHeight
                if(imgSegmentDouble(row, col) == 1)
                    projSegment(1, col) = projSegment(1, col) + 1;
                end
            end
        end

        % 自适应阈值：取投影最大值的8%，乘以缩放因子
        maxProj = max(projSegment);
        segThreshold = max(1, round(maxProj * 0.08 * thresholdScale));
        minCharWidthAdaptive = max(5, round(segWidth / 15));

        % 绘制水平投影图
        subplot(1, 2, 2);
        plot(0:segWidth-1, projSegment);
        hold on;
        yline(segThreshold, 'r--', 'Threshold');
        hold off;
        title(['Step 4.1: 水平投影 (阈值=' num2str(segThreshold) ')']);
        xlabel('列号 (Column)');
        ylabel('白色像素数 (White Pixels)');

        % --- 从右向左分割后6个字符 ---
        charRight = segWidth;
        charLeft = segWidth;
        tempChars = {};
        figure('Name', 'Step 4: 分割结果');

        for charIdx = 1:6
            % 找字符右边界
            while((projSegment(1, charRight) < segThreshold) && (charRight > 0))
                charRight = charRight - 1;
            end
            charLeft = charRight;

            % 找字符左边界
            while(((projSegment(1, charLeft) >= segThreshold) && (charLeft > 0)) || ((charRight - charLeft) < minCharWidthAdaptive))
                charLeft = charLeft - 1;
            end

            % 裁剪出单个字符
            if charLeft+1 <= charRight
                imgChar = imgSegmentReady(:, charLeft+1:charRight, :);
                tempChars{end+1} = imgChar;

                subplot(1, 7, 8 - charIdx);
                imshow(imgChar);
                title(int2str(8 - charIdx));
            end

            charRight = charLeft;
        end

        % --- 特别处理第1个字符（省份汉字）---
        char1Right = charLeft;
        while((projSegment(1, char1Right) < segThreshold) && (char1Right > 0))
            char1Right = char1Right - 1;
        end

        padding = 3;
        cropRight1 = min(segWidth, char1Right + padding);
        imgChar1 = imgSegmentDouble(:, 1:cropRight1, :);
        tempChars{end+1} = imgChar1;  % 最后加入，后面会翻转

        % 检查切割数量
        charCount = length(tempChars);

        if charCount ~= 7
            disp(['  切割数量为 ' num2str(charCount) '，不是7个，重试...']);
            thresholdScale = thresholdScale * 0.7;  % 降低阈值缩放因子
            close all;
        end
    end

    % 翻转顺序（tempChars是7到1的顺序，需要翻转为1到7）
    if charCount == 7
        tempChars = fliplr(tempChars);

        % 显示最终结果并保存
        figure('Name', 'Step 4: 分割结果');
        for i = 1:7
            subplot(1, 7, i);
            if i == 1
                imshow(logical(tempChars{i}));
            else
                imshow(tempChars{i});
            end
            title(int2str(i));

            % 保存文件
            if i == 1
                imwrite(logical(tempChars{i}), fullfile('temp_segments', '1.jpg'));
            else
                imwrite(tempChars{i}, fullfile('temp_segments', [int2str(i) '.jpg']));
            end
        end
    else
        disp(['  警告：最终切割数量为 ' num2str(charCount) '，不是7个']);
    end

    % 显示完成信息
    disp(' ');
    disp('========================================');
    disp(['  字符分割完成！切割数量: ' num2str(charCount)]);
    disp('========================================');
end
