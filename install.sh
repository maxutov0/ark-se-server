#!/bin/bash

# adduser ark

sudo apt-get update
sudo apt-get upgrade
sudo apt-get install lib32gcc-s1

sudo add-apt-repository multiverse; sudo dpkg --add-architecture i386; sudo apt update
sudo apt install steamcmd

steamcmd +force_install_dir /home/ark/ark-se-server +login anonymous +app_update 376030 +quit
