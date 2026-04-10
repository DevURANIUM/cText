from app.db import SessionLocal
from app.models import Paste
from sqlalchemy import delete, func

def main():
    with SessionLocal() as db:
        stmt = (
            delete(Paste)
            .where(Paste.expires_at.is_not(None))
            .where(Paste.expires_at <= func.datetime("now", "localtime"))
        )

        result = db.execute(stmt)
        db.commit()
        print(f"Deleted rows: {result.rowcount}")

if __name__ == "__main__":
    main()
