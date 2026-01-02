from pydantic import BaseModel

class UserCreate(BaseModel):
    username: str
    password: str


class MessageCreate(BaseModel):
    sender_id: int
    receiver_id: int
    encrypted_content: str


