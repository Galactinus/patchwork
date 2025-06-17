#!/bin/bash
#verify that we have one argument
if [ $# -ne 1 ]; then
    echo "Usage: $0 <patchwork.py>"
    exit 1
fi

INSTALL_EXE=$1

# Make virtual environment
python3 -m venv venv

# Activate virtual environment
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# write a script to run the patchwork.sh script
current_dir=$(pwd)
echo "#!/bin/bash" > patchwork.sh
echo "python_path=\"$current_dir/venv/bin/python\"" >> patchwork.sh
echo "source $current_dir/venv/bin/activate" >> patchwork.sh
echo "\$python_path $current_dir/patchwork.py \"\$@\"" >> patchwork.sh


# make the script executable
chmod +x patchwork.sh

ln -sf "$current_dir/patchwork.sh" "$INSTALL_EXE"

echo "Installed patchwork.sh to $INSTALL_EXE"