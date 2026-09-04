@echo off
setlocal EnableExtensions
chcp 65001 >nul
set "PYTHONUTF8=1"
set "PYTHONIOENCODING=utf-8"
pushd "%~dp0"

set "BASE_PY="
if defined CMA_BOOTSTRAP_PY if exist "%CMA_BOOTSTRAP_PY%" set "BASE_PY=%CMA_BOOTSTRAP_PY%"
for %%P in ("%USERPROFILE%\anaconda3\python.exe" "%USERPROFILE%\miniconda3\python.exe" "%ProgramData%\anaconda3\python.exe" "%ProgramData%\miniconda3\python.exe") do (
    if not defined BASE_PY if exist "%%~fP" set "BASE_PY=%%~fP"
)
if not defined BASE_PY (
    for /f "delims=" %%P in ('where python 2^>nul') do (
        if not defined BASE_PY set "BASE_PY=%%P"
    )
)

if not defined BASE_PY (
    echo [ERROR] Python was not found. Install Anaconda Python first.
    goto :failed
)
for %%I in ("%BASE_PY%") do set "CONDA_ROOT=%%~dpI"
set "CONDA_EXE=%CONDA_ROOT%Scripts\conda.exe"
set "ENV_DIR=%CONDA_ROOT%envs\cma_ocr27_web"
set "ENV_PY=%ENV_DIR%\python.exe"
set "REQ_FILE=%~dp0requirements.txt"
set "OCR_SCRIPT=%~dp0cma_dual_keyword_parallel.py"
set "INDEX_URL=%CMA_PIP_INDEX_URL%"
if not defined INDEX_URL set "INDEX_URL=%PIP_INDEX_URL%"
if not defined INDEX_URL set "INDEX_URL=https://pypi.org/simple"

if not exist "%CONDA_EXE%" (
    echo [ERROR] Conda was not found: %CONDA_EXE%
    goto :failed
)
if not exist "%REQ_FILE%" (
    echo [ERROR] Requirements file was not found: %REQ_FILE%
    goto :failed
)
if not exist "%OCR_SCRIPT%" (
    echo [ERROR] OCR script was not found: %OCR_SCRIPT%
    goto :failed
)

if not exist "%ENV_PY%" (
    echo [1/5] Creating isolated environment cma_ocr27_web...
    "%CONDA_EXE%" create -p "%ENV_DIR%" python=3.10 pip -y
    if errorlevel 1 goto :failed
) else (
    echo [1/5] Existing OCR environment will be reused.
)

echo.
echo [2/5] Updating pip inside the isolated environment...
"%ENV_PY%" -m pip install --upgrade "pip<25" -i "%INDEX_URL%"
if errorlevel 1 goto :failed

echo.
echo [3/5] Installing exact OCR dependencies into the shared isolated environment...
"%ENV_PY%" -m pip install -r "%REQ_FILE%" -i "%INDEX_URL%"
if errorlevel 1 goto :failed

echo.
echo [4/5] Verifying imports and exact versions...
"%ENV_PY%" -c "import numpy,cv2,paddle,fitz,pytesseract,openpyxl,setuptools,streamlit; from paddleocr import PaddleOCR; import importlib.metadata as m; assert numpy.__version__=='1.23.5'; assert paddle.__version__=='2.6.2'; assert m.version('paddleocr')=='2.7.0.3'; assert m.version('streamlit')=='1.39.0'; print('Web environment check passed')"
if errorlevel 1 goto :failed

echo.
echo [5/5] Verifying the external Tesseract engine and chi_sim+eng language data...
"%ENV_PY%" "%OCR_SCRIPT%" --check-env-only
if errorlevel 1 goto :tesseract_missing

echo.
echo Installation completed.
echo Run 02_start_web_app.bat for the web dashboard,
echo or 03_run_ocr_console.bat for the console-only mode.
popd
pause
exit /b 0

:tesseract_missing
echo.
echo [ERROR] Python dependencies are ready, but the external Tesseract engine
echo or its chi_sim+eng language data is missing. Do not start a dual-engine job yet.
echo Install Tesseract or place a portable copy in .\Tesseract-OCR\tesseract.exe,
echo then run 01_install_environment.bat again.
popd
pause
exit /b 1

:failed
echo.
echo [ERROR] OCR environment installation or verification failed.
echo Keep this window open and copy its complete output for diagnosis.
popd
pause
exit /b 1
