from fastapi import FastAPI, Depends, HTTPException, UploadFile, File, Form, WebSocket, WebSocketDisconnect
from sqlalchemy.orm import Session
from contextlib import asynccontextmanager
from typing import Dict, List, Optional
import json

from database import SessionLocal, create_tables
from models import User, Message
from schemas import UserCreate, MessageCreate

from services.lsb_service import extract_password_from_image
from services.message_handler import (
    process_message,
    save_message_to_db,
    get_user_password
)


class ConnectionManager:
    
    def __init__(self):
        self.active_connections: Dict[int, List[WebSocket]] = {}
    
    async def connect(self, websocket: WebSocket, user_id: int):
        await websocket.accept()
        if user_id not in self.active_connections:
            self.active_connections[user_id] = []
        self.active_connections[user_id].append(websocket)
        print(f"✅ WebSocket connected: user_id={user_id}, total connections={len(self.active_connections[user_id])}")
    
    def disconnect(self, websocket: WebSocket, user_id: int):
        if user_id in self.active_connections:
            if websocket in self.active_connections[user_id]:
                self.active_connections[user_id].remove(websocket)
            if not self.active_connections[user_id]:
                del self.active_connections[user_id]
        print(f"❌ WebSocket disconnected: user_id={user_id}")
    
    async def send_personal_message(self, message: dict, user_id: int):
        if user_id in self.active_connections:
            disconnected = []
            for connection in self.active_connections[user_id]:
                try:
                    await connection.send_json(message)
                except Exception as e:
                    print(f"Error sending to user {user_id}: {e}")
                    disconnected.append(connection)
            
            for conn in disconnected:
                self.disconnect(conn, user_id)
    
    async def broadcast_status(self, user_id: int, username: str, is_online: bool):
        message = {
            "type": "status",
            "user_id": user_id,
            "username": username,
            "is_online": is_online
        }
        
        for uid in list(self.active_connections.keys()):
            await self.send_personal_message(message, uid)

manager = ConnectionManager()

@asynccontextmanager
async def lifespan(app: FastAPI):
    create_tables()
    yield

app = FastAPI(lifespan=lifespan)

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


@app.get("/")
def root():
    return {"message": "Server çalışıyor"}

@app.post("/register")
async def register_user(
    username: str = Form(...),
    image: UploadFile = File(...),
    db: Session = Depends(get_db)
):
    if db.query(User).filter(User.username == username).first():
        raise HTTPException(status_code=400, detail="Username exists")

    image_bytes = await image.read()
    
    try:
        extracted_password = extract_password_from_image(image_bytes)
        print(f"✅ Register: Extracted password '{extracted_password}' from image for user '{username}'")
        
        if not extracted_password or extracted_password.strip('\x00') == '':
            raise ValueError("Extracted password is empty or invalid")
            
    except Exception as e:
        print(f"❌ Register: Failed to extract password: {e}")
        raise HTTPException(
            status_code=400,
            detail="Resimden şifre çıkarılamadı. Lütfen geçerli bir steganografik resim kullanın. Register ekranında resim seçtikten sonra şifrenizi girin ve kayıt olun."
        )

    new_user = User(
        username=username,
        stego_image=image_bytes,
        password=extracted_password,  
        is_online=False 
    )

    db.add(new_user)
    db.commit()
    db.refresh(new_user)

    print(f"✅ Register successful: user_id={new_user.id}, username={new_user.username}")
    return {"message": "Kayıt başarılı", "user_id": new_user.id}


@app.post("/login")
async def login(
    username: str = Form(...),
    password: str = Form(...),
    db: Session = Depends(get_db)
):
    
    db_user = db.query(User).filter(User.username == username).first()

    if not db_user:
        raise HTTPException(
            status_code=401,
            detail="Hatalı kullanıcı adı veya şifre"
        )
    
    if db_user.password != password:
        raise HTTPException(
            status_code=401,
            detail="Hatalı kullanıcı adı veya şifre"
        )

    db_user.is_online = True
    db.commit()

    print(f"✅ Login successful: user_id={db_user.id}, username={db_user.username}")
    return {"message": "Giriş başarılı", "user_id": db_user.id}


@app.get("/users")
def get_users(current_user_id: Optional[int] = None, db: Session = Depends(get_db)):
    users = db.query(User).all()
    result = []
    for u in users:
        user_data = {
            "id": u.id, 
            "username": u.username, 
            "is_online": u.is_online
        }
        
        if current_user_id is not None:
             unread = db.query(Message).filter(
                Message.sender_id == u.id,
                Message.receiver_id == current_user_id,
                Message.is_read == False
            ).count()
             user_data["unread_count"] = unread
             
        result.append(user_data)
        
    return result


from fastapi.responses import Response

@app.get("/users/{user_id}/photo")
def get_user_photo(user_id: int, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.id == user_id).first()
    if not user or not user.stego_image:
        raise HTTPException(status_code=404, detail="Photo not found")
    
    return Response(
        content=user.stego_image,
        media_type="image/png"
    )


@app.post("/messages/send")
async def send_message(msg: MessageCreate, db: Session = Depends(get_db)):
    
    sender = db.query(User).filter(User.id == msg.sender_id).first()
    receiver = db.query(User).filter(User.id == msg.receiver_id).first()
    
    if not sender or not receiver:
        raise HTTPException(status_code=404, detail="User not found")
    
    sender_password = get_user_password(db, msg.sender_id)
    receiver_password = get_user_password(db, msg.receiver_id)
    
    if not sender_password or not receiver_password:
        raise HTTPException(status_code=500, detail="Password retrieval failed")
    
    print(f"\n📨 ===== MESAJ GÖNDERİLİYOR =====")
    print(f"   Gönderen: {sender.username} (ID: {msg.sender_id})")
    print(f"   Alıcı: {receiver.username} (ID: {msg.receiver_id})")
    print(f"   🔐 Şifrelenmiş Mesaj (Gönderenden): {msg.encrypted_content[:50]}..." if len(msg.encrypted_content) > 50 else f"   🔐 Şifrelenmiş Mesaj (Gönderenden): {msg.encrypted_content}")
    
    try:
        encrypted_for_receiver = process_message(
            msg.encrypted_content,
            sender_password,
            receiver_password
        )
        print(f"   🔐 Şifrelenmiş Mesaj (Alıcı için): {encrypted_for_receiver[:50]}..." if len(encrypted_for_receiver) > 50 else f"   🔐 Şifrelenmiş Mesaj (Alıcı için): {encrypted_for_receiver}")
    except Exception as e:
        print(f"   ❌ Mesaj işleme hatası: {e}")
        raise HTTPException(status_code=500, detail=f"Message processing failed: {str(e)}")
    
    is_receiver_online = receiver.is_online and msg.receiver_id in manager.active_connections
    
    db_message = save_message_to_db(
        db,
        msg.sender_id,
        msg.receiver_id,
        encrypted_for_receiver,
        is_delivered=is_receiver_online
    )
    
    message_status = "delivered" if is_receiver_online else "sent"
    print(f"   📤 Durum: {message_status}")
    print(f"   ================================\n")
    
    if is_receiver_online:
        await manager.send_personal_message(
            {
                "type": "message",
                "message_id": db_message.id,
                "sender_id": msg.sender_id,
                "receiver_id": msg.receiver_id,
                "encrypted_content": encrypted_for_receiver,
                "status": message_status,
                "created_at": db_message.created_at.isoformat()
            },
            msg.receiver_id
        )
    
    await manager.send_personal_message(
        {
            "type": "message",
            "message_id": db_message.id,
            "sender_id": msg.sender_id,
            "receiver_id": msg.receiver_id,
            "encrypted_content": msg.encrypted_content,
            "status": message_status,
            "created_at": db_message.created_at.isoformat()
        },
        msg.sender_id
    )
    
    return {"message": "Mesaj gönderildi", "message_id": db_message.id, "status": message_status}


@app.get("/messages/{me_id}/{other_id}")
def get_messages(me_id: int, other_id: int, db: Session = Depends(get_db)):
    
    messages = db.query(Message).filter(
        ((Message.sender_id == me_id) & (Message.receiver_id == other_id)) |
        ((Message.sender_id == other_id) & (Message.receiver_id == me_id))
    ).order_by(Message.created_at).all()
    
    # Kullanıcı şifrelerini al
    my_password = get_user_password(db, me_id)
    other_password = get_user_password(db, other_id)
    
    result = []
    messages_to_mark_read = []
    
    for m in messages:
        encrypted_for_me = m.encrypted_content
        

        if m.sender_id == me_id:
            try:
                from services.crypto_service import des_decrypt, des_encrypt
                plain = des_decrypt(m.encrypted_content, other_password)
                encrypted_for_me = des_encrypt(plain, my_password)
            except Exception as e:
                print(f"⚠️ Re-encryption failed for message {m.id}: {e}")
        else:
            if not m.is_read:
                messages_to_mark_read.append(m.id)
        
        result.append({
            "message_id": m.id,
            "sender_id": m.sender_id,
            "receiver_id": m.receiver_id,
            "encrypted_content": encrypted_for_me,
            "status": m.status,
            "created_at": m.created_at
        })
    
    if messages_to_mark_read:
        db.query(Message).filter(Message.id.in_(messages_to_mark_read)).update(
            {"is_read": True, "is_delivered": True},
            synchronize_session=False
        )
        db.commit()
    
    return result


@app.post("/logout")
async def logout(user_id: int, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.id == user_id).first()
    if user:
        user.is_online = False
        db.commit()
        
        await manager.broadcast_status(user.id, user.username, False)
    
    return {"message": "Çıkış yapıldı"}


@app.websocket("/ws/{user_id}")
async def websocket_endpoint(websocket: WebSocket, user_id: int):

    await manager.connect(websocket, user_id)
    
    db = SessionLocal()
    try:
        user = db.query(User).filter(User.id == user_id).first()
        if user:
            user.is_online = True
            db.commit()
            await manager.broadcast_status(user_id, user.username, True)
    finally:
        db.close()
    
    try:
        while True:
            data = await websocket.receive_text()
            
            try:
                message = json.loads(data)
                if message.get("type") == "ping":
                    await websocket.send_json({"type": "pong"})
            except json.JSONDecodeError:
                pass
                
    except WebSocketDisconnect:
        manager.disconnect(websocket, user_id)
        
        db = SessionLocal()
        try:
            user = db.query(User).filter(User.id == user_id).first()
            if user:
                user.is_online = False
                db.commit()
                await manager.broadcast_status(user_id, user.username, False)
        finally:
            db.close()
        
        print(f"Client {user_id} disconnected")
    except Exception as e:
        print(f"WebSocket error for user {user_id}: {e}")
        manager.disconnect(websocket, user_id)

