function imgOriginal = Step1_ReadImage()
    % Step1_ReadImage: 读取原始图片
    %
    % 输出：
    %   imgOriginal - 原始RGB图片矩阵 (height × width × 3)
    %
    % 使用方法：
    %   imgOriginal = Step1_ReadImage();

    % 弹出文件选择对话框
    [fileName, filePath, filterIndex] = uigetfile('ChePaiKu\*.jpg', '选择车牌图片');

    % 检查用户是否取消选择
    if isequal(filterIndex, 0)
        error('用户取消选择，程序退出');
    end

    % 读取选中的图片
    imgOriginal = imread([filePath, fileName]);

    % 显示原始图片
    figure('Name', 'Step 1: 原始图片');
    subplot(3, 2, 1);
    imshow(imgOriginal);
    title('原始图片 (Original Image)');
end