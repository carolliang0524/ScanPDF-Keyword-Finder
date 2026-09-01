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

set "OCR_SCRIPT=%~dp0cma_dual_keyword_enhanced.py"
set "WEB_APP=%~dp0cma_web_app.py"
if not defined BASE_PY (
    echo [ERROR] Python was not found. Install Anaconda Python first.
    goto :failed
)
if not exist "%OCR_SCRIPT%" (
    echo [ERROR] OCR script was not found: %OCR_SCRIPT%
    goto :failed
)
if not exist "%WEB_APP%" (
    echo [ERROR] Web app was not found: %WEB_APP%
    goto :failed
)
echo [1/2] Checking the independent web OCR environment...
"%BASE_PY%" "%OCR_SCRIPT%" --check-env-only
if errorlevel 1 goto :failed

for %%I in ("%BASE_PY%") do set "CONDA_ROOT=%%~dpI"
set "WEB_PY=%CONDA_ROOT%envs\cma_ocr27_web\python.exe"
if not exist "%WEB_PY%" (
    echo [ERROR] Web environment Python was not found: %WEB_PY%
    goto :failed
)

echo.
echo [2/2] Starting the local web page. Keep this window open.
echo Browser address: http://127.0.0.1:8501
echo Closing the browser tab does not stop OCR. Closing this window does.
"%WEB_PY%" -m streamlit run "%WEB_APP%" --server.address 127.0.0.1 --server.port 8501 --browser.gatherUsageStats false
set "RUN_EXIT=%ERRORLEVEL%"
if not "%RUN_EXIT%"=="0" goto :failed

popd
pause
exit /b 0

:failed
echo.
echo [ERROR] The local web OCR page could not be started.
echo Keep this window open and copy its complete output for diagnosis.
popd
pause
exit /b 1

