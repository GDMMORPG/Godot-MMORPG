#!/usr/bin/env bash

set -e

PYTHON_MIN_MAJOR=3
PYTHON_MIN_MINOR=12
VENV_DIR=".venv"
TRY_PYTHON_COMMANDS=("python3" "python" "py3" "py")

# Find a valid Python command
PYTHON_COMMAND=""
for cmd in "${TRY_PYTHON_COMMANDS[@]}"; do
	if command -v "$cmd" &> /dev/null; then
		PYTHON_COMMAND="$cmd"
		break
	fi
done

# Check if Python command was found
if [ -z "$PYTHON_COMMAND" ]; then
	echo "Python is not installed. Please install Python to proceed."
	exit 1
fi

# Verify Python version is 3x or higher
PYTHON_VERSION=$("$PYTHON_COMMAND" -c 'import sys; print(".".join(map(str, sys.version_info[:2])))')
IFS='.' read -r MAJOR MINOR <<< "$PYTHON_VERSION"
if [ "$MAJOR" -lt $PYTHON_MIN_MAJOR ] || { [ "$MAJOR" -eq $PYTHON_MIN_MAJOR ] && [ "$MINOR" -lt $PYTHON_MIN_MINOR ]; }; then
	echo "Python $PYTHON_MIN_MAJOR.$PYTHON_MIN_MINOR or higher is required. Detected version: $MAJOR.$MINOR"
	exit 1
fi
echo "Using Python version: $MAJOR.$MINOR"

# Create virtual environment if it doesn't exist for this platform.
if [ ! -f "$VENV_DIR/bin/python" ]; then
	echo "Creating virtual environment in $VENV_DIR (This may be slow for the first time)..."
	"$PYTHON_COMMAND" -m venv "$VENV_DIR" --upgrade-deps
else
	echo "Virtual environment already exists in $VENV_DIR."
fi

# Upgrade pip
"$VENV_DIR/bin/python" -m pip install --upgrade pip

# Install required Python packages
if [ -f "requirements.txt" ]; then
	echo "Installing required Python packages..."
	"$VENV_DIR/bin/pip" install -r requirements.txt
else
	echo "No requirements.txt file found. Skipping package installation."
fi

echo "Setup complete. Virtual environment is ready."
echo "To activate the virtual environment in the future, run: "
echo "source $VENV_DIR/bin/activate"