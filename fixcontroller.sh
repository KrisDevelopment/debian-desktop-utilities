#!/bin/bash
python3 -m venv venv
source venv/bin/activate
pip uninstall pyusb
pip install pyusb
echo "Running fixcontroller.py"
python3 fixcontroller.py
deactivate
            