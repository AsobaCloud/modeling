#! /bin/bash

docker run -d -p 8787:8787 -e DISPLAY=$DISPLAY \
        -e ROOT=TRUE -e PASSWORD=vbseut \
        -v /tmp/.X11-unix:/tmp/.X11-unix \
        ona-r_studio /init
