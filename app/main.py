from fastapi import FastAPI, Request, Form, Depends, HTTPException
from fastapi.responses import HTMLResponse, PlainTextResponse, RedirectResponse
from fastapi.staticfiles import StaticFiles
from fastapi.templating import Jinja2Templates

from starlette.middleware.sessions import SessionMiddleware
from starlette.exceptions import HTTPException as StarletteHTTPException

from sqlalchemy.orm import Session
from sqlalchemy import select

from datetime import datetime, timedelta
import secrets
import string
import hashlib
import bcrypt
import os
import hmac

from dotenv import load_dotenv
from cryptography.fernet import Fernet, InvalidToken

from .db import Base, engine, SessionLocal
from .models import Paste


# =========================
# Env / Crypto
# =========================
load_dotenv()  # reads .env from project root

FERNET_KEY = (os.getenv("PASTE_SECRET_KEY") or "").strip()
if not FERNET_KEY:
    raise RuntimeError("PASTE_SECRET_KEY is not set (put it in .env)")

# Fernet expects a urlsafe base64-encoded 32-byte key
try:
    fernet = Fernet(FERNET_KEY.encode("utf-8"))
except Exception as e:
    raise RuntimeError(
        "PASTE_SECRET_KEY is invalid for Fernet. "
        "Generate one with: python -c \"from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())\""
    ) from e

# =========================
# Session secret key
# =========================
SESSION_SECRET = (os.getenv("SESSION_SECRET_KEY") or "").strip()
if not SESSION_SECRET:
    raise RuntimeError(
        "SESSION_SECRET_KEY is not set (put it in .env). "
        "Generate one with: python -c \"import secrets; print(secrets.token_urlsafe(64))\""
    )
Base.metadata.create_all(bind=engine)

app = FastAPI(title="cText (FastAPI)")
app.mount("/static", StaticFiles(directory="app/static"), name="static")
templates = Jinja2Templates(directory="app/templates")

app.add_middleware(
    SessionMiddleware,
    secret_key=SESSION_SECRET,
    same_site="lax",
    https_only=True, # If you are on HTTPS, set it to True
)

# =========================
# CSRF Session Key
# =========================
CSRF_SESSION_KEY = (os.getenv("CSRF_SESSION_KEY") or "").strip()
if not CSRF_SESSION_KEY:
    raise RuntimeError(
        "CSRF_SESSION_KEY is not set (put it in .env). "
        "Example: CSRF_SESSION_KEY=csrf_token"
    )


def get_csrf_token(request: Request) -> str:
    """
    CSRF token stored in session.

    Generated with:
    python -c "import secrets; print(secrets.token_urlsafe(32))"
    """
    token = request.session.get(CSRF_SESSION_KEY)
    if not token:
        token = secrets.token_urlsafe(32)
        request.session[CSRF_SESSION_KEY] = token
    return token


def validate_csrf(
    request: Request,
    csrf_token: str = Form(...),
) -> None:
    session_token = request.session.get(CSRF_SESSION_KEY)
    if not session_token or not hmac.compare_digest(session_token, csrf_token):
        raise HTTPException(status_code=403, detail="CSRF validation failed")

# =========================
# Expiration choices (minutes)
# label, minutes
# =========================
EXPIRE_CHOICES = [
    ("10 min", 10),
    ("30 min", 30),
    ("1 hours", 60),
    ("2 hours", 120),
    ("6 hours", 360),
    ("8 hours", 480),
    ("12 hours", 720),
    ("1 Days", 1440),
    ("2 Days", 2880),
    ("3 Days", 4320),
    ("30 Days", 43200),
]
DEFAULT_EXPIRE_MINUTES = 30

def expire_label(minutes: int) -> str:
    if minutes < 60:
        return f"{minutes} minutes"
    if minutes < 1440:
        h = minutes // 60
        return f"{h} hour" + ("" if h == 1 else "s")
    d = minutes // 1440
    return f"{d} day" + ("" if d == 1 else "s")


# =========================
# DB dependency
# =========================
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


# =========================
# Helpers
# =========================
def now_utc_naive() -> datetime:
    return datetime.utcnow()


def gen_id(length: int = 6) -> str:
    alphabet = string.ascii_lowercase + string.digits
    return "".join(secrets.choice(alphabet) for _ in range(length))


def get_paste_or_404(db: Session, paste_id: str) -> Paste:
    paste = db.get(Paste, paste_id)
    if not paste:
        raise HTTPException(status_code=404, detail="Paste not found")

    if paste.expires_at <= now_utc_naive():
        db.delete(paste)
        db.commit()
        raise HTTPException(status_code=404, detail="Paste expired")

    return paste


def is_unlocked(request: Request, paste_id: str) -> bool:
    unlocked = request.session.get("unlocked_pastes", {})
    return bool(unlocked.get(paste_id))


def set_unlocked(request: Request, paste_id: str) -> None:
    unlocked = request.session.get("unlocked_pastes", {})
    unlocked[paste_id] = True
    request.session["unlocked_pastes"] = unlocked


def _bcrypt_input(password: str) -> bytes:
    """
    bcrypt only uses the first 72 bytes.
    For longer passwords, SHA-256 first => fixed-length safe input.
    """
    pw_bytes = password.encode("utf-8")
    if len(pw_bytes) <= 72:
        return pw_bytes
    return hashlib.sha256(pw_bytes).digest()


def hash_password(password: str) -> str:
    pw = _bcrypt_input(password)
    salt = bcrypt.gensalt(rounds=12)
    return bcrypt.hashpw(pw, salt).decode("utf-8")


def verify_password(password: str, password_hash: str) -> bool:
    pw = _bcrypt_input(password)
    return bcrypt.checkpw(pw, password_hash.encode("utf-8"))


def encrypt_text(text: str) -> str:
    return fernet.encrypt(text.encode("utf-8")).decode("utf-8")


def decrypt_text(token: str) -> str:
    try:
        return fernet.decrypt(token.encode("utf-8")).decode("utf-8")
    except InvalidToken:
        # DB may contain old plaintext or wrong key was used before
        raise HTTPException(status_code=500, detail="Cannot decrypt paste content (wrong key or corrupted data)")


# =========================
# Routes
# =========================
@app.get("/", response_class=HTMLResponse)
def home(request: Request):
    csrf_token = get_csrf_token(request)
    return templates.TemplateResponse(
        "index.html",
        {
            "request": request,
            "csrf_token": csrf_token,
            "expire_choices": EXPIRE_CHOICES,
            "default_expire": DEFAULT_EXPIRE_MINUTES,
            "content": "",
        },
    )



@app.post("/paste", response_class=HTMLResponse)
def create_paste(
    request: Request,
    _csrf: None = Depends(validate_csrf),
    content: str | None = Form(None),
    expires_in: int = Form(DEFAULT_EXPIRE_MINUTES),  # minutes
    password: str | None = Form(None),
    db: Session = Depends(get_db),
):
    valid_minutes = [m for _, m in EXPIRE_CHOICES]
    if expires_in not in valid_minutes:
        expires_in = DEFAULT_EXPIRE_MINUTES

    content_clean = (content or "").strip()
    if not content_clean:
        return templates.TemplateResponse(
            "index.html",
            {
                "request": request,
                "csrf_token": get_csrf_token(request),
                "expire_choices": EXPIRE_CHOICES,
                "default_expire": expires_in,
                "error": "Please enter some text before creating a paste.",
                "content": "",
            },
            status_code=400,
        )

    pwd_clean = (password or "").strip()
    password_hash = hash_password(pwd_clean) if pwd_clean else None

    paste_id = gen_id(6)
    while db.get(Paste, paste_id) is not None:
        paste_id = gen_id(6)

    created = now_utc_naive()
    expires_at = created + timedelta(minutes=expires_in)

    paste = Paste(
        id=paste_id,
        content=encrypt_text(content_clean),
        created_at=created,
        expires_at=expires_at,
        password_hash=password_hash,
    )
    db.add(paste)
    db.commit()

    if password_hash:
        set_unlocked(request, paste_id)

    paste_url = str(request.url_for("view_paste", paste_id=paste_id))
    return templates.TemplateResponse(
        "created.html",
        {
            "request": request,
            "csrf_token": get_csrf_token(request),
            "paste_id": paste_id,
            "paste_url": paste_url,
            "expires_in": expires_in,
            "expire_label": expire_label(expires_in),
            "is_protected": bool(password_hash),
        },
    )


@app.get("/raw/{paste_id}", response_class=PlainTextResponse)
def raw_paste(request: Request, paste_id: str, db: Session = Depends(get_db)):
    paste = get_paste_or_404(db, paste_id)

    if paste.password_hash and not is_unlocked(request, paste_id):
        raise HTTPException(status_code=403, detail="Password required")

    return PlainTextResponse(decrypt_text(paste.content))


@app.post("/{paste_id}/unlock")
def unlock_paste(
    request: Request,
    paste_id: str,
    _csrf: None = Depends(validate_csrf),
    password: str | None = Form(None),
    db: Session = Depends(get_db),
):
    paste = get_paste_or_404(db, paste_id)

    if not paste.password_hash:
        return RedirectResponse(url=f"/{paste_id}", status_code=303)

    pwd_clean = (password or "").strip()
    if (not pwd_clean) or (not verify_password(pwd_clean, paste.password_hash)):
        request.session["flash_error"] = "Incorrect password."
        return RedirectResponse(url=f"/{paste_id}", status_code=303)

    set_unlocked(request, paste_id)
    return RedirectResponse(url=f"/{paste_id}", status_code=303)


@app.post("/{paste_id}/delete")
def delete_paste(request: Request, paste_id: str, _csrf: None = Depends(validate_csrf), db: Session = Depends(get_db)):
    paste = db.get(Paste, paste_id)
    if not paste:
        raise HTTPException(status_code=404, detail="Paste not found")

    if paste.password_hash and not is_unlocked(request, paste_id):
        request.session["flash_error"] = "Please unlock this paste before deleting it."
        return RedirectResponse(url=f"/{paste_id}", status_code=303)

    db.delete(paste)
    db.commit()

    request.session["flash_success"] = "Paste deleted successfully."
    return RedirectResponse(url="/", status_code=303)


# IMPORTANT: keep this last to avoid route conflicts
@app.get("/{paste_id}", response_class=HTMLResponse, name="view_paste")
def view_paste(request: Request, paste_id: str, db: Session = Depends(get_db)):
    paste = get_paste_or_404(db, paste_id)
    csrf_token = get_csrf_token(request)

    protected = bool(paste.password_hash)
    if protected and not is_unlocked(request, paste_id):
        return templates.TemplateResponse(
            "view.html",
            {
                "request": request,
                "csrf_token": csrf_token,
                "paste_id": paste.id,
                "locked": True,
                "error": request.session.pop("flash_error", None),
            },
            status_code=401,
        )

    return templates.TemplateResponse(
        "view.html",
        {
            "request": request,
            "csrf_token": csrf_token,
            "paste_id": paste.id,
            "content": decrypt_text(paste.content),
            "locked": False,
        },
    )


# =========================
# Custom error pages
# =========================
@app.exception_handler(StarletteHTTPException)
def http_exception_handler(request: Request, exc: StarletteHTTPException):
    if exc.status_code == 404:
        return templates.TemplateResponse("404.html", {"request": request}, status_code=404)
    return HTMLResponse(str(exc.detail), status_code=exc.status_code)


# @app.get("/cleanup")
# def cleanup_expired(db: Session = Depends(get_db)):
#     stmt = select(Paste)
#     pastes = db.scalars(stmt).all()
#     n = 0
#     for p in pastes:
#         if p.expires_at <= now_utc_naive():
#             db.delete(p)
#             n += 1
#     db.commit()
#     return {"deleted": n}