#!/usr/bin/env bash
# Installiert Docker Engine (+ buildx, compose) und konfiguriert Git in der WSL.
# Aufruf: bash 02-wsl-docker-git.sh ["Vorname Nachname" vorname.nachname@sn-invent.de]
set -euo pipefail

BUILDX_VERSION="v0.30.1"
COMPOSE_VERSION="v5.0.1"

GIT_NAME="${1:-}"
GIT_EMAIL="${2:-}"
[[ -n "$GIT_NAME" ]]  || read -rp "Git User Name (z.B. Max Mustermann): " GIT_NAME
[[ -n "$GIT_EMAIL" ]] || read -rp "Git User E-Mail (z.B. max.mustermann@sn-invent.de): " GIT_EMAIL
if [[ -z "$GIT_NAME" || -z "$GIT_EMAIL" ]]; then
    echo "Git-Name und E-Mail sind Pflichtfelder." >&2
    exit 1
fi

echo "==> Docker Engine installieren"
sudo apt update -y
sudo apt upgrade -y
sudo apt install -y docker.io curl git

plugins="$HOME/.docker/cli-plugins"
mkdir -p "$plugins"
curl -fL "https://github.com/docker/buildx/releases/download/${BUILDX_VERSION}/buildx-${BUILDX_VERSION}.linux-amd64" \
    -o "$plugins/docker-buildx"
curl -fL "https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-linux-x86_64" \
    -o "$plugins/docker-compose"
chmod +x "$plugins/docker-buildx" "$plugins/docker-compose"

sudo usermod -aG docker "$USER"

echo "==> Verifikation"
docker buildx version
docker compose version
# Gruppenmitgliedschaft gilt erst in neuer Sitzung; sg startet den Befehl mit Gruppe docker.
sudo service docker start || true
sg docker -c "docker ps"

echo "==> Git konfigurieren"
git config --global user.name "$GIT_NAME"
git config --global user.email "$GIT_EMAIL"
mkdir -p "$HOME/infrastructure"

echo
echo "Fertig. Erwartet: 'docker ps' zeigt die Kopfzeile CONTAINER ID IMAGE ..."
echo "Bitte neues WSL-Terminal öffnen, damit die docker-Gruppe überall gilt."
