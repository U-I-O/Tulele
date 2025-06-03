from werkzeug.security import generate_password_hash, check_password_hash
import datetime
from bson import ObjectId

class User:
    """用户模型
    
    在MongoDB中使用的用户模型，不再需要继承自SQLAlchemy的Model类
    """
    
    @staticmethod
    def generate_password_hash(password):
        """生成密码哈希"""
        return generate_password_hash(password)
    
    @staticmethod
    def create_user(mongo, username, email, password):
        """创建新用户"""
        password_hash = User.generate_password_hash(password)
        now = datetime.datetime.now()
        
        user_data = {
            'username': username,
            'email': email,
            'password_hash': password_hash,
            'created_at': now,
            'updated_at': now
        }
        
        result = mongo.db.users.insert_one(user_data)
        return result.inserted_id
    
    @staticmethod
    def get_user_by_id(mongo, user_id):
        """通过ID获取用户"""
        return mongo.db.users.find_one({'_id': ObjectId(user_id)})
    
    @staticmethod
    def get_user_by_username(mongo, username):
        """通过用户名获取用户"""
        return mongo.db.users.find_one({'username': username})
    
    @staticmethod
    def get_user_by_email(mongo, email):
        """通过邮箱获取用户"""
        return mongo.db.users.find_one({'email': email})
    
    @staticmethod
    def verify_password(user, password):
        """验证密码"""
        if not user:
            return False
        return check_password_hash(user['password_hash'], password)
    
    @staticmethod
    def to_json(user):
        """将用户数据转换为JSON格式"""
        if not user:
            return None
            
        return {
            'id': str(user['_id']),
            'username': user['username'],
            'email': user['email'],
            'created_at': user['created_at'].strftime('%Y-%m-%d %H:%M:%S') if 'created_at' in user else None,
            'updated_at': user['updated_at'].strftime('%Y-%m-%d %H:%M:%S') if 'updated_at' in user else None
        } 