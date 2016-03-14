#!/bin/sh -eux

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

check_root() {
  if [ "$(whoami)" != "root" ]; then
    echo "You need to run as root."
    exit 1
  fi
}

update_system() {
  apt-get update
  apt-get upgrade -y
}

enable_automatic_upgrades() {
  install_file /etc/apt/apt.conf.d/20auto-upgrades
  install_file /etc/apt/apt.conf.d/50unattended-upgrades
}

install_fail_2_ban() {
  apt-get install -y fail2ban
}

add_normal_user() {

  getent passwd "${NORMAL_USER}" > /dev/null 2>&1 && EXISTS=true || EXISTS=false
  if ! $EXISTS ; then
    useradd --create-home --home-dir "${USER_HOME}" --shell /bin/bash "${NORMAL_USER}" --groups ssh,sudo
    echo
    echo "Set sudo password for ${NORMAL_USER}:"
    passwd "${NORMAL_USER}"
  fi

  AUTHORIZED_KEYS="/home/${NORMAL_USER}/.ssh/authorized_keys"

  install_file "${AUTHORIZED_KEYS}"

  chmod 400 "${AUTHORIZED_KEYS}"
  chown -R "${NORMAL_USER}:${NORMAL_USER}" "${USER_HOME}"
}

configure_sudo() {
  install_file /etc/sudoers
}

lock_down_ssh() {
  install_file /etc/ssh/sshd_config
  service ssh restart
}

setup_firewall() {
  ufw allow 22
  ufw allow 80
  ufw allow 443
  ufw enable
}

check_root
update_system
enable_automatic_upgrades
install_fail_2_ban
add_normal_user
configure_sudo
lock_down_ssh
setup_firewall

