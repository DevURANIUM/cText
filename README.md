# 🚀 cText

**cText** is a simple, fast, and secure pastebin-like service built with **FastAPI**.

Create temporary text pastes, protect them with passwords, and automatically expire them after a chosen time.

🌐 Live: https://ctext.ir

---

## ✨ Features

* ⚡ FastAPI-powered backend
* 🔐 End-to-end encrypted paste storage (Fernet)
* 🔑 Optional password protection (bcrypt)
* ⏳ Expiring pastes (auto cleanup via cron)
* 🧠 Session-based unlock system
* 🛡 CSRF protection
* 📄 Raw paste endpoint
* 🎨 Clean UI (Jinja2 templates)
* 🔄 Auto restart with systemd
* 🌍 Production-ready with Nginx + SSL

---

## 🏗 Architecture

```
Client
   ↓
Nginx (80/443)
   ↓
Uvicorn (127.0.0.1:8001)
   ↓
FastAPI App
   ↓
SQLite Database
```

---

## 📦 Requirements

* Python 3.10+
* Nginx
* Uvicorn / Gunicorn
* SQLite

### Python Dependencies

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

---

## ⚙️ Installation

```bash
git clone https://github.com/YOUR_USERNAME/ctext.git
cd ctext

pip install -r requirements.txt
```

---

## 🔐 Environment Variables

Create a `.env` file in the project root:

```
PASTE_SECRET_KEY=
SESSION_SECRET_KEY=
CSRF_SESSION_KEY=
```

### Generate Keys

#### 1. Fernet Key (for encryption)

```bash
python -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())"
```

#### 2. Session Secret Key

```bash
python -c "import secrets; print(secrets.token_urlsafe(64))"
```

#### 3. CSRF Key (name of session field)

```bash
csrf_token
```

> Example:

```
PASTE_SECRET_KEY=YOUR_KEY
SESSION_SECRET_KEY=YOUR_KEY
CSRF_SESSION_KEY=csrf_token
```

---

## ▶️ Run Locally

```bash
uvicorn app.main:app --reload
```

App will be available at:

```
http://127.0.0.1:8000
```

---

## 🚀 Production Deployment (Ubuntu)

### 1. Install dependencies

```bash
apt update -y
apt install -y python3 python3-pip nginx
```

---

### 2. Run with Uvicorn

```bash
uvicorn app.main:app --host 127.0.0.1 --port 8001
```

---

### 3. Setup Nginx

```nginx
server {
    listen 80;
    server_name your-domain.com;

    location / {
        proxy_pass http://127.0.0.1:8001;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

---

### 4. Enable SSL

```bash
sudo certbot --nginx -d your-domain.com
```

---

### 5. Systemd Service

```
/etc/systemd/system/ctext.service
```

```ini
[Service]
ExecStart=/usr/local/bin/uvicorn app.main:app --host 127.0.0.1 --port 8001
Restart=always
```

---

## ⏳ Cleanup Job (Cron)

Automatically delete expired pastes:

```bash
crontab -e
```

```bash
0 3 * * * cd /var/www/ctext && /usr/bin/python3 cleanup_expired.py
```

---

## 🔐 Security Notes

* Paste content is encrypted using **Fernet (AES)**
* Passwords are hashed using **bcrypt**
* CSRF protection is enforced
* App runs on `127.0.0.1` behind Nginx
* HTTPS recommended (and enforced in sessions)

---

## 📡 API Endpoints

| Method | Endpoint       | Description  |
| ------ | -------------- | ------------ |
| GET    | `/`            | Home page    |
| POST   | `/paste`       | Create paste |
| GET    | `/{id}`        | View paste   |
| GET    | `/raw/{id}`    | Raw content  |
| POST   | `/{id}/unlock` | Unlock paste |
| POST   | `/{id}/delete` | Delete paste |

---

## 📁 Project Structure

```
app/
 ├── main.py
 ├── models.py
 ├── db.py
 ├── templates/
 └── static/

cleanup_expired.py
requirements.txt
.env
```

---

## 🧠 Future Improvements

* Rate limiting
* Paste syntax highlighting
* Private / unlisted pastes
* User accounts
* API tokens

---

## 🤝 Contributing

Pull requests are welcome. For major changes, open an issue first.

---

## 📄 License

MIT License

---

## 👨‍💻 Author

Made with ❤️ by **YOU**
