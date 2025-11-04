@echo off

if not defined PROJECT_PATH (
    set PROJECT_PATH=%CD%\project\game
)

set VERSION=4.5-stable
set DOWNLOAD_URL=https://github.com/godotengine/godot-builds/releases/download/%VERSION%/Godot_v%VERSION%_win64.exe.zip
set UNZIP_DIR=%APPDATA%\godot\editors\%VERSION%

REM Create the target directory if it doesn't exist
if not exist %UNZIP_DIR% mkdir %UNZIP_DIR%

REM Check if the executable already exists
if not exist %UNZIP_DIR%\Godot_v%VERSION%_win64.exe (
    pushd %UNZIP_DIR%
    REM Download the Godot editor zip file
    curl -L -o godot-editor.zip %DOWNLOAD_URL%
	if errorlevel 1 (
		echo "Failed to download the Godot editor"
		pause
		exit /b 1
	)

    REM Unzip the downloaded file into the target directory
    powershell -Command "Expand-Archive -Path godot-editor.zip -DestinationPath ."
	if errorlevel 1 (
		echo "Failed to unzip the Godot editor"
		pause
		exit /b 1
	)

    if not exist %UNZIP_DIR%\Godot_v%VERSION%_win64.exe (
        echo "Godot executable not found after unzipping"
        pause
        exit /b 1
    )

    REM Clean up the downloaded zip file
    del godot-editor.zip
    popd
)

:SetupProject
if not exist %PROJECT_PATH% mkdir %PROJECT_PATH%
if not exist %PROJECT_PATH%\project.godot (
    echo "Creating new Godot project at %PROJECT_PATH%"
    "%UNZIP_DIR%\Godot_v%VERSION%_win64.exe" --project-manager
    if errorlevel 1 (
        echo "Failed to open the Godot Project Manager"
        pause
        exit /b 1
    )
    echo "Waiting until the project is created..."
    :WaitForProjectCreation
    timeout /t 5 /nobreak >nul
    if not exist %PROJECT_PATH%\project.godot goto WaitForProjectCreation
    echo "Godot project created successfully."
)

REM Prompt the user to choose between console or regular executable
choice /C YN /M "Do you want to open the Godot Editor in Console Mode?"

REM Open the chosen executable
if errorlevel 2 (
    echo "Disable Console Mode..."
    start "" "%UNZIP_DIR%\Godot_v%VERSION%_win64.exe" --editor --path "%PROJECT_PATH%"
) else (
    echo "Enable Console Mode..."
    "%UNZIP_DIR%\Godot_v%VERSION%_win64_console.exe" -v -d --editor --path "%PROJECT_PATH%"
    if not errorlevel 0 pause
)

exit /b 0