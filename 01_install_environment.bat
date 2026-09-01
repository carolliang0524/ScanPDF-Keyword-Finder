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

if not exist "%ENV_PY%" (
    echo [1/4] Creating isolated environment cma_ocr27_web...
    "%CONDA_EXE%" create -p "%ENV_DIR%" python=3.10 pip -y
    if errorlevel 1 goto :failed
) else (
    echo [1/4] Existing OCR environment will be reused.
)

echo.
echo [2/4] Updating pip inside the isolated environment...
"%ENV_PY%" -m pip install --upgrade "pip<25" -i "%INDEX_URL%"
if errorlevel 1 goto :failed

echo.
echo [3/4] Installing exact OCR and web dependencies...
"%ENV_PY%" -m pip install -r "%REQ_FILE%" -i "%INDEX_URL%"
if errorlevel 1 goto :failed

echo.
echo [4/4] Verifying imports and exact versions...
"%ENV_PY%" -c "import numpy,cv2,paddle,fitz,pytesseract,openpyxl,setuptools,streamlit; from paddleocr import PaddleOCR; import importlib.metadata as m; assert numpy.__version__=='1.23.5'; assert paddle.__version__=='2.6.2'; assert m.version('paddleocr')=='2.7.0.3'; assert m.version('streamlit')=='1.39.0'; print('Web environment check passed')"
if errorlevel 1 goto :failed

echo.
echo Installation completed. Run 02_start_web_app.bat or 03_run_ocr_console.bat next.
popd
pause
exit /b 0

:failed
echo.
echo [ERROR] OCR environment installation or verification failed.
echo Keep this window open and copy its complete output for diagnosis.
popd
pause
exit /b 1

