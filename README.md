# ScanPDF Keyword Finder

> v1.1.0 · Windows 本地双引擎并行版  
> Copyright © 2026 梁慧。仅限非商业使用。

批量识别扫描 PDF 中的关键词。程序在本地使用 Tesseract 和 PaddleOCR 两个独立引擎，
分别保存结果，最后合并去重，并提供控制台与本地网页两种操作方式。

PDF、OCR 文本和结果文件不会上传到云端。网页仅监听 `127.0.0.1`。

## v1.1.0 升级内容

相较于 v1.0.0 串行增强版，本版本重点升级了执行方式和进度展示：

- 每页 PDF 只进行一次 400 DPI 无损 RGB 渲染，减少重复渲染时间。
- Tesseract 与 PaddleOCR 在两个独立 Windows 子进程中并行识别相同只读像素。
- 两个引擎地位相同，OCR 文本、失败重试、原始命中和完成状态分别保存。
- 当前文件的两个模型都完成后，文件总进度才增加并进入下一份 PDF。
- 某个模型先完成当前页时，网页显示“本页已完成，等待另一引擎”。
- 网页分别显示两个模型的当前页、运行状态、单页耗时、心跳和 500 DPI 二次精查状态。
- 运行中展示双引擎原始命中的实时中立汇总，任务结束后切换到最终 merge 去重结果。
- PaddleOCR 每处理 8 个文件自动重启工作进程，降低长任务的原生内存累积风险。
- 保留关键词大小写忽略、空格断裂、常见 OCR 混淆、疑似匹配候选和 500 DPI 二次精查。
- Tesseract 自动检查 C/D 盘标准安装位置、用户目录、Conda 环境、系统 PATH 和便携目录。
- 继续使用 `cma_ocr27_web` 隔离环境，不修改 Anaconda base，也不会重复创建新环境。

完整版本记录见 [CHANGELOG.md](CHANGELOG.md)。

## 运行要求

- Windows 10 或 Windows 11
- Anaconda 或 Miniconda，Python 3.10
- Tesseract OCR，并安装 `chi_sim` 和 `eng` 语言数据
- 首次初始化和首次加载 PaddleOCR 模型时需要联网

Python 依赖已锁定，主要版本为：

- `paddlepaddle==2.6.2`
- `paddleocr==2.7.0.3`
- `numpy==1.23.5`
- `streamlit==1.39.0`

依赖只安装在 `cma_ocr27_web` 环境，不会修改 base 环境。

## 下载

普通用户请在 GitHub 仓库右侧进入 **Releases**，下载最新版本 Assets 中的：

`ScanPDF-Keyword-Finder-v1.1.0-Windows.zip`

`Code → Download ZIP` 下载的是源码快照；Release 附件才是经过整理的完整运行包。

## 使用方法

1. 将完整 ZIP 解压到新的文件夹，不要直接在压缩包内运行。
2. 首次使用，双击 `01_install_environment.bat`。
3. 使用网页工作台，双击 `02_start_web_app.bat`。
4. 只使用控制台，双击 `03_run_ocr_console.bat`。
5. 如果 OCR 已完成但导出阶段中断，可运行 `04_rebuild_results_only.bat`，无需重新识别。

已经存在健康的 `cma_ocr27_web` 环境时，第 2 步只会检查并复用，不会创建第二个环境。

## 网页工作台

网页启动后默认打开 `http://127.0.0.1:8501`，可以：

- 输入关键词、PDF 根目录和结果保存目录；
- 查看文件总进度以及两个模型对当前文件的独立进度；
- 查看实时命中、最终可信结果、疑似候选和错误明细；
- 按文件名、关键词、模型来源和置信度筛选；
- 导出当前筛选结果为 XLSX；
- 点击命中记录，在新标签页预览对应 PDF 页，或交给默认 PDF 阅读器打开。

关闭浏览器标签页不会停止 OCR；关闭启动网页的 CMD 窗口会停止网页服务。
OCR 子进程运行期间，CMD 窗口仍显示更详细的文件进度、页级进度、心跳和错误信息。

## 控制台运行

也可以在正确的隔离环境中执行：

```bat
python cma_dual_keyword_parallel.py "D:\PDF" -k "CMA,资质,检测" -o "D:\OCR_Results"
```

关键词支持英文大小写忽略；多个关键词可使用中英文逗号、顿号或分号分隔。

## Tesseract

`pytesseract` 只是 Python 接口，电脑上仍需存在真正的 `tesseract.exe` 和
`chi_sim+eng` 语言数据。程序会检查常见安装位置，也可以显式指定：

```bat
set TESSERACT_CMD=D:\Tools\Tesseract-OCR\tesseract.exe
```

如果启动日志显示“仅使用 PaddleOCR”，该任务不是完整双引擎任务。建议停止任务、
补齐 Tesseract 后，使用新的结果目录重新运行。

## 输出文件

- `cma_results.xlsx`：完整 Excel 结果
- `cma_results_merged.csv`：最终可信合并结果
- `cma_results_candidates.csv`：需要人工复核的疑似命中
- `cma_results_tesseract_raw.csv`：Tesseract 独立原始命中
- `cma_results_paddle_raw.csv`：PaddleOCR 独立原始命中
- `cma_results_errors.csv`：错误文件、页码、阶段和异常信息
- `cma_results.log`：完整运行日志
- `runs\时间戳_进程号\`：每次任务的独立归档

程序保留断点续跑状态；全部文件由双引擎处理完成后会自动清除临时状态。个别文件失败时，
错误会写入日志，后续文件仍会继续处理，失败文件不会被计入“双引擎完整完成”数量。

## 文件说明

| 文件 | 用途 |
| --- | --- |
| `cma_dual_keyword_parallel.py` | 双引擎并行 OCR 主程序 |
| `cma_web_app_parallel.py` | 本地网页工作台 |
| `requirements.txt` | 固定版本依赖 |
| `01_install_environment.bat` | 安装或检查隔离环境 |
| `02_start_web_app.bat` | 启动网页工作台 |
| `03_run_ocr_console.bat` | 启动控制台模式 |
| `04_rebuild_results_only.bat` | 仅重建结果 |
| `CHANGELOG.md` | 版本升级记录 |
| `LICENSE.md` | 非商业许可证 |

## 性能说明

在 3 页纯扫描 PDF 的同条件小样本测试中，并行版完整用时由 41.74 秒降低到 20.92 秒，
两套引擎的命中数量和最终可信结果数量一致。小样本不代表所有电脑；实际速度受 CPU、
散热、PDF 页数、扫描尺寸和磁盘速度影响。4 核 CPU 的长任务通常预期缩短约 25%～45%。

## 许可证

本项目使用 [PolyForm Noncommercial License 1.0.0](LICENSE.md)。允许个人学习、研究、
测试、修改和其他非商业用途；商业部署、收费服务、转售或集成到营利性产品，需要事先
获得著作权人梁慧的书面授权。第三方组件仍分别适用其自身许可证。

