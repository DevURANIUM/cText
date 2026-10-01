from datetime import datetime
from zoneinfo import ZoneInfo

from app.db import SessionLocal
from app.models import Paste
from sqlalchemy import delete

# Must match LOCAL_TZ in app/main.py (timestamps are stored as naive Tehran time)
LOCAL_TZ = ZoneInfo("Asia/Tehran")


def main():
    now = datetime.now(LOCAL_TZ).replace(tzinfo=None)
    with SessionLocal() as db:
        stmt = (
            delete(Paste)
            .where(Paste.expires_at.is_not(None))
            .where(Paste.expires_at <= now)
        )

        result = db.execute(stmt)
        db.commit()
        print(f"[{now:%Y-%m-%d %H:%M}] Deleted rows: {result.rowcount}")

if __name__ == "__main__":
    main()
