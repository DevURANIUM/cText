<div align="center">

# cText.ir

**Share text in seconds. Encrypted, password-protected, auto-expiring.**

A minimal, self-hosted pastebin built with FastAPI.

[English](#english) · [فارسی](#فارسی)

</div>

---

<a id="english"></a>

## English

### Overview

cText is a lightweight pastebin. Paste some text, pick how long it should live, and share a short code or link. Content is encrypted in the database and removed automatically when it expires. No accounts and no tracking. All assets, including fonts, are self-hosted.

### Features

- **Encrypted at rest:** paste content is encrypted with Fernet (AES-128-CBC + HMAC) before it is stored.
- **Optional password:** each paste can have its own password, hashed with bcrypt (cost 12). Long passwords are SHA-256 pre-hashed, so input beyond bcrypt's 72-byte limit still counts.
- **Auto-expiry:** choose from 10 minutes to 30 days. Expired pastes are deleted when someone opens them, and a nightly cron job removes the rest.
- **Short codes:** 6-character IDs, either digits only (`482913`), letters only (`kqxmpa`), or mixed (`k3x9q2`).
- **Viewer:** line numbers, line-wrap toggle, raw view, `.txt` download, and one-click copy.
- **Editor:** live line and character counter. `Ctrl/⌘ + Enter` submits and `Tab` inserts spaces.
- **UI:** light and dark themes (follows the system, with a manual toggle), mobile-friendly, and RTL/Persian text support with the bundled Vazir font.
- **Security:** CSRF protection on every form, signed session cookies, and paste IDs generated with `secrets`.
- **One-command install:** `install.sh` sets up venv, systemd, nginx, SSL and cron on Ubuntu/Debian.

### Tech stack

| Layer | Technology |
|---|---|
| Backend | FastAPI, Starlette sessions |
| Templates | Jinja2 (server-rendered, no JS framework) |
| Database | SQLite via SQLAlchemy 2.0 |
| Crypto | `cryptography` (Fernet), `bcrypt` |
| Server | Uvicorn behind Nginx, managed by systemd |
| TLS | Let's Encrypt (certbot) |

```
Client ──► Nginx :80/:443 ──► Uvicorn 127.0.0.1:8001 ──► FastAPI ──► SQLite (pastes.db)
             │
             └── /static served directly by Nginx
```

### Project structure

```
ctext/
├── app/
│   ├── main.py             # routes, crypto, CSRF, expiry logic
│   ├── db.py               # SQLAlchemy engine/session (pastes.db in project root)
│   ├── models.py           # Paste model
│   ├── requirements.txt
│   ├── templates/          # base, index, created, view, 404
│   └── static/             # styles.css, favicon.svg, fonts/ (Vazir)
├── cleanup_expired.py      # deletes expired pastes (run by cron)
├── install.sh              # server installer / updater / uninstaller
├── .env.example            # configuration template
└── README.md
```

### Quick install (Ubuntu / Debian)

Copy the project to your server (`git clone`, `scp`, …), then run this inside the project folder:

```bash
sudo bash install.sh
```

The installer asks two questions:

1. **Domain:** for example `ctext.ir`. Leave it empty to serve over plain HTTP on the server's IP.
2. **Email:** used for the Let's Encrypt certificate. Leave it empty to skip SSL.

To install without prompts:

```bash
sudo DOMAIN=ctext.ir EMAIL=you@example.com bash install.sh
sudo DOMAIN= bash install.sh                 # no domain, HTTP on server IP
sudo APP_PORT=8002 bash install.sh           # custom internal port
```

> Before requesting a certificate, point your domain's **A record** to the server's IP.

#### What the installer does

| Step | Details |
|---|---|
| Packages | `python3`, `python3-venv`, `nginx`, `rsync`, `curl` (+ `certbot` when SSL is used) |
| Files | Syncs the project to `/var/www/ctext`. An existing `.env` and `pastes.db` are never overwritten |
| Python | Creates a virtualenv at `/var/www/ctext/venv`. No `--break-system-packages` needed |
| Secrets | Generates `.env` with strong random keys on first install only (`chmod 600`) |
| Service | `ctext.service` (systemd) on `127.0.0.1:8001`, running as `www-data`, auto-restart |
| Nginx | Reverse proxy, with `/static` served directly and a 10 MB body limit |
| SSL | Certificate via certbot plus an HTTP → HTTPS redirect. Renewal is handled by certbot's timer |
| Cron | `/etc/cron.d/ctext-cleanup` removes expired pastes daily at 03:00 |
| Check | Runs a health check and prints the final URL |

### Updating

Replace the project files with the new version and run the installer again. Data and keys are kept.

```bash
sudo bash install.sh
```

### Uninstalling

```bash
sudo bash install.sh --uninstall   # removes service, nginx site and cron job
sudo rm -rf /var/www/ctext          # optional: delete files and database
```

### Manual installation

If you prefer not to use the installer:

```bash
sudo apt install -y python3 python3-venv nginx
sudo mkdir -p /var/www/ctext && sudo cp -r . /var/www/ctext && cd /var/www/ctext
sudo python3 -m venv venv
sudo venv/bin/pip install -r app/requirements.txt
sudo cp .env.example .env    # then fill in the keys (see Configuration)
sudo chown -R www-data:www-data /var/www/ctext
```

After that, create a systemd unit that runs:

```
/var/www/ctext/venv/bin/uvicorn app.main:app --host 127.0.0.1 --port 8001 --proxy-headers
```

Set `WorkingDirectory=/var/www/ctext` and `EnvironmentFile=/var/www/ctext/.env`, put Nginx in front as a reverse proxy, and add a cron entry for `cleanup_expired.py`. `install.sh` contains the exact configs.

### Local development

```bash
python -m venv venv
venv/bin/pip install -r app/requirements.txt        # Windows: venv\Scripts\pip
cp .env.example .env                                 # fill keys, set SESSION_HTTPS_ONLY=false
venv/bin/uvicorn app.main:app --reload --port 8001   # Windows: venv\Scripts\uvicorn
```

Then open <http://localhost:8001>.

### Configuration (`.env`)

| Variable | Required | Description |
|---|---|---|
| `PASTE_SECRET_KEY` | ✅ | Fernet key used to encrypt paste content |
| `SESSION_SECRET_KEY` | ✅ | Secret used to sign session cookies |
| `CSRF_SESSION_KEY` | ✅ | Session key name for the CSRF token, e.g. `csrf_token` |
| `SESSION_HTTPS_ONLY` | — | `true` (default) for HTTPS, `false` for plain HTTP |

To generate keys:

```bash
python -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())"   # PASTE_SECRET_KEY
python -c "import secrets; print(secrets.token_urlsafe(64))"                               # SESSION_SECRET_KEY
```

### Routes

| Method | Path | Description |
|---|---|---|
| `GET` | `/` | Home page: create a paste or open one by code |
| `POST` | `/paste` | Create a paste (form: `content`, `expires_in`, `id_type`, `password`, `csrf_token`) |
| `POST` | `/go` | Redirect to a paste by code |
| `GET` | `/{id}` | View a paste (password prompt if protected) |
| `POST` | `/{id}/unlock` | Unlock a protected paste for the current session |
| `POST` | `/{id}/delete` | Delete a paste (a protected paste must be unlocked first) |
| `GET` | `/raw/{id}` | Plain-text content, for example `curl https://ctext.ir/raw/482913` |

### Backup & restore

Two files hold all the state:

```bash
sudo cp /var/www/ctext/.env       ~/ctext-backup.env
sudo cp /var/www/ctext/pastes.db  ~/ctext-backup.db
```

> ⚠️ **Keep `.env` safe.** Without the original `PASTE_SECRET_KEY`, existing pastes can't be decrypted.

To restore, copy both files back, run `chown www-data:www-data` on them, and then run `systemctl restart ctext`.

### Useful commands

```bash
systemctl status ctext        # service status
journalctl -u ctext -f        # live logs
systemctl restart ctext       # restart
nginx -t                      # test nginx config
certbot renew --dry-run       # test SSL renewal
cat /var/www/ctext/ctext_cleanup.log   # cleanup history
```

### Troubleshooting

| Problem | Cause / fix |
|---|---|
| `403 CSRF validation failed` | Site served over HTTP while `SESSION_HTTPS_ONLY=true`. Set it to `false`, or enable SSL. Then restart |
| `Cannot decrypt paste content` | `PASTE_SECRET_KEY` was changed. Restore the original `.env` |
| `502 Bad Gateway` | The app is not running. Check `journalctl -u ctext -n 50` |
| `attempt to write a readonly database` | Run `sudo chown -R www-data:www-data /var/www/ctext` |
| Certbot fails | The domain's DNS doesn't point to this server yet, or port 80 is blocked |
| Wrong times | Times are stored as Asia/Tehran (`LOCAL_TZ` in `main.py`). The server timezone doesn't matter |

---

<a id="فارسی"></a>

<div dir="rtl">

## فارسی

### معرفی

cText یک Pastebin سبک و خودمیزبانه. متن رو می‌چسبونی، تعیین می‌کنی چقدر بمونه، و یه کد کوتاه یا لینک برای بقیه می‌فرستی. محتوا رمزشده توی دیتابیس ذخیره می‌شه و بعد از انقضا خودکار پاک می‌شه. ثبت‌نام و ردیابی نداره. همه‌ی فایل‌ها، حتی فونت، روی خود سرور هستن و به CDN خارجی وابسته نیست.

### امکانات

- **رمزنگاری:** محتوای پیست قبل از ذخیره با Fernet (AES-128-CBC + HMAC) رمز می‌شه.
- **رمز عبور اختیاری:** با bcrypt هش می‌شه. رمزهای خیلی طولانی هم درست کار می‌کنن.
- **انقضای خودکار:** از ۱۰ دقیقه تا ۳۰ روز. پیست منقضی موقع باز شدن حذف می‌شه و یه cron شبانه بقیه رو پاک می‌کنه.
- **کد کوتاه ۶ کاراکتری:** فقط عدد، فقط حروف، یا ترکیبی.
- **نمایشگر:** شماره‌ی خط، شکستن خطوط بلند، نمایش Raw، دانلود `.txt` و کپی با یک کلیک.
- **ویرایشگر:** شمارنده‌ی خط و کاراکتر، ارسال با `Ctrl + Enter`.
- **ظاهر:** حالت روشن و تیره، مناسب موبایل، و پشتیبانی کامل از متن فارسی با فونت وزیر.
- **امنیت:** محافظت CSRF روی همه‌ی فرم‌ها و کوکی session امضاشده.
- **نصب یک‌دستوری:** با `install.sh`.

### نصب سریع (Ubuntu / Debian)

پوشه‌ی پروژه رو روی سرور کپی کن (با `git clone` یا `scp`)، بعد داخلش این دستور رو بزن:

</div>

```bash
sudo bash install.sh
```

<div dir="rtl">

دو تا سؤال می‌پرسه:

1. **دامنه:** مثلاً `ctext.ir`. خالی بذاری، سایت روی IP سرور با HTTP بالا میاد.
2. **ایمیل:** برای گواهی SSL از Let's Encrypt. خالی بذاری، SSL نصب نمی‌شه.

نصب بدون سؤال:

</div>

```bash
sudo DOMAIN=ctext.ir EMAIL=you@example.com bash install.sh
sudo DOMAIN= bash install.sh                 # بدون دامنه، روی IP
sudo APP_PORT=8002 bash install.sh           # پورت داخلی دلخواه
```

<div dir="rtl">

> قبل از گرفتن SSL، رکورد **A** دامنه باید به IP سرور اشاره کنه.

#### اسکریپت چه کارهایی می‌کنه

| مرحله | توضیح |
|---|---|
| پکیج‌ها | `python3`، `python3-venv`، `nginx`، و `certbot` اگه SSL بخوای |
| فایل‌ها | کپی پروژه به `/var/www/ctext`. فایل `.env` و دیتابیس موجود هیچ‌وقت بازنویسی نمی‌شن |
| پایتون | ساخت virtualenv در `/var/www/ctext/venv`. دیگه `--break-system-packages` لازم نیست |
| کلیدها | فقط بار اول `.env` رو با کلیدهای تصادفی امن می‌سازه |
| سرویس | `ctext.service` در systemd روی `127.0.0.1:8001` با کاربر `www-data` و ری‌استارت خودکار |
| nginx | reverse proxy، به‌علاوه‌ی سرو مستقیم `/static` |
| SSL | گواهی با certbot، ریدایرکت HTTP به HTTPS و تمدید خودکار |
| Cron | پاک کردن پیست‌های منقضی هر روز ساعت ۳ صبح |

### به‌روزرسانی

فایل‌های جدید رو جایگزین کن و دوباره همون دستور رو بزن. داده‌ها و کلیدها حفظ می‌شن.

</div>

```bash
sudo bash install.sh
```

<div dir="rtl">

### حذف

</div>

```bash
sudo bash install.sh --uninstall   # حذف سرویس، سایت nginx و cron
sudo rm -rf /var/www/ctext          # اختیاری: پاک کردن فایل‌ها و دیتابیس
```

<div dir="rtl">

### اجرای محلی (توسعه)

</div>

```bash
python -m venv venv
venv/bin/pip install -r app/requirements.txt        # ویندوز: venv\Scripts\pip
cp .env.example .env                                 # کلیدها رو پر کن، SESSION_HTTPS_ONLY=false
venv/bin/uvicorn app.main:app --reload --port 8001
```

<div dir="rtl">

بعد آدرس `http://localhost:8001` رو باز کن.

### تنظیمات (`.env`)

| متغیر | ضروری | توضیح |
|---|---|---|
| `PASTE_SECRET_KEY` | ✅ | کلید Fernet برای رمز کردن محتوای پیست‌ها |
| `SESSION_SECRET_KEY` | ✅ | کلید امضای کوکی session |
| `CSRF_SESSION_KEY` | ✅ | اسم کلید توکن CSRF، مثلاً `csrf_token` |
| `SESSION_HTTPS_ONLY` | — | `true` (پیش‌فرض) برای HTTPS و `false` برای HTTP ساده |

### مسیرها

| متد | مسیر | توضیح |
|---|---|---|
| `GET` | `/` | صفحه‌ی اصلی |
| `POST` | `/paste` | ساخت پیست |
| `POST` | `/go` | رفتن به پیست با کد |
| `GET` | `/{id}` | نمایش پیست |
| `POST` | `/{id}/unlock` | باز کردن پیست رمزدار |
| `POST` | `/{id}/delete` | حذف پیست |
| `GET` | `/raw/{id}` | متن خام، مثلاً `curl https://ctext.ir/raw/482913` |

### بک‌آپ و بازگردانی

کل داده‌ها توی دو فایله: `/var/www/ctext/.env` و `/var/www/ctext/pastes.db`. از هر دو بک‌آپ بگیر.

> ⚠️ **مراقب `.env` باش.** بدون `PASTE_SECRET_KEY` اصلی، پیست‌های قبلی دیگه باز نمی‌شن.

برای بازگردانی، دو فایل رو برگردون سر جاشون، مالکشون رو `www-data` کن و بعد `systemctl restart ctext` بزن.

### دستورهای کاربردی

</div>

```bash
systemctl status ctext        # وضعیت سرویس
journalctl -u ctext -f        # لاگ زنده
systemctl restart ctext       # ری‌استارت
nginx -t                      # تست تنظیمات nginx
certbot renew --dry-run       # تست تمدید SSL
```

<div dir="rtl">

### رفع مشکل

| مشکل | علت و راه‌حل |
|---|---|
| خطای `403 CSRF validation failed` | سایت روی HTTP ساده‌ست ولی `SESSION_HTTPS_ONLY=true` هست. بذارش `false` یا SSL فعال کن، بعد ری‌استارت |
| `Cannot decrypt paste content` | کلید `PASTE_SECRET_KEY` عوض شده. `.env` اصلی رو برگردون |
| `502 Bad Gateway` | برنامه اجرا نیست. `journalctl -u ctext -n 50` رو ببین |
| `readonly database` | دستور `sudo chown -R www-data:www-data /var/www/ctext` رو بزن |
| خطای certbot | DNS دامنه هنوز به سرور اشاره نمی‌کنه یا پورت ۸۰ بسته‌ست |
| ساعت اشتباه | زمان‌ها به وقت تهران ذخیره می‌شن. timezone سرور مهم نیست |

</div>

---

<div align="center">

© 2026 cText.ir · Powered by [URANIUM](https://t.me/DevRouter)

</div>
