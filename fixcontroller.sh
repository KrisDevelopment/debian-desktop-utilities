#!/bin/bash
python3 -m venv venv
source venv/bin/activate

install_deps() {
    echo "Installing dependencies..."
    pip uninstall pyusb
    pip install pyusb
    echo "Dependencies installed."
}

# run the py script with --checkdeps flag to check for missing dependencies and install
python3 fixcontroller.py --checkdeps || install_deps

echo "Running fixcontroller.py"
python3 fixcontroller.py --safe
deactivate
