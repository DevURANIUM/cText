# cText 📋

> A fast, minimal, and secure pastebin alternative — built with FastAPI.

**cText** lets you share text snippets privately and securely. Pastes are encrypted at rest, can be password-protected, and automatically expire. No accounts, no tracking, no ads.

---

## ✨ Features

- 🔐 **End-to-end encryption** — paste content is encrypted at rest using Fernet (AES-128-CBC)
- 🔑 **Password protection** — optional bcrypt-hashed password per paste
- ⏳ **Auto-expiry** — choose expiration from 10 minutes up to 30 days
- 🛡️ **CSRF protection** — HMAC-based CSRF tokens on all forms
- 📄 **Raw view** — direct plaintext access via `/raw/{id}`
- 🗑️ **Manual delete** — delete your paste at any time
- 🧹 **Auto-cleanup** — daily cron job removes expired pastes
- 🚫 **No registration required** — completely anonymous usage
- 🌐 **HTTPS-first** — designed to run behind Nginx with Let's Encrypt SSL

---

## 🛠️ Tech Stack

| Layer | Technology |
|-------|------------|
| Backend | FastAPI + Uvicorn |
| ORM | SQLAlchemy |
| Database | SQLite |
| Encryption | Cryptography (Fernet) |
| Password Hashing | bcrypt |
| Sessions | Starlette SessionMiddleware |
| Templating | Jinja2 |
| Reverse Proxy | Nginx |
| Process Manager | Systemd |
| SSL | Let's Encrypt (Certbot) |

---

## 📁 Project Structure

```
ctext/
├── app/
│   ├── main.py          # FastAPI routes and application logic
│   ├── models.py        # SQLAlchemy models
│   ├── db.py            # Database session setup
│   ├── static/          # CSS, JS, assets
│   └── templates/       # Jinja2 HTML templates
│       ├── index.html
│       ├── view.html
│       ├── created.html
│       └── 404.html
├── cleanup_expired.py   # Standalone cleanup script (used by cron)
├── requirements.txt
├── .env                 # Secret keys (not committed)
└── pastes.db            # SQLite database (auto-created)
```

---

## ⚙️ Installation & Deployment

### Prerequisites

- Ubuntu 22.04+ (or similar Debian-based distro)
- Python 3.10+
- Nginx
- Certbot (for SSL)
- A domain pointing to your server

---

### 1. Update Server

```bash
apt update -y && apt upgrade -y && apt autoremove -y
```

---

### 2. Install System Dependencies

```bash
sudo apt install -y python3 python3-pip nginx
```

If you encounter conflicts with `typing-extensions`:

```bash
apt remove --purge python3-typing-extensions
```

---

### 3. Clone & Set Up Project

```bash
mkdir /var/www/ctext/
cd /var/www/ctext/
git clone https://github.com/DevURANIUM/cText.git .
pip install -r requirements.txt --break-system-packages
```

---

### 4. Configure Environment Variables

Create the `.env` file:

```bash
nano /var/www/ctext/.env
```

Add the following:

```env
PASTE_SECRET_KEY=
SESSION_SECRET_KEY=
CSRF_SESSION_KEY=
```

**How to generate each key:**

```bash
# PASTE_SECRET_KEY (Fernet key — must be this exact format)
python3 -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())"

# SESSION_SECRET_KEY (random URL-safe string)
python3 -c "import secrets; print(secrets.token_urlsafe(64))"

# CSRF_SESSION_KEY (just a session key name, e.g. a short string)
python3 -c "import secrets; print(secrets.token_urlsafe(64))"
```

Example `.env` after filling in:

```env
PASTE_SECRET_KEY=Ib7k2YourGeneratedFernetKeyHere=
SESSION_SECRET_KEY=yourLongRandomSessionSecretHere
CSRF_SESSION_KEY=csrf_token
```

> ⚠️ Never commit `.env` to version control. Add it to `.gitignore`.

---

### 5. Configure Systemd Service

Create `/etc/systemd/system/ctext.service`:

```ini
[Unit]
Description=ctext FastAPI application
After=network.target

[Service]
User=www-data
Group=www-data
WorkingDirectory=/var/www/ctext

EnvironmentFile=/var/www/ctext/.env

ExecStart=/usr/local/bin/uvicorn app.main:app \
  --host 127.0.0.1 \
  --port 8001 \
  --proxy-headers

Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
```

Enable and start:

```bash
sudo systemctl daemon-reload
sudo systemctl start ctext
sudo systemctl enable ctext
sudo systemctl status ctext
```

---

### 6. Configure Nginx

Create `/etc/nginx/sites-available/ctext.ir`:

```nginx
server {
    listen 80;
    server_name ctext.ir;

    location / {
        proxy_pass http://127.0.0.1:8001;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

Enable the site:

```bash
sudo ln -s /etc/nginx/sites-available/ctext.ir /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

---

### 7. Enable SSL (Let's Encrypt)

```bash
sudo certbot --nginx -d ctext.ir
sudo certbot renew --dry-run
```

---

### 8. Fix File Permissions

```bash
chown www-data:www-data /var/www/ctext/pastes.db
chmod 664 /var/www/ctext/pastes.db
chown www-data:www-data /var/www/ctext
chmod 775 /var/www/ctext
```

---

### 9. Set Timezone (Optional)

```bash
sudo timedatectl set-timezone Asia/Tehran
```

---

### 10. Configure Cron Job (Cleanup)

Run `crontab -e` and add:

```bash
# Run cleanup every day at 03:00 AM
0 3 * * * cd /var/www/ctext && /usr/bin/python3 cleanup_expired.py >> /var/www/ctext/ctext_cleanup.log 2>&1
```

Verify:

```bash
crontab -l
```

---

## 🏗️ Architecture

```
Client (Browser)
       │
       ▼
  Nginx :80/:443  ──── SSL termination (Let's Encrypt)
       │
       ▼
 Uvicorn :8001 (127.0.0.1 only)
       │
       ▼
 FastAPI Application
       │
       ▼
  SQLite (pastes.db)
```

- Nginx handles all public traffic and TLS
- Uvicorn binds only to localhost for security
- Systemd ensures the process restarts automatically on failure

---

## 🔒 Security Notes

- Paste content is **encrypted at rest** using Fernet symmetric encryption
- Passwords are hashed with **bcrypt (12 rounds)**; passwords longer than 72 bytes are SHA-256-prehashed before bcrypt to prevent truncation
- **CSRF tokens** are signed using `hmac.compare_digest` to prevent timing attacks
- Sessions use `SameSite=Lax` and `https_only=True`
- The application process runs as `www-data` (least privilege)
- Uvicorn binds only to `127.0.0.1` — never exposed directly to the internet

---

## ✅ Final Checks

```bash
sudo systemctl status ctext
sudo nginx -t
sudo certbot renew --dry-run
```

Your application will be live at:

```
https://ctext.ir
```

---

## 📦 Requirements

```
fastapi
uvicorn
gunicorn
jinja2
sqlalchemy
python-dotenv
python-multipart
bcrypt
cryptography
itsdangerous
```

Install with:

```bash
pip install -r requirements.txt --break-system-packages
```

---

## 💛 Support the Project

If cText is useful to you, consider supporting its development:

| Network | Address |
|---------|---------|
| **BTC** | `bc1qcclcp574hnznm0nmdzzf0ta7366svjskttqks3` |
| **LTC** | `ltc1qcrkelw38gjrmg0ptjy2nshqej622kp76het7q0` |
| **XRP** | `rPoK5SBChFPqEiQv1W97LW6FKoJZLipDVQ` |
| **XLM** | `GDMUQREEZNBSTQOT5BV7MYEMXJFV3CYRZXUVOYCTIUZTHUWPHLVASFVD` |
| **TON** | `UQAJH2N0pqpvC9YN841w5NH1dCN9Lakwkpjvoy7vXf-vfqgv` |
| **TRON** | `TXJqhhwvkrTdnf5HReZf55hEzZuxjto3R4` |
| **USDT (BEP20)** | `0x1591036c4bD05b046532B65Df939fcd7824E18c7` |

Every contribution, no matter how small, helps keep the project running. ❤️

---

## 📄 License

This project is open source. See [LICENSE](LICENSE) for details.
