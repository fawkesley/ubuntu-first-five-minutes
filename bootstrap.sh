#!/bin/sh -eu

# Influenced by http://plusbryan.com/my-first-5-minutes-on-a-server-or-essential-security-for-linux-servers

THIS_SCRIPT="$0"
THIS_DIR="$(dirname $0)"

NORMAL_USER="paulfurley"
USER_HOME="/home/${NORMAL_USER}"

install_file() {
  DEST_FILE=$1
  SOURCE_FILE="${THIS_DIR}/skel/${DEST_FILE}"
  mkdir -p "$(dirname ${DEST_FILE})"
  cp "${SOURCE_FILE}" "${DEST_FILE}"
}

show_file_diff() {
  DEST_FILE=$1
  SOURCE_FILE="${THIS_DIR}/skel/${DEST_FILE}"

  if [ ! -f "$DEST_FILE" ]; then
      echo "${DEST_FILE} does not currently exist"
  else
      diff "${DEST_FILE}" "${SOURCE_FILE}" || true
  fi

}

check_root() {
  if [ "$(whoami)" != "root" ]; then
    echo "You need to run as root."
    exit 1
  fi
}

set_locale() {
  LOCALE="en_GB.UTF-8"
  if prompt_yes_no "Set locale to ${LOCALE}?" ; then
    locale-gen ${LOCALE}
    update-locale
  fi
}

apt_update() {
    apt-get update
}

install_etckeeper() {
    set -x
    git config --global user.email "etckeeper@paulfurley.com"
    git config --global user.name "Paul"

    apt install -y etckeeper
    set +x
}

prompt_yes_no() {
  while true; do
    read -p "$1 [y/n] " yesno

    if [ "$yesno" = "y" ]; then
      return 0

    elif [ "$yesno" = "n" ]; then
      return 1
    fi
  done
}

enable_automatic_upgrades() {
    set -x
    apt install -y unattended-upgrades
    install_file /etc/apt/apt.conf.d/20auto-upgrades
    install_file /etc/apt/apt.conf.d/50unattended-upgrades
    set +x
}

install_fail_2_ban() {
    set -x
    apt-get install -y fail2ban
    set +x
}

add_normal_user() {

  getent passwd "${NORMAL_USER}" > /dev/null 2>&1 && EXISTS=true || EXISTS=false

  if ! $EXISTS ; then
      if prompt_yes_no "Create user ${NORMAL_USER}?" ; then
          useradd --create-home --home-dir "${USER_HOME}" --shell /bin/bash "${NORMAL_USER}" --groups ssh,sudo
          echo
          echo "Set sudo password for ${NORMAL_USER}:"
          passwd "${NORMAL_USER}"
      fi
  fi

  getent passwd "${NORMAL_USER}" > /dev/null 2>&1 && EXISTS=true || EXISTS=false

  if $EXISTS ; then
      if prompt_yes_no "Overwrite authorized_keys for $NORMAL_USER?" ; then
          AUTHORIZED_KEYS="/home/${NORMAL_USER}/.ssh/authorized_keys"

          install_file "${AUTHORIZED_KEYS}"

          chmod 400 "${AUTHORIZED_KEYS}"
          chown -R "${NORMAL_USER}:${NORMAL_USER}" "${USER_HOME}"
      fi
  fi
}

configure_sudo() {
    SUDOERS_CONF=/etc/sudoers.d/allow-sudo-group.conf

    if [ ! -f  ]; then

        if prompt_yes_no "Install ${SUDOERS_CONF}?" ; then
            install_file ${SUDOERS_CONF}
        fi
    fi
}

lock_down_ssh() {
    SSHD_CONF="/etc/ssh/sshd_config"
    show_file_diff ${SSHD_CONF}

    if prompt_yes_no "Overwrite ${SSHD_CONF}?" ; then
        install_file ${SSHD_CONF}
        echo "Restarting sshd"
        service ssh restart
    fi
}

setup_firewall() {
  ALLOW_PORTS="22 80 443"

  if prompt_yes_no "Turn on Ubuntu firewall? (allow ports $ALLOW_PORTS)" ; then
      set -x
      ufw allow 22
      ufw allow 80
      ufw allow 443
      ufw enable
      set +x
  fi
}

install_useful_stuff() {
    PACKAGES="vim-tiny htop tree ack-grep psmisc"
    if prompt_yes_no "Install useful tools? (${PACKAGES})"; then
        apt install -y $PACKAGES
    fi
}

upgrade_packages() {
    apt-get upgrade -y
}


check_root
set_locale
apt_update
install_etckeeper
enable_automatic_upgrades
install_fail_2_ban
add_normal_user
configure_sudo
lock_down_ssh
setup_firewall
install_useful_stuff
upgrade_packages
