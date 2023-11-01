#! /bin/bash

echo
echo ================================================================================
echo Renstar Global LLC - Generic Host Update Utility *nix Systems v1
echo ================================================================================
echo

sudo apt update && sudo apt upgrade -y && sudo apt autoremove
