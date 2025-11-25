#!/usr/bin/env bash
#
# setup.sh - Provision a lightweight Debian 13 remote development
# workstation with XFCE, XRDP, and a full web/dev toolchain.

set -euo pipefail
umask 022
export DEBIAN_FRONTEND=noninteractive

log_info()    { echo -e "[INFO] $*"; }
log_success() { echo -e "[SUCCESS] $*"; }
log_error()   { echo -e "[ERROR] $*" >&2; }

handle_error() {
  log_error "Provisioning aborted at line ${BASH_LINENO[0]} while running '${BASH_COMMAND}'."
  exit 1
}
trap handle_error ERR

if [[ "${EUID}" -ne 0 ]]; then
  log_error "Run this script as root."
  exit 1
fi

DEV_USER="${DEV_USER:-developer}"
DEV_PASS="${DEV_USER_PASSWORD:-DevPass123!}"
if [[ "${DEV_USER}" == "root" ]]; then
  log_error "DEV_USER cannot be root."
  exit 1
fi

SERVER_HOSTNAME="${SERVER_HOSTNAME:-dev-workstation}"
ALLOW_PASSWORD_AUTH="${ALLOW_PASSWORD_AUTH:-false}"
DEV_USER_SSH_KEY="${DEV_USER_SSH_KEY:-}"
ENABLE_WIREGUARD="${ENABLE_WIREGUARD:-true}"
WG_INTERFACE_ADDRESS="${WG_INTERFACE_ADDRESS:-10.8.0.1/24}"
WG_PORT="${WG_PORT:-51820}"
WG_ALLOWED_IPS="${WG_ALLOWED_IPS:-10.8.0.0/24}"
WG_PUBLIC_INTERFACE="${WG_PUBLIC_INTERFACE:-eth0}"

SWAPFILE="/swapfile"
NVM_DIR="/usr/local/nvm"
FONT_NAME="Hack"
FONT_URL="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/${FONT_NAME}.zip"
CURSOR_URL="https://downloader.cursor.sh/linux/appImage/x64"
CURSOR_DIR="/opt/cursor"
CURSOR_BIN="${CURSOR_DIR}/Cursor.AppImage"
APT_KEYRING_DIR="/etc/apt/keyrings"
ARCH="$(dpkg --print-architecture)"
CURL_OPTS=(--fail --location --silent --show-error --retry 3)

get_codename() {
  . /etc/os-release
  echo "${VERSION_CODENAME:-bookworm}"
}
CODENAME="$(get_codename)"
case "${CODENAME}" in
  trixie|bookworm) ;;
  *) CODENAME="bookworm" ;;
esac

install -d -m 0755 "${APT_KEYRING_DIR}"

APT_OPTS=(-y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold")

update_system() {
  log_info "Updating package index and upgrading base system..."
  apt-get update
  apt-get upgrade "${APT_OPTS[@]}"
  log_success "System packages updated."
}

install_essential_packages() {
  log_info "Installing baseline utilities..."
  local packages=(
    curl wget git htop ufw software-properties-common build-essential unzip
    ca-certificates gnupg lsb-release apt-transport-https xdg-utils fontconfig
    libfuse2 fuse3 dbus-x11 locales tar desktop-file-utils
  )
  apt-get install "${APT_OPTS[@]}" --no-install-recommends "${packages[@]}"
  log_success "Essential utilities installed."
}

configure_locale() {
  log_info "Ensuring en_US.UTF-8 locale is available..."
  if ! grep -q '^en_US.UTF-8 UTF-8' /etc/locale.gen; then
    echo 'en_US.UTF-8 UTF-8' >> /etc/locale.gen
  fi
  sed -i 's/^# *\(en_US.UTF-8 UTF-8\)/\1/' /etc/locale.gen
  locale-gen en_US.UTF-8
  update-locale LANG=en_US.UTF-8
  log_success "Locale configured."
}

configure_swap() {
  log_info "Configuring 4G swap space..."
  if grep -q "${SWAPFILE}" /proc/swaps; then
    log_info "Swap file already active."
    return
  fi
  if [[ -f "${SWAPFILE}" ]]; then
    swapoff "${SWAPFILE}" || true
    rm -f "${SWAPFILE}"
  fi
  dd if=/dev/zero of="${SWAPFILE}" bs=1M count=4096 status=progress
  chmod 600 "${SWAPFILE}"
  mkswap "${SWAPFILE}"
  swapon "${SWAPFILE}"
  if ! grep -q "${SWAPFILE}" /etc/fstab; then
    echo "${SWAPFILE} none swap sw 0 0" >> /etc/fstab
  fi
  cat <<'EOF' >/etc/sysctl.d/60-swap.conf
vm.swappiness=10
vm.vfs_cache_pressure=50
EOF
  sysctl -p /etc/sysctl.d/60-swap.conf >/dev/null
  log_success "Swap configured."
}

configure_firewall() {
  log_info "Configuring UFW firewall..."
  ufw --force reset || true
  ufw default deny incoming
  ufw default allow outgoing
  ufw allow 22/tcp
  ufw allow 3389/tcp
  if [[ "${ENABLE_WIREGUARD}" == "true" ]]; then
    ufw allow "${WG_PORT}"/udp
  fi
  ufw --force enable
  log_success "Firewall rules applied (ports 22 & 3389 open)."
}

set_hostname() {
  if [[ -n "${SERVER_HOSTNAME}" ]]; then
    log_info "Setting hostname to ${SERVER_HOSTNAME}..."
    hostnamectl set-hostname "${SERVER_HOSTNAME}"
    log_success "Hostname set."
  fi
}

secure_ssh() {
  log_info "Hardening SSH daemon..."
  install -d /etc/ssh/sshd_config.d
  cat <<EOF >/etc/ssh/sshd_config.d/99-hardening.conf
PermitRootLogin no
PasswordAuthentication $( [[ "${ALLOW_PASSWORD_AUTH}" == "true" ]] && echo yes || echo no )
ChallengeResponseAuthentication no
KbdInteractiveAuthentication no
X11Forwarding no
ClientAliveInterval 300
ClientAliveCountMax 2
EOF
  systemctl reload sshd
  log_success "SSHD hardened (PasswordAuthentication=${ALLOW_PASSWORD_AUTH})."
}

create_dev_user() {
  log_info "Creating developer user '${DEV_USER}'..."
  if id -u "${DEV_USER}" >/dev/null 2>&1; then
    log_info "User '${DEV_USER}' already exists."
  else
    adduser --disabled-password --gecos "" "${DEV_USER}"
    printf '%s:%s\n' "${DEV_USER}" "${DEV_PASS}" | chpasswd
  fi
  usermod -aG sudo "${DEV_USER}"
  cat <<EOF >/etc/sudoers.d/90-${DEV_USER}
${DEV_USER} ALL=(ALL) NOPASSWD:ALL
EOF
  chmod 440 /etc/sudoers.d/90-"${DEV_USER}"
  if [[ -n "${DEV_USER_SSH_KEY}" ]]; then
    log_info "Installing provided SSH key for ${DEV_USER}..."
    local user_home
    user_home="$(eval echo ~"${DEV_USER}")"
    install -d -m 700 -o "${DEV_USER}" -g "${DEV_USER}" "${user_home}/.ssh"
    if ! grep -qxF "${DEV_USER_SSH_KEY}" "${user_home}/.ssh/authorized_keys" 2>/dev/null; then
      printf '%s\n' "${DEV_USER_SSH_KEY}" >> "${user_home}/.ssh/authorized_keys"
    fi
    chown "${DEV_USER}:${DEV_USER}" "${user_home}/.ssh/authorized_keys"
    chmod 600 "${user_home}/.ssh/authorized_keys"
  fi
  log_success "User '${DEV_USER}' ready with sudo privileges."
}

ensure_dev_user_xsession() {
  local user_home
  user_home="$(eval echo ~"${DEV_USER}")"
  if [[ ! -f "${user_home}/.xsession" ]]; then
    cat <<'EOF' > "${user_home}/.xsession"
startxfce4
EOF
    chown "${DEV_USER}:${DEV_USER}" "${user_home}/.xsession"
    chmod 644 "${user_home}/.xsession"
  fi
}

install_gui_stack() {
  log_info "Installing XFCE4 desktop and XRDP server..."
  apt-get install "${APT_OPTS[@]}" xfce4 xfce4-goodies xrdp
  adduser xrdp ssl-cert
  cat <<'EOF' >/etc/xrdp/startwm.sh
#!/bin/sh
unset DBUS_SESSION_BUS_ADDRESS
unset XDG_RUNTIME_DIR
export LANG=en_US.UTF-8
exec startxfce4
EOF
  chmod +x /etc/xrdp/startwm.sh
  sed -i 's/^port=.*/port=3389/' /etc/xrdp/xrdp.ini
  systemctl enable xrdp --now
  ensure_dev_user_xsession
  log_success "XFCE4 + XRDP configured."
}

install_nvm_node_stack() {
  log_info "Installing nvm and Node.js LTS toolchain..."
  if [[ ! -d "${NVM_DIR}/.git" ]]; then
    rm -rf "${NVM_DIR}"
    git clone https://github.com/nvm-sh/nvm.git "${NVM_DIR}"
  fi
  git -C "${NVM_DIR}" fetch --tags --quiet
  local latest_tag
  latest_tag="$(git -C "${NVM_DIR}" describe --abbrev=0 --tags 2>/dev/null || true)"
  if [[ -n "${latest_tag}" ]]; then
    git -C "${NVM_DIR}" checkout --quiet "${latest_tag}"
  fi
  cat <<'EOF' >/etc/profile.d/nvm.sh
export NVM_DIR="/usr/local/nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"
EOF
  chmod 644 /etc/profile.d/nvm.sh
  # shellcheck disable=SC1091
  . /etc/profile.d/nvm.sh
  nvm install --lts
  nvm alias default 'lts/*'
  nvm use default
  npm install -g yarn pnpm typescript ts-node
  log_success "Node.js, npm, yarn, pnpm, TypeScript, and ts-node installed."
}

install_python_stack() {
  log_info "Installing Python tooling..."
  apt-get install "${APT_OPTS[@]}" python3 python3-pip python3-venv
  log_success "Python 3 ecosystem ready."
}

install_docker_stack() {
  log_info "Installing Docker Engine & Compose..."
  curl "${CURL_OPTS[@]}" https://download.docker.com/linux/debian/gpg | gpg --dearmor -o "${APT_KEYRING_DIR}/docker.gpg"
  echo "deb [arch=${ARCH} signed-by=${APT_KEYRING_DIR}/docker.gpg] https://download.docker.com/linux/debian ${CODENAME} stable" >/etc/apt/sources.list.d/docker.list
  apt-get update
  apt-get install "${APT_OPTS[@]}" docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  systemctl enable docker --now
  groupadd -f docker
  usermod -aG docker "${DEV_USER}"
  log_success "Docker & Compose installed; user added to docker group."
}

install_vscode() {
  log_info "Installing Visual Studio Code..."
  curl "${CURL_OPTS[@]}" https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor -o "${APT_KEYRING_DIR}/packages.microsoft.gpg"
  echo "deb [arch=${ARCH} signed-by=${APT_KEYRING_DIR}/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" >/etc/apt/sources.list.d/vscode.list
  apt-get update
  apt-get install "${APT_OPTS[@]}" code
  log_success "VS Code installed via official repository."
}

install_cursor() {
  log_info "Installing Cursor AppImage system-wide..."
  local tmp_appimage
  tmp_appimage="$(mktemp)"
  curl "${CURL_OPTS[@]}" "${CURSOR_URL}" -o "${tmp_appimage}"
  install -Dm755 "${tmp_appimage}" "${CURSOR_BIN}"
  ln -sf "${CURSOR_BIN}" /usr/local/bin/cursor
  cat <<EOF >/usr/share/applications/cursor.desktop
[Desktop Entry]
Name=Cursor
Comment=Cursor AI Editor
Exec=${CURSOR_BIN}
Icon=code
Terminal=false
Type=Application
Categories=Development;IDE;
EOF
  chmod 644 /usr/share/applications/cursor.desktop
  if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database >/dev/null 2>&1 || true
  fi
  rm -f "${tmp_appimage}"
  log_success "Cursor installed with desktop entry."
}

install_browser() {
  log_info "Installing web browsers (Firefox ESR & Chromium)..."
  apt-get install "${APT_OPTS[@]}" --no-install-recommends firefox-esr chromium
  log_success "Browsers installed and ready."
}

install_fail2ban() {
  log_info "Installing and configuring Fail2Ban..."
  apt-get install "${APT_OPTS[@]}" fail2ban
  cat <<'EOF' >/etc/fail2ban/jail.d/ssh-xrdp.conf
[sshd]
enabled = true
port    = ssh
filter  = sshd
logpath = /var/log/auth.log
maxretry = 5
bantime = 1h

[xrdp]
enabled = true
port    = 3389
filter  = xrdp
logpath = /var/log/xrdp.log
maxretry = 5
bantime = 1h

[xrdp-sesman]
enabled = true
port    = 3350
filter  = xrdp-sesman
logpath = /var/log/xrdp-sesman.log
maxretry = 5
bantime = 1h
EOF
  install -d -m 755 /etc/fail2ban/filter.d
  cat <<'EOF' >/etc/fail2ban/filter.d/xrdp.conf
[Definition]
failregex = .* connection problem, giving up\b
            .* login failed for user .*
ignoreregex =
EOF
  cat <<'EOF' >/etc/fail2ban/filter.d/xrdp-sesman.conf
[Definition]
failregex = .* login failed for user .*
ignoreregex =
EOF
  systemctl enable fail2ban --now
  log_success "Fail2Ban enabled for SSH and XRDP."
}

install_shell_stack() {
  log_info "Installing Zsh and Oh My Zsh..."
  apt-get install "${APT_OPTS[@]}" zsh
  local zsh_path
  zsh_path="$(command -v zsh)"
  chsh -s "${zsh_path}" root
  chsh -s "${zsh_path}" "${DEV_USER}"
  local user_home
  user_home="$(eval echo ~"${DEV_USER}")"
  if [[ ! -d "${user_home}/.oh-my-zsh" ]]; then
    local installer="/tmp/ohmyzsh-install.sh"
    curl "${CURL_OPTS[@]}" https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh -o "${installer}"
    chmod +x "${installer}"
    su - "${DEV_USER}" -c "RUNZSH=no CHSH=no KEEP_ZSHRC=yes ${installer}"
    rm -f "${installer}"
  fi
  if [[ -f "${user_home}/.zshrc" ]]; then
    su - "${DEV_USER}" -c "sed -i 's|^ZSH_THEME=.*|ZSH_THEME=\"robbyrussell\"|' ~/.zshrc"
  fi
  log_success "Zsh set as default shell with Oh My Zsh."
}

install_nerd_font() {
  log_info "Installing ${FONT_NAME} Nerd Font..."
  local font_tmp
  font_tmp="$(mktemp -d)"
  curl "${CURL_OPTS[@]}" "${FONT_URL}" -o "${font_tmp}/${FONT_NAME}.zip"
  local font_dir="/usr/local/share/fonts/${FONT_NAME}Nerd"
  mkdir -p "${font_dir}"
  unzip -o "${font_tmp}/${FONT_NAME}.zip" -d "${font_dir}" >/dev/null
  fc-cache -f >/dev/null
  rm -rf "${font_tmp}"
  log_success "Nerd Font installed for terminal/app icon support."
}

install_wireguard() {
  if [[ "${ENABLE_WIREGUARD}" != "true" ]]; then
    log_info "WireGuard installation skipped (ENABLE_WIREGUARD=false)."
    return
  fi
  log_info "Installing and configuring WireGuard VPN..."
  apt-get install "${APT_OPTS[@]}" wireguard qrencode
  umask 077
  install -d -m 700 /etc/wireguard
  local priv_key="/etc/wireguard/private.key"
  local pub_key="/etc/wireguard/public.key"
  if [[ ! -f "${priv_key}" ]]; then
    wg genkey | tee "${priv_key}" | wg pubkey > "${pub_key}"
  fi
  local private_key
  private_key="$(cat "${priv_key}")"
  cat <<EOF >/etc/wireguard/wg0.conf
[Interface]
Address = ${WG_INTERFACE_ADDRESS}
ListenPort = ${WG_PORT}
PrivateKey = ${private_key}
SaveConfig = true
PostUp = iptables -t nat -A POSTROUTING -o ${WG_PUBLIC_INTERFACE} -j MASQUERADE; iptables -A FORWARD -i %i -j ACCEPT; iptables -A FORWARD -o %i -j ACCEPT
PostDown = iptables -t nat -D POSTROUTING -o ${WG_PUBLIC_INTERFACE} -j MASQUERADE; iptables -D FORWARD -i %i -j ACCEPT; iptables -D FORWARD -o %i -j ACCEPT

# Add peer definitions below:
# [Peer]
# PublicKey =
# AllowedIPs =
EOF
  cat <<'EOF' >/etc/sysctl.d/70-wireguard.conf
net.ipv4.ip_forward=1
net.ipv6.conf.all.forwarding=1
EOF
  sysctl -p /etc/sysctl.d/70-wireguard.conf >/dev/null
  systemctl enable wg-quick@wg0.service --now
  log_success "WireGuard active on wg0 (${WG_INTERFACE_ADDRESS}, port ${WG_PORT})."
}

main() {
  update_system
  install_essential_packages
  configure_locale
  configure_swap
  configure_firewall
  set_hostname
  create_dev_user
  secure_ssh
  install_fail2ban
  install_gui_stack
  install_nvm_node_stack
  install_python_stack
  install_docker_stack
  install_vscode
  install_cursor
  install_browser
  install_shell_stack
  install_nerd_font
  install_wireguard
  log_success "Provisioning complete. Reboot recommended before first XRDP sign-in."
}

main

