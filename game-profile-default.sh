#!/bin/bash

echo $(dirname "$(readlink -f "$0")")
script_dir_arg=$(dirname "$(readlink -f "$0")")

bash $script_dir_arg/nvidia.sh --reset
bash $script_dir_arg/update-power-mode.sh