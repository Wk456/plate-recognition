# 车牌识别系统

基于 MATLAB 的中国车牌自动识别系统，采用传统图像处理方法实现。

## 项目结构

```
智能交通实训/
├── Main.m                  # 主程序入口
├── Step1_ReadImage.m       # 步骤1：读取图片
├── Step2_Preprocess.m      # 步骤2：图像预处理
├── Step3_Locate.m          # 步骤3：车牌定位
├── Step4_Segment.m         # 步骤4：字符分割
├── Step5_Recognize.m       # 步骤5：字符识别
├── QieGe.m                 # 裁剪辅助函数
├── ChePaiKu/               # 车牌图片库
├── temp_segments/          # 分割后的字符图片（运行时生成）
└── 字符模板(4020)/         # 字符模板库（0-9, A-Z, 省份汉字）
```

## 使用方法

1. 运行 `Main.m` 启动程序
2. 在弹出的文件选择对话框中选择一张车牌图片
3. 程序自动完成：读图 → 预处理 → 定位 → 分割 → 识别
4. 最终显示识别结果

## 算法流程

| 步骤 | 函数 | 方法 |
|------|------|------|
| 读取图片 | `Step1_ReadImage()` | 弹出文件选择对话框 |
| 图像预处理 | `Step2_Preprocess()` | 灰度化 → Canny边缘检测 → 形态学腐蚀 → 闭运算 → 去除小区域 |
| 车牌定位 | `Step3_Locate()` | 垂直投影定位行边界 + 水平投影定位列边界 + 二值化去边框 |
| 字符分割 | `Step4_Segment()` | 水平投影分割法 |
| 字符识别 | `Step5_Recognize()` | HOG特征提取 + SVM分类器（模板匹配备选） |

## 识别能力

- **第1位**：31个省份汉字
- **第2位**：24个字母（A-Z，不含I和O）
- **第3-7位**：34个字母数字组合（0-9, A-Z，不含I和O）

## 环境要求

- MATLAB R2016b 或更高版本
- 需要 Image Processing Toolbox
- 需要 Statistics and Machine Learning Toolbox（用于 SVM 分类器）
