## Welcome

I highly recommend that you run add-to-path.sh and add the current directory to path. It will make life easier.


### Tips and tricks
- *fancontrol.sh* : If you soft-lock your system with wrong fan settings, enter emergency mode using init=/bin/bash in grub, then mount the fs in read-write mode (mount -o remount,rw / ) and edit the config file in /etc/nbfc/nbfc.json 

### Gaming related tools:
- *fixgamepad.sh* : Support for generic USB controllers if they happend not to work out of the box.
- *fancontrol.sh* : Fan speeds and temp stats
- *predator300.sh* : Predator specific hardware tools (rgb keyboard, turbo fan mode)
- *nvidia.sh* : some nvidia tools, show usage, set clock speeds.
  
### Laptop tools:
- *update-power-mode.sh* : Update CPU clock speeds depending on the current power mode (Battery/AC). Supports some basic arguments check them with -h.
