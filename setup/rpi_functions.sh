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
    for GROUP in $(groups ${CLONEUSER} | sed -e "s/^${CLONEUSER} : ${CLONEUSER} //"); do sudo adduser ${NEWUSER} ${GROUP} > /dev/null ; done
    if [ -f /etc/sudoers.d/010_${CLONEUSER}-nopasswd ]; then
      sudo cp /etc/sudoers.d/010_${CLONEUSER}-nopasswd /etc/sudoers.d/010_${NEWUSER}-nopasswd > /dev/null
      sudo chmod u+w /etc/sudoers.d/010_${NEWUSER}-nopasswd  > /dev/null
      sudo sed -i "s/${CLONEUSER}/${NEWUSER}/g" /etc/sudoers.d/010_${NEWUSER}-nopasswd > /dev/null
      sudo chmod u-w /etc/sudoers.d/010_${NEWUSER}-nopasswd > /dev/null
      #sudo cat /etc/sudoers.d/010_${NEWUSER}-nopasswd
    fi
  fi
}

function rpi_updates() {
  ## Install Updates
  #echo "Perform firmware update..."
  #sudo rpi-update
  echo "Installing Updates..."
  sudo apt-get update > /dev/null && sudo apt-get dist-upgrade -y > /dev/null
}


function rpi_set_timezone() {
  local TIMEZONE="${1:-America/Vancouver}"

  if [ ! -f "/usr/share/zoneinfo/$TIMEZONE" ]; then
    return 1;
  fi

  echo "Setting time zone to ${TIMEZONE}..."
  # Set timezone to America/New_York
  rm /etc/localtime
  #sudo cp /etc/timezone /etc/timezone.dist
  echo "${TIMEZONE}" > /etc/timezone
  sudo dpkg-reconfigure -f noninteractive tzdata  > /dev/null
}

function rpi_set_keyboard() {
  local KEYBOARD=${1:-us}

  # Set the keyboard to US, don't set any modifier keys, etc.
  echo "Setting Keyboard to ${KEYBOARD}..."
  sudo cp /etc/default/keyboard /etc/default/keyboard.dist
  sudo sed -i -e "/XKBLAYOUT=/s/gb/${KEYBOARD}/" /etc/default/keyboard
  sudo service keyboard-setup restart  > /dev/null
}

function rpi_change_hostname() {
  local NEW_HOSTNAME=${1}

  if [[ ! "$NEW_HOSTNAME" ]]; then
    echo "ERROR: rpi_change_hostname: New Hostname missing."
  else
    ## Change Host name
    echo "Changing hostname to ${NEW_HOSTNAME}..."
    CURRENT_HOSTNAME=`cat /etc/hostname | tr -d " \t\n\r"`
    echo $NEW_HOSTNAME > /etc/hostname
    sed -i "s/127.0.1.1.*$CURRENT_HOSTNAME/127.0.1.1\t$NEW_HOSTNAME/g" /etc/hosts
  fi
}

function rpi_set_locale() {
  local LOCALE="${1:-en_US.UTF-8}"

  ## Change locale
  #sudo cp /etc/locale.gen /etc/locale.gen.dist
  #sudo sed -i -e "s/^en_GB.UTF-8/\# en_GB.UTF-8/g" /etc/locale.gen
  #sudo sed -i -e "s/^\# ${LOCALE}/${LOCALE}/g" /etc/locale.gen
  #sudo locale-gen "${LOCALE}"

  if ! LOCALE_LINE="$(grep "^$LOCALE " /usr/share/i18n/SUPPORTED)"; then
    return 1
  fi

  echo "Changing locale to ${LOCALE}..."
  local ENCODING="$(echo $LOCALE_LINE | cut -f2 -d " ")"
  echo "$LOCALE $ENCODING" > /etc/locale.gen
  sed -i "s/^\s*LANG=\S*/LANG=$LOCALE/" /etc/default/locale
  dpkg-reconfigure -f noninteractive locales
}

function rpi_set_autologin() {
  local USER="${1:-pi}"

  echo "Setting auto login for user ${USER}..."
  systemctl set-default multi-user.target
  ln -fs /lib/systemd/system/getty@.service /etc/systemd/system/getty.target.wants/getty@tty1.service
  cat > /etc/systemd/system/getty@tty1.service.d/autologin.conf << EOF
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin $USER --noclear %I \$TERM
EOF
}
