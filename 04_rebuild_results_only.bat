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
if not defined BASE_PY (
    echo [ERROR] Python was not found. Install Anaconda Python first.
    goto :failed
)
if not exist "%OCR_SCRIPT%" (
    echo [ERROR] OCR script was not found: %OCR_SCRIPT%
    goto :failed
)
echo This mode does not run OCR.
echo It rebuilds CSV and XLSX files from a saved .cma_ocr_resume folder.
"%BASE_PY%" "%OCR_SCRIPT%" --rebuild-results
set "RUN_EXIT=%ERRORLEVEL%"
if not "%RUN_EXIT%"=="0" goto :failed

echo.
echo Result rebuild completed successfully.
popd
pause
exit /b 0

:failed
echo.
echo [ERROR] No recoverable result was rebuilt.
echo Keep this window open and copy its complete output for diagnosis.
popd
pause
exit /b 1

