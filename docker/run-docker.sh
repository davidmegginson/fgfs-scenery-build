#!/bin/bash
# DO NOT RUN AS SUDO!

UID=$(id -u)
GID=$(id -g)

docker run -u $UID:$GID -i -v /media/david/Storage/fgfs-scenery:/terragear-work/ -t flightgear/terragear:ws20 /bin/bash
