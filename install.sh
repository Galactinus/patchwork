#!/bin/bash


# Look for patchwork on the path, if not found, verify that we have one argument
if ! command -v patchwork &> /dev/null; then
    if [ $# -ne 1 ]; then
        echo "Usage: $0 <patchwork.py>"
        exit 1
    fi
    INSTALL_EXE=$1
else
    INSTALL_EXE="$(which patchwork)"
    echo installing to $INSTALL_EXE
fi

INSTALL_EXE=$1

# Make virtual environment
python3 -m venv venv

# Activate virtual environment
source venv/bin/activate

# Install dependencies
# pip install -r $current_dir/requirements.txt

# write a script to run the patchwork.sh script
current_dir=$(pwd)
echo "#!/bin/bash" > patchwork.sh
echo "python_path=\"$current_dir/venv/bin/python\"" >> patchwork.sh
echo "source $current_dir/venv/bin/activate" >> patchwork.sh
echo "\$python_path $current_dir/patchwork.py \"\$@\"" >> patchwork.sh


# make the script executable
chmod +x patchwork.sh

ln -sf "$current_dir/patchwork.sh" "$INSTALL_EXE"

# Install bash completion for user
USER_COMPLETION_DIR="$HOME/.local/share/bash-completion/completions"

# Create user completion directory if it doesn't exist
if [ ! -d "$USER_COMPLETION_DIR" ]; then
    echo "Creating user completion directory: $USER_COMPLETION_DIR"
    mkdir -p "$USER_COMPLETION_DIR"
fi

echo "Installing bash completion to $USER_COMPLETION_DIR"
cp "$current_dir/patchwork_completion.bash" "$USER_COMPLETION_DIR/patchwork.bash"

# Source the completion for immediate use
if [ -f "$current_dir/patchwork_completion.bash" ]; then
    echo "Sourcing bash completion for current session"
    source "$current_dir/patchwork_completion.bash"
fi

echo "Installed patchwork.sh to $INSTALL_EXE"
echo "Bash completion installed. You may need to restart your shell or run 'source ~/.bashrc' to enable autocomplete."