function plateResult = Step5_Recognize(charImgs)
    % Step5_Recognize: 车牌字符识别（SVM特征向量法）
    %
    % 输入：charImgs - 1x7 cell数组，7个字符图片
    % 输出：plateResult - 识别结果字符串

    disp('  [Step 5] 字符识别(SVM)...');

    %% 加载SVM模型
    models = struct();
    models.chinese = loadSVM('classifierChinese.mat');
    models.letter = loadSVM('classifierLetter.mat');
    models.alphanum = loadSVM('classifierAlphanum.mat');

    %% 逐位识别
    plateResult = '';
    for i = 1:7
        img = charImgs{i};
        if size(img, 3) == 3
            img = rgb2gray(img);
        end
        if ~islogical(img)
            img = imbinarize(img);
        end

        switch i
            case 1
                label = svmPredict(img, models.chinese);
            case 2
                label = svmPredict(img, models.letter);
            otherwise
                label = svmPredict(img, models.alphanum);
        end

        plateResult = [plateResult, label];
        disp(['  第' num2str(i) '位: ' label]);
    end

    %% 显示结果
    disp(' ');
    disp('========================================');
    disp(['  识别结果: ' plateResult]);
    disp('========================================');

    figure('Name', '车牌识别结果');
    for i = 1:7
        subplot(2, 4, i);
        imshow(charImgs{i});
        if i == 1, title('省份');
        elseif i == 2, title('字母');
        else, title('数字/字母'); end
    end
    subplot(2, 4, 8);
    text(0.5, 0.5, plateResult, 'FontSize', 24, 'HorizontalAlignment', 'center');
    axis off;
    title('识别结果');
end

%% 加载SVM模型
function model = loadSVM(matFile)
    model = [];
    if exist(matFile, 'file')
        temp = load(matFile);
        vars = fieldnames(temp);
        model = temp.(vars{1});
        disp(['  加载: ' matFile ' ✓']);
    else
        disp(['  不存在: ' matFile]);
    end
end

%% SVM预测
function label = svmPredict(img, model)
    label = '?';
    if isempty(model)
        return;
    end
    imgR = imresize(img, [40 20]);
    hogFeat = extractHOGFeatures(imgR, 'NumBins', 9, ...
        'CellSize', [4 4], 'BlockSize', [2 2]);
    [pred, ~] = predict(model, hogFeat);
    label = char(pred);
end
