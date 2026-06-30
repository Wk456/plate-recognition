function Step6_ResultGUI()
    % Step6_ResultGUI: 车牌识别结果展示界面

    fig = figure('Name', '车牌识别系统', ...
        'NumberTitle', 'off', ...
        'MenuBar', 'none', ...
        'ToolBar', 'none', ...
        'Position', [100, 100, 1000, 520], ...
        'Color', [0.94 0.94 0.94]);

    % ---- 选择图片按钮 ----
    uicontrol('Parent', fig, 'Style', 'pushbutton', ...
        'String', '选择图片', ...
        'FontSize', 11, ...
        'Position', [20, 10, 120, 30], ...
        'Callback', @onSelectImage);

    % ---- 左侧：原图 ----
    annotation(fig, 'textbox', [0.02, 0.92, 0.25, 0.06], ...
        'String', '原始图片', 'FontSize', 12, 'FontWeight', 'bold', ...
        'HorizontalAlignment', 'center', 'EdgeColor', 'none');
    ax1 = axes('Parent', fig, 'Position', [0.03, 0.15, 0.28, 0.75]);
    axis(ax1, 'off');

    % ---- 中间上：车牌灰度 ----
    annotation(fig, 'textbox', [0.34, 0.92, 0.16, 0.06], ...
        'String', '车牌定位', 'FontSize', 12, 'FontWeight', 'bold', ...
        'HorizontalAlignment', 'center', 'EdgeColor', 'none');
    ax2 = axes('Parent', fig, 'Position', [0.34, 0.52, 0.18, 0.38]);
    axis(ax2, 'off');

    % ---- 中间下：车牌二值 ----
    annotation(fig, 'textbox', [0.34, 0.46, 0.16, 0.06], ...
        'String', '二值化', 'FontSize', 11, 'FontWeight', 'bold', ...
        'HorizontalAlignment', 'center', 'EdgeColor', 'none');
    ax3 = axes('Parent', fig, 'Position', [0.34, 0.08, 0.18, 0.38]);
    axis(ax3, 'off');

    % ---- 右侧：7个分割字符 ----
    annotation(fig, 'textbox', [0.55, 0.92, 0.42, 0.06], ...
        'String', '字符分割', 'FontSize', 12, 'FontWeight', 'bold', ...
        'HorizontalAlignment', 'center', 'EdgeColor', 'none');
    charAxes = gobjects(1, 7);
    charLabels = {'省', '市', 'A/B', '1', '2', '3', '4'};
    for i = 1:7
        col = mod(i - 1, 4);
        row = floor((i - 1) / 4);
        left = 0.55 + col * 0.105;
        bottom = 0.68 - row * 0.32;
        charAxes(i) = axes('Parent', fig, 'Position', [left, bottom, 0.095, 0.22]);
        axis(charAxes(i), 'off');
        title(charAxes(i), charLabels{i}, 'FontSize', 9);
    end

    % ---- 右下：识别结果 ----
    resultTxt = annotation(fig, 'textbox', [0.55, 0.08, 0.42, 0.12], ...
        'String', '识别结果: ---', ...
        'FontSize', 14, 'FontWeight', 'bold', ...
        'FontName', 'Microsoft YaHei', ...
        'HorizontalAlignment', 'center', ...
        'VerticalAlignment', 'middle', ...
        'EdgeColor', [0.6 0.6 0.6], ...
        'LineWidth', 1, ...
        'Margin', 6);

    function onSelectImage(~, ~)
        % 清理上一次的分割结果
        if exist('temp_segments', 'dir')
            delete(fullfile('temp_segments', '*.jpg'));
        end

        % 选择图片
        [fileName, filePath, filterIndex] = uigetfile({'*.jpg;*.png;*.bmp', '图片文件'}, '选择车牌图片');
        if isequal(filterIndex, 0), return; end
        imgOriginal = imread(fullfile(filePath, fileName));

        % Step 2
        imgPreprocessed = Step2_Preprocess(imgOriginal);

        % Step 3
        [imgLocated, imgGrayPlate] = Step3_Locate(imgPreprocessed, imgOriginal);

        % Step 4
        Step4_Segment(imgLocated);

        % Step 5
        charImgs = cell(1, 7);
        for i = 1:7
            imgPath = fullfile('temp_segments', [int2str(i) '.jpg']);
            if exist(imgPath, 'file')
                charImgs{i} = imread(imgPath);
            else
                charImgs{i} = zeros(40, 20, 'logical');
            end
        end
        plateResult = Step5_Recognize(charImgs);

        % 更新显示
        imshow(imgOriginal, 'Parent', ax1);
        imshow(imgGrayPlate, 'Parent', ax2);
        imshow(imgLocated, 'Parent', ax3);
        for i = 1:7
            imshow(charImgs{i}, 'Parent', charAxes(i));
            title(charAxes(i), charLabels{i}, 'FontSize', 9);
        end
        resultTxt.String = ['识别结果: ' plateResult];

        disp(' ');
        disp('========================================');
        disp(['  最终识别结果: ' plateResult]);
        disp('========================================');
    end
end
