#! /bin/bash

#Enabling X11 forwarding
XAUTH=$HOME/.Xauthority
touch $XAUTH

docker run -d  \
        --tty --interactive -p 8787:8787 \
        --env DISPLAY=$DISPLAY --volume $XAUTH:/root/.Xauthority \
        -e ROOT=TRUE -e PASSWORD=vbseut \
        ona-r_studio /init


#still working through proper syntax
#using --network=host results in r-studio not being found on any port
