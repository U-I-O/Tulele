from flask import jsonify, request
from flask_jwt_extended import (
    jwt_required, get_jwt_identity, create_access_token,
    current_user, get_jwt
)
from bson import ObjectId
import datetime
from . import api
from .. import mongo
from ..models.user import User
from ..utils.auth_utils import authenticate_user, generate_tokens
from ..utils.mongo_utils import parse_mongo_doc

@api.route('/auth/register', methods=['POST'])
def register():
    """注册新用户"""
    data = request.get_json()
    if not data:
        return jsonify({'error': '无效的数据'}), 400
    
    # 验证必填字段
    required_fields = ['username', 'email', 'password']
    for field in required_fields:
        if field not in data:
            return jsonify({'error': f'缺少必填字段: {field}'}), 400
    
    # 检查用户名是否已存在
    if User.get_user_by_username(mongo, data['username']):
        return jsonify({'error': '用户名已存在'}), 400
    
    # 检查邮箱是否已存在
    if User.get_user_by_email(mongo, data['email']):
        return jsonify({'error': '邮箱已存在'}), 400
    
    # 创建新用户
    user_id = User.create_user(mongo, data['username'], data['email'], data['password'])
    
    # 生成身份令牌
    tokens = generate_tokens(user_id, {
        'username': data['username'],
        'email': data['email']
    })
    
    # 获取创建的用户
    user = User.get_user_by_id(mongo, user_id)
    
    return jsonify({
        'message': '用户注册成功',
        'user': User.to_json(user),
        'access_token': tokens['access_token'],
        'refresh_token': tokens['refresh_token']
    }), 201


@api.route('/auth/login', methods=['POST'])
def login():
    """用户登录"""
    data = request.get_json()
    if not data:
        return jsonify({'error': '无效的数据'}), 400
    
    # 验证必填字段
    if 'username' not in data and 'email' not in data:
        return jsonify({'error': '需要提供用户名或邮箱'}), 400
    
    if 'password' not in data:
        return jsonify({'error': '需要提供密码'}), 400
    
    # 使用用户名或邮箱登录
    username_or_email = data.get('username', data.get('email'))
    password = data['password']
    
    # 验证用户
    user, error_message = authenticate_user(mongo, username_or_email, password)
    
    if not user:
        return jsonify({'error': error_message}), 401
    
    # 生成身份令牌
    tokens = generate_tokens(user['_id'], {
        'username': user['username'],
        'email': user['email']
    })
    
    return jsonify({
        'message': '登录成功',
        'user': User.to_json(user),
        'access_token': tokens['access_token'],
        'refresh_token': tokens['refresh_token']
    })


@api.route('/auth/refresh', methods=['POST'])
@jwt_required(refresh=True)
def refresh():
    """刷新访问令牌"""
    identity = get_jwt_identity()
    user_id = identity.get('user_id')
    
    # 获取用户信息
    user = User.get_user_by_id(mongo, user_id)
    if not user:
        return jsonify({'error': '用户不存在'}), 401
    
    # 创建新的访问令牌
    access_token = create_access_token(identity=identity)
    
    return jsonify({
        'access_token': access_token,
        'user': User.to_json(user)
    })


@api.route('/auth/me', methods=['GET'])
@jwt_required()
def get_user_profile():
    """获取当前用户的个人资料"""
    identity = get_jwt_identity()
    user_id = identity.get('user_id')
    
    # 获取用户信息
    user = User.get_user_by_id(mongo, user_id)
    if not user:
        return jsonify({'error': '用户不存在'}), 401
    
    return jsonify(User.to_json(user))


@api.route('/auth/update-profile', methods=['PUT'])
@jwt_required()
def update_profile():
    """更新用户个人资料"""
    identity = get_jwt_identity()
    user_id = identity.get('user_id')
    data = request.get_json()
    
    if not data:
        return jsonify({'error': '无效的数据'}), 400
    
    # 不允许更新敏感字段
    for field in ['_id', 'password_hash', 'email']:
        if field in data:
            del data[field]
    
    # 更新用户资料
    data['updated_at'] = datetime.datetime.now()
    
    result = mongo.db.users.update_one(
        {'_id': ObjectId(user_id)},
        {'$set': data}
    )
    
    if result.modified_count == 0:
        return jsonify({'error': '更新失败或没有变更'}), 400
    
    # 获取更新后的用户信息
    updated_user = User.get_user_by_id(mongo, user_id)
    
    return jsonify({
        'message': '个人资料更新成功',
        'user': User.to_json(updated_user)
    })


@api.route('/auth/change-password', methods=['POST'])
@jwt_required()
def change_password():
    """修改密码"""
    identity = get_jwt_identity()
    user_id = identity.get('user_id')
    data = request.get_json()
    
    if not data:
        return jsonify({'error': '无效的数据'}), 400
    
    # 验证必填字段
    required_fields = ['old_password', 'new_password']
    for field in required_fields:
        if field not in data:
            return jsonify({'error': f'缺少必填字段: {field}'}), 400
    
    # 获取用户信息
    user = User.get_user_by_id(mongo, user_id)
    if not user:
        return jsonify({'error': '用户不存在'}), 401
    
    # 验证旧密码
    if not User.verify_password(user, data['old_password']):
        return jsonify({'error': '旧密码错误'}), 400
    
    # 更新密码
    updated_user = {
        'password_hash': User.generate_password_hash(data['new_password']),
        'updated_at': datetime.datetime.now()
    }
    
    result = mongo.db.users.update_one(
        {'_id': ObjectId(user_id)},
        {'$set': updated_user}
    )
    
    if result.modified_count == 0:
        return jsonify({'error': '密码更新失败'}), 400
    
    return jsonify({'message': '密码修改成功'})


@api.route('/auth/logout', methods=['POST'])
@jwt_required()
def logout():
    """用户登出（前端实现）"""
    # JWT不需要在服务器端存储状态，因此登出主要是前端删除令牌
    # 此API仅用于保持一致的API结构
    return jsonify({'message': '成功登出'}) 