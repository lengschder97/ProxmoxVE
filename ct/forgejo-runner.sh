#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)

# Copyright (c) 2026
# Author: Simon Friedrich
# License: MIT
# Source: https://forgejo.org/

APP="Forgejo Runner"

var_tags="${var_tags:-ci}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-8}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"

# REQUIRED for Podman-in-LXC
var_unprivileged="1"
var_nesting="1"
var_keyctl="1"

# User input
var_forgejo_instance=""
var_forgejo_runner_token=""

header_info "$APP"
variables
color
catch_errors

function description() {
  cat <<EOF
Forgejo Actions Runner using Podman (unprivileged LXC)

Required inputs:
- Forgejo Instance URL (e.g. https://code.forgejo.org)
- Forgejo Runner Registration Token

This container requires:
- nesting=1
- keyctl=1
- unconfined AppArmor profile
EOF
}

start
build_container

# -------------------------------------------------
# Apply required LXC config for Podman
# -------------------------------------------------
msg_info "Applying required LXC configuration"

CONF_FILE="/etc/pve/lxc/${CTID}.conf"

if ! grep -q "lxc.apparmor.profile: unconfined" "$CONF_FILE"; then
  {
    echo "lxc.apparmor.profile: unconfined"
    echo "lxc.cap.drop:"
    echo "lxc.mount.auto: proc:rw sys:rw"
  } >>"$CONF_FILE"
fi

pct restart "$CTID"
msg_ok "LXC configuration applied"

# -------------------------------------------------
# Pass variables to install script
# -------------------------------------------------
export FORGEJO_INSTANCE="$var_forgejo_instance"
export FORGEJO_RUNNER_TOKEN="$var_forgejo_runner_token"

msg_info "Installing Forgejo Runner inside container"
pct exec "$CTID" -- bash <(curl -fsSL https://raw.githubusercontent.com/YOUR_GITHUB/REPO/main/install/forgejo-runner-install.sh)
msg_ok "Forgejo Runner installed"

description
msg_ok "Completed successfully!"
echo -e "${INFO}${YW}Forgejo Runner is now online and ready.${CL}"
