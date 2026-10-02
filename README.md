# cText.ir

سرویس ساده برای اشتراک‌گذاری متن (Pastebin). متن رو می‌چسبونی، زمان انقضا رو انتخاب می‌کنی و کد یا لینکش رو برای بقیه می‌فرستی.

## امکانات

- **رمزنگاری:** محتوای همه‌ی پیست‌ها با Fernet رمز شده ذخیره می‌شه.
- **رمز عبور اختیاری:** هر پیست می‌تونه رمز داشته باشه (با bcrypt هش می‌شه).
- **انقضای خودکار:** از ۱۰ دقیقه تا ۳۰ روز. پیست‌های منقضی هر شب پاک می‌شن.
- **کد کوتاه:** کد ۶ کاراکتری، فقط عدد، فقط حروف، یا ترکیبی.
- **نمایشگر:** شماره‌ی خط، شکستن خطوط بلند، Raw، دانلود `.txt` و کپی با یک کلیک.
- **ظاهر:** حالت روشن و تیره، مناسب موبایل، و پشتیبانی از متن فارسی (فونت وزیر).
- **امنیت فرم‌ها:** محافظت CSRF روی همه‌ی فرم‌ها.

## تکنولوژی

FastAPI · Jinja2 · SQLAlchemy · SQLite · Uvicorn · Nginx

```
Client → Nginx (80/443) → Uvicorn (127.0.0.1:8001) → FastAPI → SQLite (pastes.db)
```

## ساختار پروژه

```
├── app/
│   ├── main.py            # مسیرها و منطق برنامه
│   ├── db.py              # اتصال دیتابیس
│   ├── models.py          # مدل Paste
│   ├── requirements.txt
│   ├── templates/         # صفحه‌ها (Jinja2)
│   └── static/            # CSS، فونت، آیکون
├── cleanup_expired.py     # پاک‌سازی پیست‌های منقضی (cron)
├── install.sh             # نصب‌کننده‌ی سرور
└── .env.example           # نمونه‌ی تنظیمات
```

## نصب روی سرور

روی سرور Ubuntu یا Debian، فقط با یک دستور. پوشه‌ی پروژه رو روی سرور کپی کن (مثلاً با `scp` یا `git clone`)، بعد داخلش:

```bash
sudo bash install.sh
```

دو تا سؤال می‌پرسه:

1. **دامنه:** مثلاً `ctext.ir`. خالی بذاری، سایت روی IP سرور با HTTP بالا میاد.
2. **ایمیل:** برای گواهی SSL از Let's Encrypt. خالی بذاری، SSL نصب نمی‌شه.

بدون سؤال:

```bash
sudo DOMAIN=ctext.ir EMAIL=you@mail.com bash install.sh
```

> قبل از نصب SSL، رکورد A دامنه باید به IP سرور اشاره کنه.

### اسکریپت چه کارهایی می‌کنه

| مرحله | توضیح |
|---|---|
| پکیج‌ها | `python3`، `python3-venv`، `nginx`، و `certbot` (اگه SSL بخوای) |
| فایل‌ها | کپی پروژه به `/var/www/ctext` (فایل `.env` و دیتابیس موجود دست نمی‌خورن) |
| پایتون | ساخت virtualenv در `/var/www/ctext/venv`، بدون `--break-system-packages` |
| `.env` | فقط بار اول کلیدهای امن رو خودش می‌سازه |
| سرویس | `ctext.service` در systemd روی `127.0.0.1:8001` با ری‌استارت خودکار |
| nginx | reverse proxy، به‌علاوه‌ی سرو مستقیم فایل‌های `/static` |
| SSL | گرفتن گواهی با certbot و ریدایرکت HTTP به HTTPS |
| Cron | پاک کردن پیست‌های منقضی هر روز ساعت ۳ صبح |

### به‌روزرسانی

فایل‌های جدید رو جایگزین کن و دوباره همون دستور رو بزن. داده‌ها و کلیدها حفظ می‌شن:

```bash
sudo bash install.sh
```

### دستورهای کاربردی

```bash
systemctl status ctext            # وضعیت
journalctl -u ctext -f            # لاگ زنده
systemctl restart ctext           # ری‌استارت
sudo bash install.sh --uninstall  # حذف سرویس، nginx و cron (فایل‌ها می‌مونن)
```

## اجرای محلی (توسعه)

```bash
python -m venv venv
venv/bin/pip install -r app/requirements.txt   # ویندوز: venv\Scripts\pip
cp .env.example .env                            # کلیدها رو پر کن، SESSION_HTTPS_ONLY=false
venv/bin/uvicorn app.main:app --reload --port 8001
```

بعد برو به `http://localhost:8001`.

## تنظیمات (`.env`)

| متغیر | توضیح |
|---|---|
| `PASTE_SECRET_KEY` | کلید Fernet برای رمز کردن محتوای پیست‌ها |
| `SESSION_SECRET_KEY` | کلید امضای کوکی session |
| `CSRF_SESSION_KEY` | اسم کلید توکن CSRF در session (مثلاً `csrf_token`) |
| `SESSION_HTTPS_ONLY` | `true` برای HTTPS و `false` برای HTTP ساده |

## نکته‌های مهم

- **از `/var/www/ctext/.env` بک‌آپ بگیر.** اگه `PASTE_SECRET_KEY` گم بشه، پیست‌های قبلی دیگه باز نمی‌شن.
- زمان‌ها به وقت تهران ذخیره می‌شن (`Asia/Tehran`). تنظیم timezone سرور لازم نیست.
- درگاه داخلی رو با `sudo APP_PORT=8002 bash install.sh` عوض کن.
- اگه سایت روی HTTP ساده بالاست، باید `SESSION_HTTPS_ONLY=false` باشه. وگرنه فرم‌ها خطای CSRF می‌دن. اسکریپت نصب این مقدار رو خودش تنظیم می‌کنه.

---

Powered by [URANIUM](https://t.me/DevRouter)
