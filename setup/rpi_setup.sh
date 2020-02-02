#!/bin/bash

# Install Script to setup Raspberry Pi
# Runs updates, fixes the Locale
# Changes keyboard to US Layout
# Sets Timezone

TMZ="America/Vancouver"
LOCALE="en_US.UTF-8"

USE_POWERLINE="YES"

#Check if script is being run as root
if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

# Configure Pi
cd ~

echo "Change pi default password..."
sudo passwd pi

CURRENT_HOSTNAME="$(hostname --fqdn)"
[ -z "${CURRENT_HOSTNAME}" ] && CURRENT_HOSTNAME="$(uname -n)"

if [ ${CURRENT_HOSTNAME} == raspberrypi ]; then
  read -p "Enter new Hostname: " HOSTNAME
  # bail out if blank
  [ -z $HOSTNAME ] && echo "Aborting because no hostname provided" && exit 1

else
  HOSTNAME="${CURRENT_HOSTNAME}"
fi

read -p "Enter username to replace 'pi': " NEWUSER
# bail out if blank
[ -z $NEWUSER ] && echo "Aborting because no name provided" && exit 1

wget --output-document=rpi_functions.sh --quiet https://raw.githubusercontent.com/rodneyshupe/RPi_Utilities/master/setup/rpi_functions.sh && source rpi_functions.sh

## Add new user and lock Pi User
rpi_change_hostname "${HOSTNAME}"
rpi_clone_user ${NEWUSER}
rpi_updates
rpi_install_essentials
rpi_set_timezone "${TMZ}"
rpi_set_keyboard "us"
if [ "$USE_POWERLINE" = "YES" ]; then
  rpi_install_powerline_prompt "/home/$NEWUSER"
else
  rpi_enhance_prompt "/home/$NEWUSER"
fi
rpi_install_login_notifications
rpi_set_locale "${LOCALE}"

echo "Reboot to complete inital setup."
