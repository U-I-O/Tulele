from flask_jwt_extended import create_access_token, create_refresh_token
from werkzeug.security import check_password_hash
from datetime import timedelta

def authenticate_user(mongo, username_or_email, password):
    """
    验证用户凭据并返回用户信息
    
    Args:
        mongo: PyMongo实例
        username_or_email: 用户名或电子邮件
        password: 密码
        
    Returns:
        user: 用户信息字典，验证失败则为None
        message: 错误信息，验证成功则为None
    """
    # 检查是邮箱还是用户名
    if '@' in username_or_email:
        user = mongo.db.users.find_one({'email': username_or_email})
    else:
        user = mongo.db.users.find_one({'username': username_or_email})
    
    if not user:
        return None, "用户不存在"
    
    if not check_password_hash(user['password_hash'], password):
        return None, "密码错误"
    
    return user, None

def generate_tokens(user_id, identity_claims=None):
    """
    为用户生成访问令牌和刷新令牌
    
    Args:
        user_id: 用户ID
        identity_claims: 额外身份信息
        
    Returns:
        tokens: 包含access_token和refresh_token的字典
    """
    # 创建自定义身份信息
    identity = {'user_id': str(user_id)}
    if identity_claims:
        identity.update(identity_claims)
    
    # 创建访问令牌和刷新令牌
    access_token = create_access_token(
        identity=identity,
        expires_delta=timedelta(hours=1)  # 访问令牌1小时有效
    )
    
    refresh_token = create_refresh_token(
        identity=identity,
        expires_delta=timedelta(days=30)  # 刷新令牌30天有效
    )
    
    return {
        'access_token': access_token,
        'refresh_token': refresh_token
    } 