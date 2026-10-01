# نصب cText.ir

روی سرور Ubuntu یا Debian، فقط با یک دستور.

## نصب

پوشه‌ی پروژه رو روی سرور کپی کن (مثلاً با `scp` یا `git clone`)، بعد داخلش:

```bash
sudo bash install.sh
```

دو تا سؤال می‌پرسه:

1. **دامنه** — مثلاً `ctext.ir`. خالی بذاری، سایت روی IP سرور با HTTP بالا میاد.
2. **ایمیل** — برای گواهی SSL از Let's Encrypt. خالی بذاری، SSL نصب نمی‌شه.

بدون سؤال:

```bash
sudo DOMAIN=ctext.ir EMAIL=you@mail.com bash install.sh
```

> قبل از نصب SSL، رکورد A دامنه باید به IP سرور اشاره کنه.

## اسکریپت چه کارهایی می‌کنه

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

## به‌روزرسانی

فایل‌های جدید رو جایگزین کن و دوباره همون دستور رو بزن. داده‌ها و کلیدها حفظ می‌شن:

```bash
sudo bash install.sh
```

## دستورهای کاربردی

```bash
systemctl status ctext          # وضعیت
journalctl -u ctext -f          # لاگ زنده
systemctl restart ctext         # ری‌استارت
sudo bash install.sh --uninstall  # حذف سرویس، nginx و cron (فایل‌ها می‌مونن)
```

## نکته‌های مهم

- **از `/var/www/ctext/.env` بک‌آپ بگیر.** محتوای پیست‌ها با `PASTE_SECRET_KEY` رمز می‌شه. اگه این کلید گم بشه، پیست‌های قبلی دیگه باز نمی‌شن.
- زمان‌ها به وقت تهران ذخیره می‌شن (`Asia/Tehran`). تنظیم timezone سرور لازم نیست.
- درگاه داخلی رو با `sudo APP_PORT=8002 bash install.sh` عوض کن.
- اگه سایت روی HTTP ساده بالاست، باید `SESSION_HTTPS_ONLY=false` باشه. وگرنه فرم‌ها خطای CSRF می‌دن. اسکریپت این مقدار رو خودش تنظیم می‌کنه.

## ساختار

```
Client → Nginx (80/443) → Uvicorn (127.0.0.1:8001) → FastAPI → SQLite (pastes.db)
```
