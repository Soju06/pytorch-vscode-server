#!/bin/bash

echo "${SSH_PUBLIC_KEY}" > ~/.ssh/authorized_keys

if [ ! -z "$SSH_PUBLIC_KEY" ]; then
    sudo service ssh start;
fi

dumb-init "$@"