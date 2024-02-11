#!/bin/sh

while ! netstat -tuln | grep LISTEN | grep ':80 '; do sleep 1; done

# Turn on all nodes
tpi -p ons
