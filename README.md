# CMA Dual-Engine OCR

> 源码可见，仅限非商业使用（Source Available / Noncommercial Use Only）

一个面向 Windows 的本地批量 PDF 关键词检索工具。它分别使用 Tesseract 和
PaddleOCR 识别扫描件，最后合并、去重并导出 XLSX/CSV。项目同时提供控制台模式和
本地网页模式；网页只是 OCR 主程序的可视化入口，不会把 PDF 或识别结果上传到网络。

## 主要功能

- 递归扫描文件夹内的 PDF，并按 400 DPI 渲染扫描页。
- Tesseract 与 PaddleOCR 独立完成整批识别，不区分主次。
- 合并两套结果，按文件、页码和关键词去重，并标注单模型/双模型命中。
- 关键词大小写不敏感，兼容 Unicode 变体、OCR 空格断裂和受控的常见误识别。
- 对疑似页面进行高 DPI 二次精查；低可信模糊结果进入待复核表，不混入可信主表。
- 保存进度、心跳、错误日志和续跑状态；意外中断后可以继续或重建结果。
- 网页实时显示当前模型、文件进度、页级进度、心跳摘要和阶段性/最终合并结果。
- 命中结果可回查 PDF，网页预览服务仅绑定 `127.0.0.1`。

## 两种运行方式及文件关系

网页版包含全部控制台 OCR 能力，是控制台增强版的功能超集。两种模式共用同一个
`cma_dual_keyword_enhanced.py`，不会维护两套识别算法。

### 控制台模式需要的文件

| 文件 | 是否必需 | 用途 |
| --- | --- | --- |
| `cma_dual_keyword_enhanced.py` | 必需 | OCR、关键词匹配、合并去重和导出核心 |
| `requirements.txt` | 必需 | 隔离环境的固定依赖版本 |
| `01_install_environment.bat` | 推荐保留 | 首次安装或主动修复环境 |
| `03_run_ocr_console.bat` | 推荐保留 | 自动查找 Python 并启动控制台模式 |
| `04_rebuild_results_only.bat` | 可选 | 不重新 OCR，只从续跑状态重建结果 |

环境已经正确安装时，也可以在命令行直接运行：

```bat
python cma_dual_keyword_enhanced.py
```

直接双击 `.py` 可能在报错后立即关闭窗口，因此普通用户更适合运行
`03_run_ocr_console.bat`。

### 网页模式额外需要的文件

| 文件 | 用途 |
| --- | --- |
| `cma_web_app.py` | Streamlit 本地网页界面、实时结果和 PDF 回查 |
| `02_start_web_app.bat` | 检查环境并启动本地网页 |

网页模式仍然需要前述核心主程序和 `requirements.txt`。仓库已经包含所有文件，通常
无需手工拆分。

## 系统要求

- Windows 10 或 Windows 11。
- Anaconda 或 Miniconda，建议使用 Python 3.10 的 base 解释器作为启动入口。
- Tesseract OCR，并安装 `chi_sim` 和 `eng` 语言数据。
- 首次安装依赖和首次加载 PaddleOCR 模型时需要联网；之后可离线处理本地 PDF。

程序只创建或复用名为 `cma_ocr27_web` 的独立 Conda 环境，不会在 Anaconda base
环境里安装、卸载或降级 NumPy、PaddleOCR 等包。

## 快速开始

1. 下载仓库或 Release 压缩包，并完整解压到普通本地文件夹。不要在 ZIP 预览窗口中
   直接运行批处理。
2. 确认 Tesseract 已安装，并支持简体中文和英文。
3. 首次使用可运行 `01_install_environment.bat`，等待环境检查完成。
4. 网页模式运行 `02_start_web_app.bat`；控制台模式运行
   `03_run_ocr_console.bat`。
5. 网页默认地址为 <http://127.0.0.1:8501>。OCR 运行期间应保持启动网页的命令窗口
   开启；关闭或刷新浏览器标签页不会停止已经启动的 OCR 子进程。

网页输入内容：

- 关键词：多个关键词可用中文或英文逗号、顿号、分号分隔。
- PDF 根文件夹：程序会递归查找其中的 PDF。
- 结果保存文件夹：建议每个任务使用独立目录。
- DPI：默认 400；除非文件非常特殊，建议先保持默认值。

## 命令行示例

```bat
python cma_dual_keyword_enhanced.py "D:\PDF" -k "CMA,资质,检测" -o "D:\OCR_Results"
```

可选参数：

```text
--dpi 400          PDF 渲染 DPI
--binarize         对 Tesseract 输入启用二值化
--rebuild-results  从 .cma_ocr_resume 重建结果，不重新执行 OCR
```

完整参数可运行：

```bat
python cma_dual_keyword_enhanced.py --help
```

## 安装位置和镜像配置

启动器会依次检查当前用户和系统常见的 Anaconda/Miniconda 安装位置，然后检查
`PATH`。如果 Conda 安装在自定义目录，可以在当前命令窗口指定：

```bat
set CMA_BOOTSTRAP_PY=D:\Miniconda3\python.exe
```

Python 主程序还支持用 `CMA_CONDA_EXE` 或 `CONDA_EXE` 指定 `conda.exe`。如果
Tesseract 不在标准位置或 `PATH` 中，可以指定：

```bat
set TESSERACT_CMD=D:\Tools\Tesseract-OCR\tesseract.exe
```

依赖安装默认使用官方 PyPI。需要使用其他镜像时，可在运行安装器前设置：

```bat
set CMA_PIP_INDEX_URL=https://pypi.tuna.tsinghua.edu.cn/simple
```

这些设置只影响当前命令窗口，不会修改 Python base 环境。

## 输出文件

结果目录会保存：

- `cma_results.xlsx`：完整工作簿。
- `cma_results_merged.csv`：最终可信合并结果。
- `cma_results_candidates.csv`：待人工复核候选。
- `cma_results_errors.csv`：包含文件名、页码和引擎的错误明细。
- `cma_results.log`：UTF-8 运行日志。
- `runs/时间戳/`：每次运行的完整归档。
- `.cma_ocr_resume/`：续跑所需的内部状态，不建议在任务完成前删除。

## 安全与隐私

- OCR 全程在本机运行，程序没有上传 PDF 或结果的功能。
- Streamlit 和 PDF 预览服务只监听 `127.0.0.1`。
- PDF 回查接口只允许访问用户所选 PDF 根目录内的 `.pdf` 文件。
- 仓库不包含测试 PDF、识别结果、日志、个人绝对路径、账号、令牌或模型缓存。

## 注意事项

- PaddleOCR 首次运行可能下载模型，初始化数分钟属于正常情况，可通过心跳确认仍在工作。
- 扫描质量、字体、印章遮挡和页面倾斜都会影响 OCR；模糊匹配结果应人工复核。
- 本项目当前以 Windows 本地运行方式为目标，批处理和默认阅读器打开功能未适配
  macOS/Linux。

## 版权与许可证

Copyright © 2026 梁慧。

本项目采用 [PolyForm Noncommercial License 1.0.0](LICENSE.md)，属于“源码可见、
仅限非商业使用”，不是 OSI 定义下的开源软件。

- 允许个人学习、研究、测试、修改以及其他非商业用途。
- 允许非营利性教育、科研、公益组织在非商业目的下使用。
- 非商业传播必须同时保留完整许可证和版权声明。
- 销售、收费服务、商业部署、商业咨询、转售以及集成到营利性产品均须事先取得
  著作权人梁慧的书面授权。
- 除许可证明确授予的权利外，其他权利均由著作权人保留。

PaddleOCR、Tesseract、Streamlit 等第三方组件分别适用其自身许可证，本项目的非商业
许可不改变第三方组件的授权条件。完整且具有约束力的条款以 [LICENSE.md](LICENSE.md)
中的英文原文为准。

