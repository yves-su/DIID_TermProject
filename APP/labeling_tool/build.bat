@echo off
echo Starting Build Process...

:: Clean previous builds
if exist "build" rmdir /s /q "build"
if exist "dist" rmdir /s /q "dist"

:: Run PyInstaller
:: --onedir: Create a directory with exe and dependencies (easier to debug)
:: --windowed: No console window (GUI only)
:: --noconfirm: Do not ask for confirmation to overwrite
:: --clean: Clean cache
echo Running PyInstaller...
python -m PyInstaller --noconfirm --onedir --windowed --clean --name "SmartRacketLabeler" main.py

if %errorlevel% neq 0 (
    echo Build Failed!
    pause
    exit /b %errorlevel%
)

echo.
echo Build Successful!
echo Executable is located at: dist\SmartRacketLabeler\SmartRacketLabeler.exe
echo.
pause
