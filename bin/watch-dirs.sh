#!/bin/bash

# XXX Provide a stop script too.

# XXX Allow these to be configurable.  Perhaps
# `--hostdir=...`
# `--guestdir=...`
# `--projects=...`
hostbasedir="${HOME}/code"
guestbasedir="/code"
projects=(
    flight-console-webapp
    flight-desktop-webapp
    flight-file-manager/client
    flight-job-script-service/client
    flight-landing-page/landing-page
    flight-webapp-components
)

for project in "${projects[@]}" ; do
    ~/.vagrant.d/tmp/notify-forwarder_linux_x64 watch \
        -c 127.0.0.1:22020 \
        "${hostbasedir}"/"${project}" "${guestbasedir}"/"${project}" &
done
