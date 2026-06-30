function imgOriginal = Step1_ReadImage()
    % Step1_ReadImage: 读取原始图片
    %
    % 输出：
    %   imgOriginal - 原始RGB图片矩阵 (height x width x 3)

    [fileName, filePath, filterIndex] = uigetfile('ChePaiKu\*.jpg', '选择车牌图片');

    if isequal(filterIndex, 0)
        error('用户取消选择，程序退出');
    end

    imgOriginal = imread([filePath, fileName]);
end
