from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from models import Base 


DATABASE_URL = "postgresql://chat_user:chat_pass@localhost:5432/chat_app"

engine = create_engine(DATABASE_URL)

SessionLocal = sessionmaker(
    autocommit=False,
    autoflush=False,
    bind=engine
)

def create_tables():
    Base.metadata.create_all(bind=engine)