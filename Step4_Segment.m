function Step4_Segment(imgLocated)
    % Step4_Segment: 字符分割（连通域定位法）
    %
    % 输入：imgLocated - 二值车牌图（字符白、背景黑）
    % 输出：temp_segments/1.jpg ~ 7.jpg

    if ~exist('temp_segments', 'dir')
        mkdir('temp_segments');
    end

    imgReady = bwareaopen(imgLocated, 20);
    [segH, segW] = size(imgReady);

    % 1. 上下裁剪17%，去除铆钉
    cropTop = round(segH * 0.17);
    cropBottom = segH - round(segH * 0.17);
    imgReady = imgReady(cropTop:cropBottom, :);
    [segH, segW] = size(imgReady);

    % 1.5 左右裁剪5%，去除车牌边框
    cropLeft = round(segW * 0.05);
    cropRight = segW - round(segW * 0.05);
    imgReady = imgReady(:, cropLeft:cropRight);
    [segH, segW] = size(imgReady);

    % 2. 连通域分析
    cc = bwconncomp(imgReady);
    stats = regionprops(cc, 'Area', 'BoundingBox', 'PixelIdxList');
    areas = [stats.Area];

    % 3. 过滤面积过小的连通域（小于中位数的15%）
    if isempty(areas)
        warning('无有效连通域');
        return;
    end
    medianArea = median(areas);
    validIdx = find(areas >= medianArea * 0.15);
    stats = stats(validIdx);
    areas = areas(validIdx);

    % 4. 按 x 坐标排序
    bboxes = cat(1, stats.BoundingBox); % N x 4: [x, y, w, h]
    [~, sortIdx] = sort(bboxes(:, 1));
    stats = stats(sortIdx);
    bboxes = bboxes(sortIdx, :);

    % 5. 合并距离过近的连通域（间距 < 车牌宽度的2%）
    mergeGap = segW * 0.02;
    merged = true;
    while merged
        merged = false;
        n = length(stats);
        if n <= 7, break; end
        newStats = [];
        k = 1;
        while k <= n
            curBox = stats(k).BoundingBox;
            curRight = curBox(1) + curBox(3);
            curPixels = stats(k).PixelIdxList;
            % 合并后面距离过近的连通域
            while k < n
                nextBox = stats(k+1).BoundingBox;
                gap = nextBox(1) - curRight;
                if gap < mergeGap
                    % 合并
                    newX = min(curBox(1), nextBox(1));
                    newY = min(curBox(2), nextBox(2));
                    newRight = max(curRight, nextBox(1) + nextBox(3));
                    newBottom = max(curBox(2) + curBox(4), nextBox(2) + nextBox(4));
                    curBox = [newX, newY, newRight - newX, newBottom - newY];
                    curRight = newRight;
                    curPixels = union(curPixels, stats(k+1).PixelIdxList);
                    k = k + 1;
                    merged = true;
                else
                    break;
                end
            end
            s.BoundingBox = curBox;
            s.Area = length(curPixels);
            s.PixelIdxList = curPixels;
            newStats = [newStats, s]; %#ok<AGROW>
            k = k + 1;
        end
        stats = newStats;
    end

    % 6. 选择7个最佳字符连通域
    nCandidates = length(stats);
    bboxes = cat(1, stats.BoundingBox);

    if nCandidates == 7
        charStats = stats;
    elseif nCandidates > 7
        % 按面积降序，取前7个
        allAreas = arrayfun(@(s) s.Area, stats);
        [~, areaIdx] = sort(allAreas, 'descend');
        charStats = stats(areaIdx(1:7));
        % 重新按 x 排序
        bboxes = cat(1, charStats.BoundingBox);
        [~, xIdx] = sort(bboxes(:, 1));
        charStats = charStats(xIdx);
    else
        % 不足7个，用投影法补充
        warning('连通域不足7个(%d个)，使用投影法补充', nCandidates);
        charStats = stats;
    end

    % 7. 裁剪并保存
    figure('Name', 'Step 4: 字符分割');

    subplot(3, 7, 1:7);
    imshow(imgReady);
    title('二值图');

    subplot(3, 7, 8:14);
    proj = sum(imgReady, 1);
    bar(proj);
    hold on;

    for i = 1:min(7, length(charStats))
        bbox = charStats(i).BoundingBox;
        x1 = max(1, round(bbox(1)));
        y1 = max(1, round(bbox(2)));
        x2 = min(segW, round(bbox(1) + bbox(3)));
        y2 = min(segH, round(bbox(2) + bbox(4)));

        xline(x1, 'r--');
        xline(x2, 'r--');

        imgChar = imgReady(y1:y2, x1:x2);

        subplot(3, 7, 14 + i);
        imshow(imgChar);
        title(num2str(i));
        imwrite(imgChar, fullfile('temp_segments', strcat(int2str(i), '.jpg')));
    end
    hold off;

    disp(['  字符分割完成 ' num2str(min(7, length(charStats))) '个']);
end
