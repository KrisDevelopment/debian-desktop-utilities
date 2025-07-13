## Welcome

I highly recommend that you run add-to-path.sh and add the current directory to path. It will make life easier.


### Tips and tricks
- *fancontrol.sh* : If you soft-lock your system with wrong fan settings, enter emergency mode using init=/bin/bash in grub, then mount the fs in read-write mode (mount -o remount,rw / ) and edit the config file in /etc/nbfc/nbfc.json 

### Gaming related tools:
- *fixgamepad.sh* : Support for generic USB controllers if they happend not to work out of the box.
- *fancontrol.sh* : Fan speeds and temp stats
- *predator300.sh* : Predator specific hardware tools (rgb keyboard, turbo fan mode)
- *nvidia.sh* : some nvidia tools, show usage, set clock speeds.

### Gaming tips:
When running a game on a laptop with Nvidia GPU and you can't get it to render throug the dedicated GPU, launch the app with this:
```
__NV_PRIME_RENDER_OFFLOAD=1 __GLX_VENDOR_LIBRARY_NAME=nvidia
```
Or if you are doing it through Steam, add that same string in the launch params.
  
### Laptop tools:
- *update-power-mode.sh* : Update CPU clock speeds depending on the current power mode (Battery/AC). Supports some basic arguments check them with -h.


### Hardware info and control:
- *hardware-info.sh* : Full hardware info, CPU, GPU, RAM etc.
- *predator300.sh* : Turbo and neon keyboard for predator laptop
- *ls-devices* : Full list of disks and devices
- *disk-utiles* : Mount, unmount, format.
- *nvidia.sh* : Nvidia tools.
- *audo-select-pipewire/pulseaudio* : Select sound driver.