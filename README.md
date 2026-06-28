# 车牌识别系统

基于 MATLAB 的中国车牌自动识别系统。

## 版本说明

| 版本 | 识别方法 | 说明 |
|------|----------|------|
| v1.0 | HOG + SVM | 初始版本，基于传统机器学习 |
| v1.1 | HOG + SVM + 预训练模型 | 加入离线训练流程，Step5 加载预训练 SVM 分类器 |
| v2.0 | **CNN 卷积神经网络** | 识别器升级为 CNN，精度更高，泛化能力更强 |

### v1.1 → v2.0 主要变化

- **Step5_Recognize.m**：从 HOG 特征提取 + SVM 分类改为 CNN 卷积神经网络直接分类
- **TrainCNN.m**：新增 CNN 训练脚本，可训练三个独立模型（汉字 / 字母 / 字母数字）
- **模型文件**：`cnn_Chinese.mat`、`cnn_Letter.mat`、`cnn_Alphanum.mat` 替代原有 SVM 模型
- **输入尺寸**：CNN 输入统一为 28×14 灰度图像（SVM 版本为 40×20）

## 项目结构

```
智能交通实训/
├── Main.m                  # 主程序入口
├── Step1_ReadImage.m       # 步骤1：读取图片
├── Step2_Preprocess.m      # 步骤2：图像预处理
├── Step3_Locate.m          # 步骤3：车牌定位
├── Step4_Segment.m         # 步骤4：字符分割
├── Step5_Recognize.m       # 步骤5：字符识别（CNN）
├── QieGe.m                 # 裁剪辅助函数
├── TrainCNN.m              # CNN 模型训练脚本
├── cnn_Chinese.mat         # CNN 汉字分类器（已训练）
├── cnn_Letter.mat          # CNN 字母分类器（已训练）
├── cnn_Alphanum.mat        # CNN 字母数字分类器（已训练）
├── ChePaiKu/               # 车牌图片库
├── temp_segments/          # 分割后的字符图片（运行时生成）
└── 字符模板(4020)/         # 字符模板库（annCh/annGray 训练集）
```

## 使用方法

1. 运行 `Main.m` 启动程序
2. 在弹出的文件选择对话框中选择一张车牌图片
3. 程序自动完成：读图 → 预处理 → 定位 → 分割 → 识别
4. 最终显示识别结果

如需重新训练 CNN 模型，运行 `TrainCNN.m`。

## 算法流程

| 步骤 | 函数 | 方法 |
|------|------|------|
| 读取图片 | `Step1_ReadImage()` | 弹出文件选择对话框 |
| 图像预处理 | `Step2_Preprocess()` | 灰度化 → Canny边缘检测 → 形态学腐蚀 → 闭运算 → 去除小区域 |
| 车牌定位 | `Step3_Locate()` | 垂直投影定位行边界 + 水平投影定位列边界 + 二值化去边框 |
| 字符分割 | `Step4_Segment()` | 水平投影分割法 |
| 字符识别 | `Step5_Recognize()` | **CNN 卷积神经网络分类**（模板匹配备选） |

## 识别能力

- **第1位**：31个省份汉字
- **第2位**：24个字母（A-Z，不含I和O）
- **第3-7位**：34个字母数字组合（0-9, A-Z，不含I和O）

## 环境要求

- MATLAB R2016b 或更高版本
- 需要 Image Processing Toolbox
- 需要 Deep Learning Toolbox（用于 CNN 训练与推理）
