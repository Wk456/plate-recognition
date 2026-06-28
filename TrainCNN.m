%% ========================================================================
%  CNN 训练脚本：训练三个卷积神经网络模型并保存
%  ========================================================================
%  模型1：省份汉字分类器（31类）
%  模型2：字母分类器（24类，第2位用）
%  模型3：字母数字分类器（34类，第3-7位用）
%
%  使用方法：运行一次此脚本，生成 cnn_Chinese.mat / cnn_Letter.mat / cnn_Alphanum.mat
%  之后运行 Main.m 时 Step5 直接加载模型

close all; clc; clear;

templateFolder = [pwd '\字符模板(4020)\'];
targetSize = [28 14];
numEpochs = 10;
miniBatchSize = 64;

%% 省份文件夹名 → 中文字符 映射
folderToChinese = containers.Map(...
    {'zh_cuan','zh_e','zh_gan','zh_gan1','zh_gui','zh_gui1',...
     'zh_hei','zh_hu','zh_ji','zh_jin','zh_jing','zh_jl',...
     'zh_liao','zh_lu','zh_meng','zh_min','zh_ning','zh_qing',...
     'zh_qiong','zh_shan','zh_su','zh_sx','zh_wan','zh_xiang',...
     'zh_xin','zh_yu','zh_yu1','zh_yue','zh_yun','zh_zang','zh_zhe'},...
    {'川','鄂','甘','赣','桂','贵',...
     '黑','沪','吉','津','京','晋',...
     '辽','鲁','蒙','闽','宁','青',...
     '琼','陕','苏','台','皖','湘',...
     '新','渝','豫','粤','云','藏','浙'});

%% ==================== 训练汉字分类器（已训练，跳过）====================
disp('========================================');
disp('  [1/3] 汉字 CNN 已训练，跳过');
disp('========================================');

%% ==================== 训练字母分类器 ====================
disp(' ');
disp('========================================');
disp('  [2/3] 训练字母 CNN 分类器...');
disp('========================================');

letterSet = {'A','B','C','D','E','F','G','H','J','K',...
             'L','M','N','P','Q','R','S','T','U','V',...
             'W','X','Y','Z'};

[grayImages, grayRawLabels] = loadImages(fullfile(templateFolder, 'annGray'), targetSize);

letterIdx = ismember(grayRawLabels, letterSet);
letterImages = grayImages(:,:,:,letterIdx);
letterLabels = grayRawLabels(letterIdx);

uniqueLetter = unique(letterLabels);
disp(['  样本数: ' num2str(size(letterImages, 4)) '，类别数: ' num2str(length(uniqueLetter))]);

if size(letterImages, 4) > 0 && length(uniqueLetter) > 1
    dsLetterImg = arrayDatastore(letterImages, 'IterationDimension', 4);
    dsLetterLbl = arrayDatastore(categorical(letterLabels));
    dsLetter = combine(dsLetterImg, dsLetterLbl);

    layersLetter = buildCNN([targetSize, 1], length(uniqueLetter));
    options = trainingOptions('adam', ...
        'MaxEpochs', numEpochs, 'MiniBatchSize', miniBatchSize, ...
        'InitialLearnRate', 0.001, ...
        'Verbose', true, 'VerboseFrequency', 1, ...
        'Plots', 'none');

    disp(['  开始训练，共 ' num2str(numEpochs) ' 轮，' num2str(size(letterImages,4)) ' 个样本...']);
    netLetter = trainNetwork(dsLetter, layersLetter, options);
    save('cnn_Letter.mat', 'netLetter');
    disp('  字母 CNN 已保存: cnn_Letter.mat');
end

%% ==================== 训练字母数字分类器 ====================
disp(' ');
disp('========================================');
disp('  [3/3] 训练字母数字 CNN 分类器...');
disp('========================================');

uniqueAlphanum = unique(grayRawLabels);
disp(['  样本数: ' num2str(size(grayImages, 4)) '，类别数: ' num2str(length(uniqueAlphanum))]);

if size(grayImages, 4) > 0 && length(uniqueAlphanum) > 1
    dsAlphanumImg = arrayDatastore(grayImages, 'IterationDimension', 4);
    dsAlphanumLbl = arrayDatastore(categorical(grayRawLabels));
    dsAlphanum = combine(dsAlphanumImg, dsAlphanumLbl);

    layersAlphanum = buildCNN([targetSize, 1], length(uniqueAlphanum));
    options = trainingOptions('adam', ...
        'MaxEpochs', numEpochs, 'MiniBatchSize', miniBatchSize, ...
        'InitialLearnRate', 0.001, ...
        'Verbose', true, 'VerboseFrequency', 1, ...
        'Plots', 'none');

    disp(['  开始训练，共 ' num2str(numEpochs) ' 轮，' num2str(size(grayImages,4)) ' 个样本...']);
    netAlphanum = trainNetwork(dsAlphanum, layersAlphanum, options);
    save('cnn_Alphanum.mat', 'netAlphanum');
    disp('  字母数字 CNN 已保存: cnn_Alphanum.mat');
end

%% ==================== 完成 ====================
disp(' ');
disp('========================================');
disp('  CNN 训练完成！生成文件：');
disp('    cnn_Chinese.mat    - 汉字 CNN 模型');
disp('    cnn_Letter.mat     - 字母 CNN 模型');
disp('    cnn_Alphanum.mat   - 字母数字 CNN 模型');
disp('========================================');

%% ==================== 局部函数（必须放在文件末尾）====================

function [images, labels] = loadImages(folderPath, targetSize)
    imageList = {};
    labels = {};

    subDirs = dir(folderPath);
    subDirs = subDirs([subDirs.isdir]);
    subDirs = subDirs(~ismember({subDirs.name}, {'.','..'}));

    for d = 1:length(subDirs)
        folderName = subDirs(d).name;
        imgFiles = dir(fullfile(folderPath, folderName, '*.jpg'));

        for f = 1:length(imgFiles)
            imgPath = fullfile(folderPath, folderName, imgFiles(f).name);
            try
                img = imread(imgPath);
                if size(img, 3) == 3
                    img = rgb2gray(img);
                end
                if ~islogical(img)
                    img = imbinarize(img);
                end
                img = double(img);
                img = imresize(img, targetSize);
                imageList{end+1} = img;
                labels{end+1} = folderName;
            catch
            end
        end
    end

    % 合并为 4D 数组 H×W×1×N
    N = length(imageList);
    if N > 0
        images = zeros([targetSize, 1, N], 'double');
        for i = 1:N
            images(:,:,1,i) = imageList{i};
        end
    else
        images = [];
    end
    labels = labels';
end

function layers = buildCNN(inputSize, numClasses)
    layers = [
        imageInputLayer(inputSize, 'Name', 'input', 'Normalization', 'none')

        convolution2dLayer(3, 32, 'Padding', 'same', 'Name', 'conv1')
        batchNormalizationLayer('Name', 'bn1')
        reluLayer('Name', 'relu1')
        maxPooling2dLayer(2, 'Stride', 2, 'Name', 'pool1')

        convolution2dLayer(3, 64, 'Padding', 'same', 'Name', 'conv2')
        batchNormalizationLayer('Name', 'bn2')
        reluLayer('Name', 'relu2')
        maxPooling2dLayer(2, 'Stride', 2, 'Name', 'pool2')

        convolution2dLayer(3, 128, 'Padding', 'same', 'Name', 'conv3')
        batchNormalizationLayer('Name', 'bn3')
        reluLayer('Name', 'relu3')
        averagePooling2dLayer(2, 'Stride', 2, 'Name', 'pool3')

        fullyConnectedLayer(256, 'Name', 'fc1')
        reluLayer('Name', 'relu4')
        dropoutLayer(0.5, 'Name', 'drop1')
        fullyConnectedLayer(numClasses, 'Name', 'fc2')
        softmaxLayer('Name', 'softmax')
        classificationLayer('Name', 'output')
    ];
end
