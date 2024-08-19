#!/bin/sh

# /etc/init.d/S99zallnodeson.sh
# chmod +x /etc/init.d/S99zallnodeson.sh

while ! netstat -tuln | grep LISTEN | grep ':80 '; do sleep 1; done

# Turn on all nodes
tpi -p on
