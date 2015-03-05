#!/bin/sh

echo -e "\n\n\n" | ssh-keygen
tar cvf ssh-key.tar .ssh
