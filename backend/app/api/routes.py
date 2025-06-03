from flask import jsonify, request
from . import api
from ..models import User
from .. import mongo
import datetime
from bson.json_util import dumps
import json

@api.route('/test', methods=['GET'])
def test():
    """测试API连接"""
    return jsonify({
        'message': '后端API连接成功',
        'timestamp': datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    })

@api.route('/users', methods=['GET'])
def get_users():
    """获取所有用户信息"""
    users = list(mongo.db.users.find({}, {'password_hash': 0}))
    # 将ObjectId转换为字符串
    for user in users:
        user['_id'] = str(user['_id'])
    
    return jsonify({
        'message': '获取用户列表成功',
        'users': users
    })

@api.route('/users', methods=['POST'])
def create_user():
    """创建新用户"""
    data = request.get_json()
    if not data:
        return jsonify({'error': '无效的数据'}), 400
    
    # 检查必填字段
    required_fields = ['username', 'email', 'password']
    for field in required_fields:
        if field not in data:
            return jsonify({'error': f'缺少必填字段: {field}'}), 400
    
    # 检查用户是否已存在
    if mongo.db.users.find_one({'username': data['username']}):
        return jsonify({'error': '用户名已存在'}), 400
    
    if mongo.db.users.find_one({'email': data['email']}):
        return jsonify({'error': '邮箱已存在'}), 400
    
    # 创建新用户
    user_id = User.create_user(mongo, data['username'], data['email'], data['password'])
    
    return jsonify({
        'message': '用户创建成功',
        'user': {
            'id': str(user_id),
            'username': data['username'],
            'email': data['email']
        }
    }), 201