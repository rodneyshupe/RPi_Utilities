#!/bin/bash

function rpi_clone_user() {
  local NEWUSER=$1
  local CLONEUSER=${2:-pi}

  if [[ ! "$NEWUSER" ]]; then
    echo "ERROR: rpi_clone_user: New username missing."
  else
    ## Add new user and lock Pi User
    echo "Adding user $NEWUSER..."
    echo "  Please enter the following information:"
    sudo adduser ${NEWUSER}
    for GROUP in $(groups ${CLONEUSER} | sed -e "s/^${CLONEUSER} : ${CLONEUSER} //"); do sudo adduser ${NEWUSER} ${GROUP}; done
    if [ -f /etc/sudoers.d/010_${CLONEUSER}-nopasswd ]; then
      sudo cp /etc/sudoers.d/010_${CLONEUSER}-nopasswd /etc/sudoers.d/010_${NEWUSER}-nopasswd
      sudo chmod u+w /etc/sudoers.d/010_${NEWUSER}-nopasswd
      sudo sed -i "s/${CLONEUSER}/${NEWUSER}/g" /etc/sudoers.d/010_${NEWUSER}-nopasswd
      sudo chmod u-w /etc/sudoers.d/010_${NEWUSER}-nopasswd
      #sudo cat /etc/sudoers.d/010_${NEWUSER}-nopasswd
    fi
  fi
}

functin rpi_updates() {
  ## Install Updates
  echo "Installing Updates..."
  sudo apt-get update && sudo apt-get dist-upgrade -y
}


function rpi_set_timezone() {
  local TMZ=${1:-America/Vancouver}

  # Set timezone to America/New_York
  sudo cp /etc/timezone /etc/timezone.dist
  echo "${TMZ}" > /etc/timezone
  sudo dpkg-reconfigure -f noninteractive tzdata
}

function rpi_set_keyboard() {
  local KEYBOARD=${1:-us}

  # Set the keyboard to US, don't set any modifier keys, etc.
  sudo cp /etc/default/keyboard /etc/default/keyboard.dist
  sudo sed -i -e "/XKBLAYOUT=/s/gb/${KEYBOARD}/" /etc/default/keyboard
  sudo service keyboard-setup restart
}

function rpi_change_hostname() {
  local HOSTNAME=${1}

  if [[ ! "$NEWUSER" ]]; then
    echo "ERROR: rpi_clone_user: New username missing."
  else
    ## Change Host name
    sudo raspi-config nonint do_hostname ${HOSTNAME}
  fi
}

function rpi_set_locale() {
  local LOCALE=${1:-en_US.UTF-8}

  ## Change locale
  sudo cp /etc/locale.gen /etc/locale.gen.dist
  sudo sed -i -e "s/^en_GB.UTF-8/\# en_GB.UTF-8/g" /etc/locale.gen
  sudo sed -i -e "s/^\# ${LOCALE}/${LOCALE}/g" /etc/locale.gen
  sudo locale-gen "${LOCALE}"
}
