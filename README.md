# 车牌识别系统

基于 MATLAB 的中国车牌自动识别系统，支持 GUI 操作界面。

## 版本说明

| 版本 | 识别方法 | 主要特性 |
| --- | --- | --- |
| v1.0 | HOG + SVM | 初始版本，完整 6 步流程（含独立倾斜校正步骤） |
| v1.1 | HOG + SVM + 预训练模型 | 加入离线训练流程，Step5 加载预训练 SVM 分类器 |
| v2.0 | CNN 卷积神经网络 | 识别器升级为 CNN，新增 TrainCNN.m 训练脚本 |
| **v3.0** | **HOG + SVM** | **回归 SVM，重构为 5 步流程，新增 GUI 结果界面** |

### 各版本详细说明

#### v1.0 - 初始版本
- 6 步流程：读图 → 预处理 → 定位 → 倾斜校正 → 分割 → 识别
- 灰度化 + Canny 边缘检测 + 形态学处理
- 垂直/水平投影法定位与分割
- 基于 HOG 特征的 SVM 分类

#### v1.1 - 预训练 SVM 模型
- 新增 `classifierChinese.mat`、`classifierLetter.mat`、`classifierAlphanum.mat`
- 无需每次训练，直接加载预训练模型
- HOG 特征：40x20 图片，CellSize=[4,4]，BlockSize=[2,2]，NumBins=9 → 1296 维特征

#### v2.0 - CNN 识别
- 识别器从 SVM 升级为 CNN 卷积神经网络
- 新增 `TrainCNN.m` 训练脚本，可训练汉字/字母/字母数字三个模型
- CNN 输入统一为 28x14 灰度图像
- 需要 Deep Learning Toolbox

#### v3.0 - GUI 界面 + 流程重构
- 合并倾斜校正到 Step3（删除原 Step4_Deskew.m）
- Step2 改为 HSV 蓝色检测 + Canny 边缘检测双重验证
- Step4 改用连通域定位法替代投影法
- 新增 Step6_ResultGUI.m：GUI 操作界面
  - 选择图片按钮
  - 原图 / 车牌定位 / 二值化 / 字符分割 / 识别结果 一屏展示
- 去除所有中间 figure 窗口
- 删除 CNN 相关文件，回归 SVM 识别

## 项目结构

```text
智能交通实训/
├── Main.m                  # 主程序入口（启动 GUI）
├── Step1_ReadImage.m       # 步骤1：读取图片
├── Step2_Preprocess.m      # 步骤2：图像预处理（HSV+Canny双验证）
├── Step3_Locate.m          # 步骤3：车牌定位 + 倾斜校正
├── Step4_Segment.m         # 步骤4：字符分割（连通域定位法）
├── Step5_Recognize.m       # 步骤5：字符识别（HOG+SVM）
├── Step6_ResultGUI.m       # 结果展示GUI界面
├── classifierChinese.mat   # SVM 汉字分类器
├── classifierLetter.mat    # SVM 字母分类器
├── classifierAlphanum.mat  # SVM 字母数字分类器
├── ChePaiKu/               # 车牌图片库
├── temp_segments/          # 分割后的字符图片（运行时生成）
└── 字符模板(4020)/         # 字符模板库
```

## 使用方法

1. 运行 `Main.m` 启动程序
2. 点击「选择图片」按钮，从 `ChePaiKu/` 中选择一张车牌图片
3. 程序自动完成：预处理 → 定位 → 分割 → 识别
4. GUI 界面显示完整处理流程和最终识别结果

## 算法流程

| 步骤 | 函数 | 方法 |
| --- | --- | --- |
| 读取图片 | `Step1_ReadImage()` | 文件选择对话框 |
| 图像预处理 | `Step2_Preprocess()` | HSV蓝色检测 + Canny边缘检测 → 取交集 |
| 车牌定位 | `Step3_Locate()` | 膨胀+连通域粗定位 → Hough倾斜校正 → 投影精确裁剪 → Otsu二值化 |
| 字符分割 | `Step4_Segment()` | 连通域定位法（面积过滤 + 距离合并 + 7字符选择） |
| 字符识别 | `Step5_Recognize()` | HOG特征提取 + SVM分类（汉字/字母/字母数字三模型） |
| 结果展示 | `Step6_ResultGUI()` | GUI界面：原图 + 定位 + 二值 + 分割 + 识别结果 |

## 识别能力

- **第1位**：31个省份汉字
- **第2位**：24个字母（A-Z，不含I和O）
- **第3-7位**：34个字母数字组合（0-9, A-Z，不含I和O）

## 环境要求

- MATLAB R2016b 或更高版本
- 需要 Image Processing Toolbox
