function plateResult = Step5_Recognize(charImgs)
    % Step5_Recognize: 车牌字符识别（SVM特征向量法）
    %
    % 输入：charImgs - 1x7 cell数组，7个字符图片
    % 输出：plateResult - 识别结果字符串

    disp('  [Step 5] 字符识别(SVM)...');

    models = struct();
    models.chinese = loadSVM('classifierChinese.mat');
    models.letter = loadSVM('classifierLetter.mat');
    models.alphanum = loadSVM('classifierAlphanum.mat');

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

    disp(' ');
    disp('========================================');
    disp(['  识别结果: ' plateResult]);
    disp('========================================');
end

function model = loadSVM(matFile)
    model = [];
    if exist(matFile, 'file')
        temp = load(matFile);
        vars = fieldnames(temp);
        model = temp.(vars{1});
        disp(['  加载: ' matFile]);
    else
        disp(['  不存在: ' matFile]);
    end
end

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
