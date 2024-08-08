#!/usr/bin/env python3

import os
import sys

print("Usage: fixcontroller.py [--safe], or use the run.sh script") # safety mode to prevent infinite loop

# Gamepad USB fix
if len(sys.argv) == 1:
    # A shell script wrapper generation for externally managed environemnts (eg. deb12).
    if not os.path.exists("run.sh"):
        print ("First-time setup, creating ruh.sh shell script...")

        with open("run.sh", "w") as f:
            shell_src = """#!/bin/bash
    python3 -m venv venv
    source venv/bin/activate
    pip uninstall pyusb
    pip install pyusb
    echo "Running fixcontroller.py"
    python3 fixcontroller.py --safe
    deactivate
                """
            f.write(shell_src)
        os.chmod("run.sh", 0o755)
        print("Shell script created. Run it with ./run.sh")
        # run the shell script
        os.system("sudo ./run.sh")  # run the shell script
        exit()

    exit()

if sys.argv[1] == "--safe":
    try:
        import usb.core
        import usb.util
    except ImportError:
        print("First, install the pyusb module with PIP or your package manager.")
    else:
        if os.geteuid() != 0:
            print("You need to run this script with sudo")
            sys.exit()

        dev = usb.core.find(find_all=True)

        print("Fixing controller...")
        for d in dev:
            if d.idVendor == 0x045e and d.idProduct == 0x028e:
                d.ctrl_transfer(0xc1, 0x01, 0x0100, 0x00, 0x14)
                print("Controller fixed")
    finally:
        sys.exit()
