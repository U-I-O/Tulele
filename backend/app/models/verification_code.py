import datetime
import random
from bson import ObjectId

class VerificationCode:
    """验证码模型
    
    用于生成和验证各种用途的验证码（如密码重置、邮箱验证等）
    """
    
    # 验证码用途
    PURPOSE_RESET_PASSWORD = 'reset_password'
    PURPOSE_VERIFY_EMAIL = 'verify_email'
    
    # 验证码有效期（分钟）
    EXPIRY_MINUTES = 30
    
    @staticmethod
    def generate_code():
        """生成6位数字验证码"""
        return str(random.randint(100000, 999999))
    
    @staticmethod
    def create_code(mongo, email, purpose):
        """创建新验证码
        
        Args:
            mongo: MongoDB连接实例
            email: 用户邮箱
            purpose: 验证码用途
            
        Returns:
            验证码
        """
        code = VerificationCode.generate_code()
        now = datetime.datetime.now()
        expiry_time = now + datetime.timedelta(minutes=VerificationCode.EXPIRY_MINUTES)
        
        # 先删除该邮箱同一用途的旧验证码
        mongo.db.verification_codes.delete_many({
            'email': email,
            'purpose': purpose
        })
        
        # 创建新验证码记录
        verification_data = {
            'email': email,
            'code': code,
            'purpose': purpose,
            'created_at': now,
            'expires_at': expiry_time,
            'used': False
        }
        
        mongo.db.verification_codes.insert_one(verification_data)
        return code
    
    @staticmethod
    def verify_code(mongo, email, code, purpose):
        """验证验证码
        
        Args:
            mongo: MongoDB连接实例
            email: 用户邮箱
            code: 验证码
            purpose: 验证码用途
            
        Returns:
            验证成功返回True，失败返回False
        """
        # 查找验证码记录
        verification = mongo.db.verification_codes.find_one({
            'email': email,
            'code': code,
            'purpose': purpose,
            'used': False,
            'expires_at': {'$gt': datetime.datetime.now()}
        })
        
        if not verification:
            return False
        
        # 标记验证码已使用
        mongo.db.verification_codes.update_one(
            {'_id': verification['_id']},
            {'$set': {'used': True}}
        )
        
        return True
    
    @staticmethod
    def get_active_code(mongo, email, purpose):
        """获取活跃的验证码
        
        Args:
            mongo: MongoDB连接实例
            email: 用户邮箱
            purpose: 验证码用途
            
        Returns:
            找到返回验证码记录，否则返回None
        """
        return mongo.db.verification_codes.find_one({
            'email': email,
            'purpose': purpose,
            'used': False,
            'expires_at': {'$gt': datetime.datetime.now()}
        }) 