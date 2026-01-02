from sqlalchemy import Column, Integer, String, Boolean, ForeignKey, DateTime, LargeBinary, Text
from sqlalchemy.orm import relationship, declarative_base
from datetime import datetime
from sqlalchemy.sql import func


Base = declarative_base()

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    username = Column(String, unique=True, index=True, nullable=False)
    
    stego_image = Column(LargeBinary, nullable=False)
    
    password = Column(Text, nullable=False)

    is_online = Column(Boolean, default=False)

    created_at = Column(DateTime, default=datetime.utcnow)

    sent_messages = relationship(
        "Message",
        foreign_keys="Message.sender_id",
        back_populates="sender"
    )

    received_messages = relationship(
        "Message",
        foreign_keys="Message.receiver_id",
        back_populates="receiver"
    )


class Message(Base):
    __tablename__ = "messages"

    id = Column(Integer, primary_key=True, index=True)

    sender_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    receiver_id = Column(Integer, ForeignKey("users.id"), nullable=False)

    encrypted_content = Column(String, nullable=False)

   
    is_delivered = Column(Boolean, default=False)
    is_read = Column(Boolean, default=False)

    created_at = Column(DateTime(timezone=True), server_default=func.now())

    sender = relationship(
        "User",
        foreign_keys=[sender_id],
        back_populates="sent_messages"
    )

    receiver = relationship(
        "User",
        foreign_keys=[receiver_id],
        back_populates="received_messages"
    )
    
    @property
    def status(self) -> str:
        if self.is_read:
            return "read"
        elif self.is_delivered:
            return "delivered"
        else:
            return "sent"