#! /bin/bash

echo
echo ================================================================================
echo Renstar Global LLC - Generic Host Package Installation Utility
echo ================================================================================
echo

echo Installing APT Packages... Please Wait.
echo

/usr/bin/sudo /usr/bin/apt update && /usr/bin/sudo /usr/bin/apt install neofetch lolcat fortune ncdu mc cowsay inxi ansiweather figlet eza  bat dust btop nala gping micro fd-find

echo
echo APT Package Installation Complete.
echo

echo Installing Config Files... Please Wait.

/usr/bin/sudo /usr/bin/cp ./zzzzzzzzzz_plan ~/.plan
/usr/bin/sudo /usr/bin/chown $(id -u):$(id -g) ~/.plan

/usr/bin/sudo /usr/bin/cp ./zzzzzzzzzz_bash_aliases ~/.bash_aliases
/usr/bin/sudo /usr/bin/chown $(id -u):$(id -g) ~/.bash_aliases

/usr/bin/sudo /usr/bin/cp ./zzzzzzzzzz_bash_logout ~/.bash_logout
/usr/bin/sudo /usr/bin/chown $(id -u):$(id -g) ~/.bash_logout

/usr/bin/sudo /usr/bin/cp ./zzzzzzzzzz_fortune.sh /etc/profile.d/zzzzzzzzzz_fortune.sh
/usr/bin/sudo /usr/bin/chmod 755 /etc/profile.d/zzzzzzzzzz_fortune.sh

echo Have a _____ day.
echo
