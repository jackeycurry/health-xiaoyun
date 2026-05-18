from sqlalchemy.orm import Session
from models.user import User
from schemas.user import UserCreate, UserLogin, UserResponse, Token
from utils.security import get_password_hash, verify_password, create_access_token


class AuthService:
    def __init__(self, db: Session):
        self.db = db

    def register(self, user_data: UserCreate) -> User:
        # 检查手机号是否已存在
        existing_user = self.db.query(User).filter(User.phone == user_data.phone).first()
        if existing_user:
            raise ValueError("该手机号已注册")

        # 创建新用户
        user = User(
            phone=user_data.phone,
            password_hash=get_password_hash(user_data.password),
            nickname=f"用户{user_data.phone[-4:]}"
        )
        self.db.add(user)
        self.db.commit()
        self.db.refresh(user)
        return user

    def login(self, login_data: UserLogin) -> Token:
        user = self.db.query(User).filter(User.phone == login_data.phone).first()

        if not user or not verify_password(login_data.password, user.password_hash):
            raise ValueError("手机号或密码错误")

        access_token = create_access_token(data={"sub": str(user.id)})
        return Token(access_token=access_token)

    def get_user_by_id(self, user_id: str) -> User:
        return self.db.query(User).filter(User.id == user_id).first()
