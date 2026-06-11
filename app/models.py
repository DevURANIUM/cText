from sqlalchemy import String, Text, DateTime
from sqlalchemy.orm import Mapped, mapped_column
from datetime import datetime
from .db import Base

class Paste(Base):
    __tablename__ = "pastes"

    id: Mapped[str] = mapped_column(String(16), primary_key=True, index=True)
    content: Mapped[str] = mapped_column(Text, nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime, nullable=False)
    expires_at: Mapped[datetime] = mapped_column(DateTime, nullable=False)

    # اگر None باشد یعنی paste بدون پسورد است
    password_hash: Mapped[str | None] = mapped_column(String(255), nullable=True)
