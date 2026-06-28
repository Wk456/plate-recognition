function plateResult = Step5_Recognize(charImgs)
    % Step5_Recognize: 车牌字符识别
    %
    % 方法：HOG特征提取 + SVM分类器（模板匹配备选）
    % 输入：
    %   charImgs - 1x7 cell数组，包含分割后的7个字符图片
    % 输出：
    %   plateResult - 识别结果字符串（如："川A12345"）

    disp('[Step 5] 字符识别...');

    %% 定义字符类别
    templateFolder = [pwd '\字符模板(4020)\'];
    targetSize = [40 20];

    % 第1位：省份汉字（31个）
    chineseChars = {'藏','川','鄂','甘','赣','港','桂','贵','黑','沪',...
                    '吉','京','津','晋','辽','鲁','蒙','闽','青','琼',...
                    '陕','苏','台','皖','湘','新','渝','豫','粤','云','浙'};

    % 第2位：字母（24个，去掉I和O）
    letterChars = {'A','B','C','D','E','F','G','H','J','K',...
                   'L','M','N','P','Q','R','S','T','U','V',...
                   'W','X','Y','Z'};

    % 第3-7位：数字或字母（34个）
    alphanumChars = {'0','1','2','3','4','5','6','7','8','9',...
                     'A','B','C','D','E','F','G','H','J','K',...
                     'L','M','N','P','Q','R','S','T','U','V',...
                     'W','X','Y','Z'};

    %% 加载已训练的分类器
    disp('  加载分类器模型...');

    classifierChinese = [];
    classifierLetter = [];
    classifierAlphanum = [];

    if exist('classifierChinese.mat', 'file')
        load('classifierChinese.mat', 'classifierChinese');
        disp('    汉字分类器加载成功');
    else
        disp('    警告：classifierChinese.mat 不存在，请先运行 TrainModel.m');
    end

    if exist('classifierLetter.mat', 'file')
        load('classifierLetter.mat', 'classifierLetter');
        disp('    字母分类器加载成功');
    else
        disp('    警告：classifierLetter.mat 不存在，请先运行 TrainModel.m');
    end

    if exist('classifierAlphanum.mat', 'file')
        load('classifierAlphanum.mat', 'classifierAlphanum');
        disp('    字母数字分类器加载成功');
    else
        disp('    警告：classifierAlphanum.mat 不存在，请先运行 TrainModel.m');
    end

    %% 识别字符
    disp('  识别字符...');

    plateResult = '';

    for i = 1:7
        img = charImgs{i};

        % 预处理
        if size(img, 3) == 3
            img = rgb2gray(img);
        end
        img = imbinarize(img);
        img = imresize(img, targetSize);

        % 提取HOG特征
        hogFeature = extractHOGFeatures(img, 'CellSize', [4 4]);

        % 根据位置选择对应的分类器
        switch i
            case 1
                if ~isempty(classifierChinese)
                    [predictedLabel, ~] = predict(classifierChinese, hogFeature);
                else
                    predictedLabel = templateMatch(img, chineseChars, templateFolder, targetSize);
                end
            case 2
                if ~isempty(classifierLetter)
                    [predictedLabel, ~] = predict(classifierLetter, hogFeature);
                else
                    predictedLabel = templateMatch(img, letterChars, templateFolder, targetSize);
                end
            case {3, 4, 5, 6, 7}
                if ~isempty(classifierAlphanum)
                    [predictedLabel, ~] = predict(classifierAlphanum, hogFeature);
                else
                    predictedLabel = templateMatch(img, alphanumChars, templateFolder, targetSize);
                end
        end

        plateResult = [plateResult, predictedLabel{1}];
        disp(['  第' num2str(i) '位: ' predictedLabel{1}]);
    end

    %% 显示结果
    disp(' ');
    disp('========================================');
    disp(['  识别结果: ' plateResult]);
    disp('========================================');

    % 图形窗口显示结果
    figure('Name', '车牌识别结果');
    for i = 1:7
        subplot(2, 4, i);
        imshow(charImgs{i});
        if i == 1
            title('省份');
        elseif i == 2
            title('字母');
        else
            title('数字/字母');
        end
    end
    subplot(2, 4, 8);
    text(0.5, 0.5, plateResult, 'FontSize', 24, 'HorizontalAlignment', 'center');
    axis off;
    title('识别结果');
end

%% 辅助函数：模板匹配（备选方案）
function predictedLabel = templateMatch(img, charList, templateFolder, targetSize)
    bestScore = inf;
    bestChar = '?';

    for i = 1:length(charList)
        charName = charList{i};
        templatePath = [templateFolder charName '.bmp'];

        if exist(templatePath, 'file')
            try
                tmpl = imread(templatePath);
                if size(tmpl, 3) == 3
                    tmpl = rgb2gray(tmpl);
                end
                if ~islogical(tmpl)
                    tmpl = imbinarize(tmpl);
                end
                tmpl = double(tmpl);
                tmpl = imresize(tmpl, targetSize);

                diff = abs(double(img) - double(tmpl));
                score = sum(diff(:));

                if score < bestScore
                    bestScore = score;
                    bestChar = charName;
                end
            catch
            end
        end
    end

    predictedLabel = {bestChar};
end