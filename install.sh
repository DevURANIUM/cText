#!/usr/bin/env bash
# =========================================================
#  cText.ir — one-shot installer for Ubuntu / Debian
#
#  Fresh install or update (re-run any time, keeps .env + database):
#     sudo bash install.sh
#
#  Non-interactive:
#     sudo DOMAIN=ctext.ir EMAIL=you@mail.com bash install.sh
#     sudo DOMAIN= bash install.sh            # no domain, plain HTTP on server IP
#
#  Remove service / nginx site / cron (keeps files and database):
#     sudo bash install.sh --uninstall
# =========================================================
set -euo pipefail

APP_NAME="ctext"
APP_DIR="${APP_DIR:-/var/www/ctext}"
APP_PORT="${APP_PORT:-8001}"
APP_USER="www-data"
SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

SERVICE_FILE="/etc/systemd/system/${APP_NAME}.service"
NGINX_SITE="/etc/nginx/sites-available/${APP_NAME}"
NGINX_LINK="/etc/nginx/sites-enabled/${APP_NAME}"
CRON_FILE="/etc/cron.d/${APP_NAME}-cleanup"

c_ok=$'\e[32m'; c_info=$'\e[36m'; c_warn=$'\e[33m'; c_err=$'\e[31m'; c_off=$'\e[0m'
step() { echo; echo "${c_info}==>${c_off} $*"; }
ok()   { echo "   ${c_ok}✓${c_off} $*"; }
warn() { echo "   ${c_warn}!${c_off} $*"; }
die()  { echo "${c_err}✗ $*${c_off}" >&2; exit 1; }

[[ $EUID -eq 0 ]] || die "Run as root:  sudo bash install.sh"
command -v apt-get >/dev/null || die "This installer supports Ubuntu/Debian (apt) only."

# ---------------------------------------------------------
# Uninstall
# ---------------------------------------------------------
if [[ "${1:-}" == "--uninstall" ]]; then
  step "Removing ${APP_NAME} service, nginx site and cron job"
  systemctl disable --now "${APP_NAME}" 2>/dev/null || true
  rm -f "$SERVICE_FILE" "$NGINX_LINK" "$NGINX_SITE" "$CRON_FILE"
  systemctl daemon-reload
  nginx -t >/dev/null 2>&1 && systemctl reload nginx || true
  ok "Done. Files and database are still in ${APP_DIR} (delete manually: rm -rf ${APP_DIR})"
  exit 0
fi

[[ -f "$SRC_DIR/app/main.py" ]] || die "Run this script from the project folder (app/main.py not found next to it)."

# ---------------------------------------------------------
# Questions
# ---------------------------------------------------------
echo "${c_info}cText.ir installer${c_off}"

if [[ -z "${DOMAIN+x}" ]]; then
  read -rp "Domain (e.g. ctext.ir) — leave empty to use the server IP: " DOMAIN
fi
DOMAIN="${DOMAIN// /}"

USE_SSL="no"
if [[ -n "$DOMAIN" ]]; then
  if [[ -z "${EMAIL+x}" ]]; then
    read -rp "Email for Let's Encrypt (empty = skip SSL): " EMAIL
  fi
  if [[ -n "${EMAIL:-}" ]]; then USE_SSL="yes"; fi
fi

# ---------------------------------------------------------
# 1. Packages
# ---------------------------------------------------------
step "Installing system packages"
export DEBIAN_FRONTEND=noninteractive
apt-get update -y -qq
PKGS=(python3 python3-venv python3-pip nginx rsync curl)
if [[ "$USE_SSL" == "yes" ]]; then PKGS+=(certbot python3-certbot-nginx); fi
apt-get install -y -qq "${PKGS[@]}" >/dev/null
ok "Installed: ${PKGS[*]}"

# ---------------------------------------------------------
# 2. Copy application
# ---------------------------------------------------------
step "Copying application to ${APP_DIR}"
mkdir -p "$APP_DIR"
if [[ "$SRC_DIR" != "$APP_DIR" ]]; then
  rsync -a --delete \
    --exclude ".env" --exclude "pastes.db" --exclude "*.log" \
    --exclude "venv/" --exclude "__pycache__/" --exclude ".git/" \
    --exclude ".claude/" --exclude "_backup*/" \
    "$SRC_DIR/" "$APP_DIR/"
fi
ok "Files synced (existing .env and database untouched)"

# ---------------------------------------------------------
# 3. Python virtualenv
# ---------------------------------------------------------
step "Setting up Python virtualenv"
[[ -x "$APP_DIR/venv/bin/python" ]] || python3 -m venv "$APP_DIR/venv"
"$APP_DIR/venv/bin/pip" install -q --upgrade pip
"$APP_DIR/venv/bin/pip" install -q -r "$APP_DIR/app/requirements.txt"
ok "Dependencies installed"

# ---------------------------------------------------------
# 4. .env (secrets) — generated only once
# ---------------------------------------------------------
step "Configuring .env"
HTTPS_ONLY=$([[ "$USE_SSL" == "yes" ]] && echo true || echo false)
if [[ -f "$APP_DIR/.env" ]]; then
  ok "Existing .env kept"
  if ! grep -q '^SESSION_HTTPS_ONLY=' "$APP_DIR/.env"; then
    echo "SESSION_HTTPS_ONLY=$HTTPS_ONLY" >> "$APP_DIR/.env"
    ok "Added SESSION_HTTPS_ONLY=$HTTPS_ONLY"
  fi
else
  "$APP_DIR/venv/bin/python" - "$APP_DIR/.env" "$HTTPS_ONLY" <<'PY'
import secrets, sys
from cryptography.fernet import Fernet
path, https_only = sys.argv[1], sys.argv[2]
with open(path, "w") as f:
    f.write(f"PASTE_SECRET_KEY={Fernet.generate_key().decode()}\n")
    f.write(f"SESSION_SECRET_KEY={secrets.token_urlsafe(64)}\n")
    f.write("CSRF_SESSION_KEY=csrf_token\n")
    f.write(f"SESSION_HTTPS_ONLY={https_only}\n")
PY
  ok "New secrets generated  (back up ${APP_DIR}/.env — without it old pastes can't be decrypted)"
fi
chmod 600 "$APP_DIR/.env"

# ---------------------------------------------------------
# 5. Permissions
# ---------------------------------------------------------
chown -R "$APP_USER:$APP_USER" "$APP_DIR"

# ---------------------------------------------------------
# 6. systemd service
# ---------------------------------------------------------
step "Creating systemd service"
cat > "$SERVICE_FILE" <<EOF
[Unit]
Description=cText.ir (FastAPI)
After=network.target

[Service]
User=${APP_USER}
Group=${APP_USER}
WorkingDirectory=${APP_DIR}
EnvironmentFile=${APP_DIR}/.env
ExecStart=${APP_DIR}/venv/bin/uvicorn app.main:app --host 127.0.0.1 --port ${APP_PORT} --proxy-headers --forwarded-allow-ips 127.0.0.1
Restart=always
RestartSec=3
NoNewPrivileges=true
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable -q "$APP_NAME"
systemctl restart "$APP_NAME"
ok "Service ${APP_NAME} running on 127.0.0.1:${APP_PORT}"

# ---------------------------------------------------------
# 7. nginx
# ---------------------------------------------------------
step "Configuring nginx"
if [[ -n "$DOMAIN" ]]; then
  LISTEN="listen 80;"
  SERVER_NAME="$DOMAIN"
else
  LISTEN="listen 80 default_server;"
  SERVER_NAME="_"
  if [[ -L /etc/nginx/sites-enabled/default ]]; then
    rm -f /etc/nginx/sites-enabled/default
    warn "Disabled nginx 'default' site so cText answers on the server IP"
  fi
fi

# Keep certbot's SSL edits on re-runs: only rewrite the site if it has no certificate yet
if [[ -f "$NGINX_SITE" ]] && grep -q "ssl_certificate" "$NGINX_SITE"; then
  ok "Existing SSL-enabled nginx config kept"
else
  cat > "$NGINX_SITE" <<EOF
server {
    ${LISTEN}
    server_name ${SERVER_NAME};

    client_max_body_size 10m;

    location /static/ {
        alias ${APP_DIR}/app/static/;
        expires 7d;
        access_log off;
    }

    location / {
        proxy_pass http://127.0.0.1:${APP_PORT};
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF
fi
ln -sf "$NGINX_SITE" "$NGINX_LINK"
nginx -t -q || die "nginx config test failed (see above)"
systemctl reload nginx
ok "nginx → ${SERVER_NAME}"

# ---------------------------------------------------------
# 8. SSL
# ---------------------------------------------------------
if [[ "$USE_SSL" == "yes" ]]; then
  step "Requesting Let's Encrypt certificate for ${DOMAIN}"
  if certbot --nginx -d "$DOMAIN" --non-interactive --agree-tos -m "$EMAIL" --redirect; then
    ok "HTTPS enabled (auto-renew handled by certbot timer)"
  else
    warn "Certbot failed — is ${DOMAIN} pointing to this server? Site still works over HTTP."
    sed -i 's/^SESSION_HTTPS_ONLY=.*/SESSION_HTTPS_ONLY=false/' "$APP_DIR/.env"
    systemctl restart "$APP_NAME"
    USE_SSL="no"
  fi
fi

# ---------------------------------------------------------
# 9. Daily cleanup of expired pastes (03:00)
# ---------------------------------------------------------
step "Scheduling daily cleanup"
cat > "$CRON_FILE" <<EOF
# cText.ir — delete expired pastes every day at 03:00
0 3 * * * ${APP_USER} cd ${APP_DIR} && ${APP_DIR}/venv/bin/python cleanup_expired.py >> ${APP_DIR}/ctext_cleanup.log 2>&1
EOF
chmod 644 "$CRON_FILE"
ok "Cron job: ${CRON_FILE}"

# ---------------------------------------------------------
# 10. Health check
# ---------------------------------------------------------
step "Checking"
sleep 2
if curl -fsS -o /dev/null "http://127.0.0.1:${APP_PORT}/"; then
  ok "App responds"
else
  warn "App did not respond yet. Logs:  journalctl -u ${APP_NAME} -n 50 --no-pager"
fi

if [[ -f "$NGINX_SITE" ]] && grep -q "ssl_certificate" "$NGINX_SITE"; then USE_SSL="yes"; fi
if [[ -n "$DOMAIN" ]]; then
  URL="$([[ "$USE_SSL" == "yes" ]] && echo https || echo http)://${DOMAIN}"
else
  URL="http://$(hostname -I 2>/dev/null | awk '{print $1}')"
fi

echo
echo "${c_ok}cText.ir is installed → ${URL}${c_off}"
echo
echo "  Update:    git pull / copy new files, then:  sudo bash install.sh"
echo "  Logs:      journalctl -u ${APP_NAME} -f"
echo "  Restart:   systemctl restart ${APP_NAME}"
echo "  Uninstall: sudo bash install.sh --uninstall"
