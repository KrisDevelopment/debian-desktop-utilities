##Welcome

I highly recommend that you run add-to-path.sh and add the current directory to path. It will make life easier.


### Tips and tricks
- *fancontrol* : If you soft-lock your system with wrong fan settings, enter emergency mode using init=/bin/bash in grub, then mount the fs in read-write mode (mount -o remount,rw / ) and edit the config file in /etc/nbfc/nbfc.json 