@echo off
setlocal enabledelayedexpansion

set VENV_DIR=.venv

REM Check if Python is installed
python --version >nul 2>&1
if errorlevel 1 (
	echo Python is not installed. Please install Python to proceed.
	exit /b 1
)

REM Check if virtual environment exists
if not exist "%VENV_DIR%/Scripts/python.exe" (
	echo Creating virtual environment in %VENV_DIR%...
	python -m venv "%VENV_DIR%"
) else (
	echo Virtual environment already exists in %VENV_DIR%.
)

REM Upgrade pip
%VENV_DIR%\Scripts\python.exe -m pip install --upgrade pip

REM Install required Python packages
if exist "requirements.txt" (
	echo Installing required Python packages...
	%VENV_DIR%\Scripts\pip install -r requirements.txt
) else (
	echo No requirements.txt file found. Skipping package installation.
)


echo Setup complete. Virtual environment is ready.
