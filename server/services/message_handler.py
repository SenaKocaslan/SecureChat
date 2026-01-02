

from services.crypto_service import des_encrypt, des_decrypt
from datetime import datetime


def process_message(cipher_from_client: str, sender_password: str, receiver_password: str) -> str:
    
    print(f"🔄 Processing message:")
    print(f"  - Cipher length: {len(cipher_from_client)}")
    print(f"  - Sender password: {sender_password}")
    print(f"  - Receiver password: {receiver_password}")
    
    try:
        plain_text = des_decrypt(cipher_from_client, sender_password)
        print(f"  ✅ Decrypted: {plain_text}")
        
        cipher_for_recipient = des_encrypt(plain_text, receiver_password)
        print(f"  ✅ Re-encrypted for recipient")
        
        return cipher_for_recipient
    except Exception as e:
        print(f"  ❌ Error in process_message: {e}")
        import traceback
        traceback.print_exc()
        raise


def save_message_to_db(db, sender_id: int, receiver_id: int, encrypted_content: str, is_delivered: bool = False):
    
    from models import Message
    
    message = Message(
        sender_id=sender_id,
        receiver_id=receiver_id,
        encrypted_content=encrypted_content,
        is_delivered=is_delivered
    )
    
    db.add(message)
    db.commit()
    db.refresh(message)
    
    return message


def get_pending_messages(db, receiver_id: int):
    
    from models import Message
    
    return db.query(Message).filter(
        Message.receiver_id == receiver_id,
        Message.is_delivered == False
    ).order_by(Message.created_at).all()


def mark_messages_delivered(db, receiver_id: int):
    
    from models import Message
    
    db.query(Message).filter(
        Message.receiver_id == receiver_id,
        Message.is_delivered == False
    ).update({"is_delivered": True})
    
    db.commit()


def get_user_password(db, user_id: int) -> str:
    
    from models import User
    
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        print(f"❌ User {user_id} not found")
        return None
    
    print(f"🔑 Retrieved password for user {user_id} ({user.username}): '{user.password}'")
    return user.password


def get_user_by_username(db, username: str):
    
    from models import User
    
    return db.query(User).filter(User.username == username).first()


if __name__ == "__main__":
    print("=== Message Handler Test ===")
    
    sender_pass = "sender88"
    receiver_pass = "receive8"
    original = "Merhaba!"
    
    from services.crypto_service import des_encrypt
    cipher_from_sender = des_encrypt(original, sender_pass)
    print(f"Gönderen şifreledi: {cipher_from_sender[:20]}...")
    
    cipher_for_receiver = process_message(cipher_from_sender, sender_pass, receiver_pass)
    print(f"Alıcı için: {cipher_for_receiver[:20]}...")
    
    from services.crypto_service import des_decrypt
    decrypted = des_decrypt(cipher_for_receiver, receiver_pass)
    print(f"Alıcı çözdü: {decrypted}")
    
    assert original == decrypted
    print("✓ Test başarılı!")
