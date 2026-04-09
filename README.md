# cText

**cText** is a minimal, privacy-focused paste sharing service built with **FastAPI**, inspired by tools like **Pastebin**.  
It lets users create temporary text pastes, optionally protect them with a password, automatically expire them after a chosen time, and delete them manually.

The project is designed to be lightweight, easy to deploy, and simple to maintain on a VPS with **Uvicorn**, **Nginx**, **Systemd**, and **Let's Encrypt SSL**.

---

## Features

- Create text pastes with a short unique ID
- Optional password protection for private pastes
- Automatic expiration with multiple time choices
- Manual paste deletion
- Raw text endpoint for direct access
- CSRF protection for form submissions
- Session-based unlock flow for protected pastes
- Encrypted paste storage using **Fernet**
- Password hashing with **bcrypt**
- FastAPI + Jinja2 server-rendered pages
- SQLite-friendly setup for simple self-hosting
- Daily cleanup job for expired pastes

---

## Tech Stack

- **Backend:** FastAPI
- **ASGI Server:** Uvicorn
- **Process Manager:** Systemd
- **Reverse Proxy:** Nginx
- **Templates:** Jinja2
- **Database:** SQLite via SQLAlchemy
- **Environment Management:** python-dotenv
- **Password Hashing:** bcrypt
- **Encryption:** cryptography / Fernet
- **Session Middleware:** Starlette SessionMiddleware

---

## Preview

A dark, modern, minimal interface built for quick paste creation and sharing.

> You can add your own screenshot to the repository, for example at `docs/screenshot.png`, then reference it like this:
>
> ```md
> ![cText Screenshot](docs/screenshot.png)
> ```

---

## Use Cases

- Share logs, snippets, or notes temporarily
- Send one-time text content with expiration
- Protect sensitive pastes with a password
- Self-host a personal or internal paste service
- Run a lightweight alternative to public paste platforms

---

## Project Structure

```text
cText/
├── app/
│   ├── main.py
│   ├── db.py
│   ├── models.py
│   ├── static/
│   └── templates/
├── cleanup_expired.py
├── requirements.txt
├── .env
└── README.md
```

> The exact structure may differ slightly depending on how you organize your files, but the main deployment assumptions are based on this layout.

---

## Requirements

### Required Python packages

Install these dependencies:

```txt
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

You can place them in `requirements.txt` and install with:

```bash
pip install -r requirements.txt
```

If your server environment needs it:

```bash
pip install -r requirements.txt --break-system-packages
```

---

## Environment Variables

Create a `.env` file in the project root:

```env
PASTE_SECRET_KEY=
SESSION_SECRET_KEY=
CSRF_SESSION_KEY=
```

### What each key does

- `PASTE_SECRET_KEY`  
  Used for encrypting and decrypting paste content with **Fernet**.

- `SESSION_SECRET_KEY`  
  Used by **SessionMiddleware** to securely sign session data.

- `CSRF_SESSION_KEY`  
  This is the session field name used to store the CSRF token.

---

## How to Generate the Secrets

### 1) Generate `PASTE_SECRET_KEY`

This key **must** be a valid Fernet key:

```bash
python3 -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())"
```

Example output:

```env
PASTE_SECRET_KEY=your_generated_fernet_key_here
```

---

### 2) Generate `SESSION_SECRET_KEY`

Generate a long random URL-safe secret:

```bash
python3 -c "import secrets; print(secrets.token_urlsafe(64))"
```

Example output:

```env
SESSION_SECRET_KEY=your_generated_session_secret_here
```

---

### 3) Set `CSRF_SESSION_KEY`

This value is **not** a cryptographic key in your current implementation.  
It is the **session key name** where the CSRF token will be stored.

A simple value is enough:

```env
CSRF_SESSION_KEY=csrf_token
```

If you want, you can use another custom name:

```env
CSRF_SESSION_KEY=ctext_csrf_token
```

> Important: in the current codebase, `CSRF_SESSION_KEY` is used as a **dictionary key name** inside the session, not as a secret token itself.

---

## Example `.env`

```env
PASTE_SECRET_KEY=REPLACE_WITH_A_VALID_FERNET_KEY
SESSION_SECRET_KEY=REPLACE_WITH_A_LONG_RANDOM_SECRET
CSRF_SESSION_KEY=csrf_token
```

---

## Installation

### 1) Update the server

```bash
apt update -y
apt upgrade -y
apt autoremove -y
```

### 2) Install system dependencies

```bash
sudo apt install -y python3 python3-pip nginx
```

If you encounter issues with `typing-extensions`:

```bash
apt remove --purge python3-typing-extensions
```

If FastAPI needs to be installed manually:

```bash
pip install fastapi --break-system-packages
```

---

## Deployment on Ubuntu

### 1) Create project directory

```bash
mkdir /var/www/ctext/
cd /var/www/ctext/
```

Copy your project files into this directory, then install dependencies:

```bash
pip install -r requirements.txt
pip install -r requirements.txt --break-system-packages
```

---

### 2) Configure Systemd

Create:

```text
/etc/systemd/system/ctext.service
```

Use:

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

Then reload and start:

```bash
sudo systemctl daemon-reload
sudo systemctl start ctext
sudo systemctl enable ctext
sudo systemctl status ctext
```

Restart when needed:

```bash
sudo systemctl restart ctext
```

---

### 3) Configure Nginx

Create:

```text
/etc/nginx/sites-available/ctext.ir
```

Add:

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

### 4) Enable SSL with Let's Encrypt

```bash
sudo certbot --nginx -d ctext.ir
```

Test renewal:

```bash
sudo certbot renew --dry-run
```

---

### 5) Set timezone

Check current time:

```bash
date
```

Set timezone:

```bash
sudo timedatectl set-timezone Asia/Tehran
```

---

### 6) Fix file permissions

For the database file:

```bash
chown www-data:www-data /var/www/ctext/pastes.db
chmod 664 /var/www/ctext/pastes.db
```

For the project directory:

```bash
chown www-data:www-data /var/www/ctext
chmod 775 /var/www/ctext
```

---

### 7) Configure cleanup cron job

Open crontab:

```bash
crontab -e
```

Add:

```bash
0 3 * * * cd /var/www/ctext && /usr/bin/python3 cleanup_expired.py
```

Optional log output:

```bash
0 3 * * * cd /var/www/ctext && /usr/bin/python3 cleanup_expired.py >> /var/www/ctext/ctext_cleanup.log 2>&1
```

Verify cron jobs:

```bash
crontab -l
```

---

## Architecture Overview

```text
Client
   ↓
Nginx (Port 80/443)
   ↓
Uvicorn (127.0.0.1:8001)
   ↓
FastAPI Application
   ↓
SQLite Database
```

---

## Application Behavior

### Home page

- Displays the paste creation form
- Generates and stores a CSRF token in the session
- Shows expiration choices
- Accepts optional password protection

### Paste creation

When a user submits content:

- empty content is rejected
- expiration time is validated against predefined choices
- optional password is hashed with bcrypt
- paste content is encrypted before saving
- a unique 6-character paste ID is generated
- the user receives a shareable URL

### Protected pastes

If a paste has a password:

- the content stays locked
- the user must unlock it with the correct password
- unlocked state is stored in the session

### Raw pastes

`/raw/{paste_id}` returns plain text content.

If the paste is password-protected and not unlocked in the current session, access is denied.

### Expiration

Whenever a paste is requested:

- the app checks whether it has expired
- expired pastes are automatically removed from the database
- a `404` response is returned for expired or missing pastes

### Deletion

A paste can be deleted manually.

For password-protected pastes, the user must unlock the paste first before deletion.

---

## Security Notes

cText includes several security-focused mechanisms:

### 1) Encrypted paste storage

Paste contents are encrypted using **Fernet** before being stored in the database.

### 2) Password hashing

Paste passwords are hashed using **bcrypt**.

### 3) Long password handling

Because bcrypt only considers the first 72 bytes, long passwords are first transformed with **SHA-256** to keep verification safe and consistent.

### 4) CSRF protection

Form submissions use a session-based CSRF token and `hmac.compare_digest()` for secure token comparison.

### 5) Session protection

Unlocked paste state is stored in the user session.

### 6) Local bind only

The app runs on:

```text
127.0.0.1:8001
```

and is meant to be exposed through **Nginx**, not directly to the internet.

---

## Available Expiration Options

Current expiration choices in the code:

- 10 minutes
- 30 minutes
- 1 hour
- 2 hours
- 6 hours
- 8 hours
- 12 hours
- 1 day
- 2 days
- 3 days
- 30 days

Default:

- 30 minutes

---

## Endpoints

### `GET /`
Show the home page.

### `POST /paste`
Create a new paste.

### `GET /raw/{paste_id}`
Return paste content as plain text.

### `POST /{paste_id}/unlock`
Unlock a password-protected paste.

### `POST /{paste_id}/delete`
Delete a paste.

### `GET /{paste_id}`
View a paste by ID.

---

## Error Handling

- Missing paste → `404`
- Expired paste → deleted, then `404`
- Missing password for protected paste → `401` or `403` depending on route
- Invalid CSRF token → `403`
- Invalid encryption key → application startup error
- Missing session secret → application startup error

Custom 404 page support is included through template rendering.

---

## Running Locally

A simple local run example:

```bash
uvicorn app.main:app --reload
```

By default, the project expects a valid `.env` file to exist before startup.

---

## Production Notes

- Run behind **Nginx**
- Keep `https_only=True` when serving over HTTPS
- Use strong secrets in `.env`
- Never commit `.env` to GitHub
- Add `.env` to `.gitignore`
- Back up your database if persistence matters
- Keep your Fernet key safe; changing it will make existing encrypted content unreadable unless migrated

---

## Suggested `.gitignore`

```gitignore
__pycache__/
*.pyc
.env
venv/
.venv/
pastes.db
*.log
```

---

## Example `requirements.txt`

```txt
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

---

## Troubleshooting

### App fails to start with `PASTE_SECRET_KEY is not set`

Your `.env` file is missing `PASTE_SECRET_KEY`.

Generate one with:

```bash
python3 -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())"
```

---

### App fails to start with `SESSION_SECRET_KEY is not set`

Generate one with:

```bash
python3 -c "import secrets; print(secrets.token_urlsafe(64))"
```

---

### App fails to decrypt paste content

This usually means one of these:

- the Fernet key changed after pastes were created
- the database contains old plaintext content
- stored content is corrupted

---

### Protected paste keeps asking for password

Make sure:

- cookies are enabled
- HTTPS is working correctly
- session middleware is configured properly

Because the app uses:

```python
https_only=True
```

session cookies are intended for HTTPS deployments.

---

### Nginx returns 502 Bad Gateway

Usually this means:

- Uvicorn is not running
- Systemd service failed
- wrong port in `proxy_pass`
- incorrect `ExecStart` path

Check:

```bash
sudo systemctl status ctext
journalctl -u ctext -f
```

---

## Roadmap Ideas

Possible future improvements:

- syntax highlighting
- burn-after-read mode
- custom paste URLs
- rate limiting
- admin dashboard
- API endpoints
- Docker support
- PostgreSQL support
- paste size limits
- dark/light theme toggle

---

## Donation

Support the project:

- **BTC:** `bc1qcclcp574hnznm0nmdzzf0ta7366svjskttqks3`
- **LTC:** `ltc1qcrkelw38gjrmg0ptjy2nshqej622kp76het7q0`
- **XRP:** `rPoK5SBChFPqEiQv1W97LW6FKoJZLipDVQ`
- **XLM:** `GDMUQREEZNBSTQOT5BV7MYEMXJFV3CYRZXUVOYCTIUZTHUWPHLVASFVD`
- **TON:** `UQAJH2N0pqpvC9YN841w5NH1dCN9Lakwkpjvoy7vXf-vfqgv`
- **TRON:** `TXJqhhwvkrTdnf5HReZf55hEzZuxjto3R4`
- **USDT (BEP20):** `0x1591036c4bD05b046532B65Df939fcd7824E18c7`

Thank you for supporting the project.

---

## License

You can publish this project under the license of your choice.

A common option is **MIT License**.

Example:

```text
MIT License
```

If you want, add a `LICENSE` file to the repository before publishing.

---

## Author

Built and maintained by the cText developer.

If you publish it on GitHub, replace this section with your name, handle, website, or contact links.

---

## Final Checklist Before Publishing

- [ ] remove any private secrets from the repository
- [ ] add `.env` to `.gitignore`
- [ ] make sure `requirements.txt` is complete
- [ ] verify `README.md`
- [ ] test deployment on a fresh Ubuntu server
- [ ] confirm SSL is working
- [ ] verify cron cleanup works
- [ ] make sure database permissions are correct

---

cText is a simple self-hosted paste service focused on fast sharing, temporary storage, and practical privacy features.
