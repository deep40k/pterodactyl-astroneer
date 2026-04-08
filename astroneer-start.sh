#!/usr/bin/env bash
set -euo pipefail

APP_DIR="/home/container"
STEAMCMD_DIR="/opt/steamcmd"
PROTON_DIR="/opt/ge-proton"
APP_ID="728470"
PORT="${SERVER_PORT:-8777}"
SERVER_NAME="${SERVER_NAME:-Pterodactyl Astroneer Server}"
SERVER_PWD="${SERVER_PWD:-}"
OWNER_NAME="${OWNER_NAME:-}"
PUBLIC_IP="${PUBLIC_IP:-}"
DOMAIN_NAME="${DOMAIN_NAME:-}"
DISABLE_ENCRYPTION="${DISABLE_ENCRYPTION:-0}"
AUTO_UPDATE="${AUTO_UPDATE:-1}"
SAVE_NAME="${SAVE_NAME:-SAVE_1}"

export HOME="$APP_DIR"
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"
export STEAM_COMPAT_CLIENT_INSTALL_PATH="$STEAMCMD_DIR"
export STEAM_COMPAT_DATA_PATH="$APP_DIR/compatdata/${APP_ID}"
export PROTON_LOG_DIR="$APP_DIR/logs"
export PROTON_LOG="${PROTON_LOG:-1}"
export SDL_AUDIODRIVER="dummy"
export PROTON_USE_WINED3D="1"
export PROTON_NO_ESYNC="1"
export PROTON_NO_FSYNC="1"

mkdir -p \
  "$APP_DIR/logs" \
  "$APP_DIR/.steam/sdk32" \
  "$APP_DIR/.steam/sdk64" \
  "$APP_DIR/compatdata/${APP_ID}" \
  "$APP_DIR/Astro/Saved/Config/WindowsServer" \
  "$APP_DIR/Astro/Saved/SaveGames"

cat > "$APP_DIR/.asoundrc" <<'ASOUNDRC'
pcm.!default {
    type null
}
ctl.!default {
    type hw
    card 0
}
ASOUNDRC

if [[ -z "$PUBLIC_IP" ]]; then
  if [[ -n "$DOMAIN_NAME" ]]; then
    PUBLIC_IP="$(getent ahostsv4 "$DOMAIN_NAME" | awk 'NR==1{print $1}')"
  fi
fi
if [[ -z "$PUBLIC_IP" ]]; then
  PUBLIC_IP="$(curl -4fsS https://api.ipify.org || true)"
fi

if [[ -z "$OWNER_NAME" ]]; then
  echo "OWNER_NAME is required. Set the Steam username that should become owner/admin." >&2
  exit 1
fi
if [[ -z "$PUBLIC_IP" ]]; then
  echo "Could not determine PUBLIC_IP automatically. Set PUBLIC_IP explicitly." >&2
  exit 1
fi

if [[ "$AUTO_UPDATE" == "1" ]]; then
  "$STEAMCMD_DIR/steamcmd.sh" \
    +force_install_dir "$APP_DIR" \
    +login anonymous \
    +@sSteamCmdForcePlatformType windows \
    +app_update "$APP_ID" validate \
    +quit
fi

cp -f "$STEAMCMD_DIR/linux32/steamclient.so" "$APP_DIR/.steam/sdk32/steamclient.so"
cp -f "$STEAMCMD_DIR/linux64/steamclient.so" "$APP_DIR/.steam/sdk64/steamclient.so"

ENGINE_INI="$APP_DIR/Astro/Saved/Config/WindowsServer/Engine.ini"
SETTINGS_INI="$APP_DIR/Astro/Saved/Config/WindowsServer/AstroServerSettings.ini"

if [[ ! -f "$ENGINE_INI" ]]; then
  cat > "$ENGINE_INI" <<'EOF_ENGINE'
[URL]
Port=8777

[SystemSettings]
net.AllowEncryption=True
EOF_ENGINE
fi

if [[ ! -f "$SETTINGS_INI" ]]; then
  cat > "$SETTINGS_INI" <<'EOF_SETTINGS'
[/Script/Astro.AstroServerSettings]
PublicIP=
ServerName=Pterodactyl Astroneer Server
ServerPassword=
OwnerName=
OwnerGuid=0
ActiveSaveFileDescriptiveName=SAVE_1
EOF_SETTINGS
fi

export ENGINE_INI SETTINGS_INI PORT PUBLIC_IP SERVER_NAME SERVER_PWD OWNER_NAME SAVE_NAME DISABLE_ENCRYPTION

python3 - <<'PY'
from pathlib import Path
import os

def upsert(path_str, section, key, value):
    path = Path(path_str)
    lines = path.read_text(encoding='utf-8', errors='ignore').splitlines()
    if not lines:
        lines = [section]
    sec_idx = None
    for i, line in enumerate(lines):
        if line.strip() == section:
            sec_idx = i
            break
    if sec_idx is None:
        if lines and lines[-1] != '':
            lines.append('')
        lines.append(section)
        lines.append(f"{key}={value}")
        path.write_text("\n".join(lines) + "\n", encoding='utf-8')
        return
    insert_idx = sec_idx + 1
    replaced = False
    i = sec_idx + 1
    while i < len(lines) and not (lines[i].startswith('[') and lines[i].endswith(']')):
        if lines[i].startswith(f"{key}="):
            lines[i] = f"{key}={value}"
            replaced = True
            break
        insert_idx = i + 1
        i += 1
    if not replaced:
        lines.insert(insert_idx, f"{key}={value}")
    path.write_text("\n".join(lines) + "\n", encoding='utf-8')

engine = os.environ['ENGINE_INI']
settings = os.environ['SETTINGS_INI']
port = os.environ['PORT']
public_ip = os.environ['PUBLIC_IP']
server_name = os.environ['SERVER_NAME']
server_pwd = os.environ['SERVER_PWD']
owner_name = os.environ['OWNER_NAME']
save_name = os.environ['SAVE_NAME']
allow_encryption = 'False' if os.environ['DISABLE_ENCRYPTION'] == '1' else 'True'

upsert(engine, '[URL]', 'Port', port)
upsert(engine, '[SystemSettings]', 'net.AllowEncryption', allow_encryption)
upsert(settings, '[/Script/Astro.AstroServerSettings]', 'PublicIP', public_ip)
upsert(settings, '[/Script/Astro.AstroServerSettings]', 'ServerName', server_name)
upsert(settings, '[/Script/Astro.AstroServerSettings]', 'ServerPassword', server_pwd)
upsert(settings, '[/Script/Astro.AstroServerSettings]', 'OwnerName', owner_name)
upsert(settings, '[/Script/Astro.AstroServerSettings]', 'OwnerGuid', '0')
upsert(settings, '[/Script/Astro.AstroServerSettings]', 'ActiveSaveFileDescriptiveName', save_name)
PY

# write current effective config summary to console
printf 'ASTRONEER_BOOTSTRAP_DONE\n'
printf 'Server URI: %s:%s\n' "$PUBLIC_IP" "$PORT"
printf 'Encryption: %s\n' "$([[ "$DISABLE_ENCRYPTION" == "1" ]] && echo disabled || echo enabled)"

exec xvfb-run -a --server-args='-screen 0 1024x768x24' \
  "$PROTON_DIR/proton" run "$APP_DIR/Astro/Binaries/Win64/AstroServer-Win64-Shipping.exe" -log
