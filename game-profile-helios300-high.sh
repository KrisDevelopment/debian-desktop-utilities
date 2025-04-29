#!/bin/bash

echo $(dirname "$(readlink -f "$0")")
script_dir_arg=$(dirname "$(readlink -f "$0")")

bash $script_dir_arg/nvidia.sh --min-max 300 2000 
bash $script_dir_arg/update-power-mode.sh -m 3500
