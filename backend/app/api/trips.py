from flask import jsonify, request
from . import api
from ..models import TripPlan, UserTrip
from .. import mongo
import datetime
from bson.json_util import dumps
from bson import ObjectId
import json

@api.route('/trips/plans', methods=['GET'])
def get_trip_plans():
    """获取旅行规划列表"""
    limit = int(request.args.get('limit', 20))
    skip = int(request.args.get('skip', 0))
    
    # 构建筛选条件
    filters = {}
    
    # 如果提供了目的地，添加筛选
    if 'destination' in request.args:
        filters['destination'] = {'$regex': request.args['destination'], '$options': 'i'}
    
    # 如果提供了标签，添加筛选
    if 'tag' in request.args:
        filters['tags'] = {'$in': [request.args['tag']]}
    
    trip_plans = TripPlan.get_trip_plans(mongo, filters, limit, skip)
    
    return jsonify({
        'total': len(trip_plans),
        'plans': [TripPlan.to_json(plan) for plan in trip_plans]
    })

@api.route('/trips/plans/<plan_id>', methods=['GET'])
def get_trip_plan(plan_id):
    """获取特定旅行规划的详情"""
    trip_plan = TripPlan.get_trip_plan_by_id(mongo, plan_id)
    
    if not trip_plan:
        return jsonify({'error': '未找到该旅行规划'}), 404
        
    return jsonify(TripPlan.to_json(trip_plan))

@api.route('/trips/plans', methods=['POST'])
def create_trip_plan():
    """创建新的旅行规划"""
    data = request.get_json()
    if not data:
        return jsonify({'error': '无效的数据'}), 400
    
    # 验证必需字段
    required_fields = ['name', 'origin', 'destination', 'startDate', 'endDate']
    for field in required_fields:
        if field not in data:
            return jsonify({'error': f'缺少必需字段: {field}'}), 400
    
    # 创建旅行规划
    plan_id = TripPlan.create_trip_plan(mongo, data)
    
    return jsonify({
        'message': '旅行规划创建成功',
        'plan_id': str(plan_id)
    }), 201

@api.route('/trips/plans/<plan_id>', methods=['PUT'])
def update_trip_plan(plan_id):
    """更新旅行规划"""
    data = request.get_json()
    if not data:
        return jsonify({'error': '无效的数据'}), 400
    
    # 检查旅行规划是否存在
    if not TripPlan.get_trip_plan_by_id(mongo, plan_id):
        return jsonify({'error': '未找到该旅行规划'}), 404
    
    # 更新旅行规划
    success = TripPlan.update_trip_plan(mongo, plan_id, data)
    
    if success:
        return jsonify({'message': '旅行规划更新成功'})
    else:
        return jsonify({'error': '旅行规划更新失败'}), 500

@api.route('/trips/plans/<plan_id>', methods=['DELETE'])
def delete_trip_plan(plan_id):
    """删除旅行规划"""
    # 检查旅行规划是否存在
    if not TripPlan.get_trip_plan_by_id(mongo, plan_id):
        return jsonify({'error': '未找到该旅行规划'}), 404
    
    # 删除旅行规划
    success = TripPlan.delete_trip_plan(mongo, plan_id)
    
    if success:
        return jsonify({'message': '旅行规划删除成功'})
    else:
        return jsonify({'error': '旅行规划删除失败'}), 500

@api.route('/trips/user-trips', methods=['GET'])
def get_user_trips():
    """获取用户旅行方案列表"""
    limit = int(request.args.get('limit', 20))
    skip = int(request.args.get('skip', 0))
    
    # 需要提供用户ID
    user_id = request.args.get('user_id')
    if not user_id:
        return jsonify({'error': '缺少user_id参数'}), 400
    
    user_trips = UserTrip.get_user_trips_by_user(mongo, user_id, limit, skip)
    
    return jsonify({
        'total': len(user_trips),
        'trips': [UserTrip.to_json(trip) for trip in user_trips]
    })

@api.route('/trips/user-trips/<trip_id>', methods=['GET'])
def get_user_trip(trip_id):
    """获取特定用户旅行方案的详情"""
    user_trip = UserTrip.get_user_trip_by_id(mongo, trip_id)
    
    if not user_trip:
        return jsonify({'error': '未找到该旅行方案'}), 404
        
    return jsonify(UserTrip.to_json(user_trip))

@api.route('/trips/user-trips', methods=['POST'])
def create_user_trip():
    """创建新的用户旅行方案"""
    data = request.get_json()
    if not data:
        return jsonify({'error': '无效的数据'}), 400
    
    # 验证必需字段
    if 'plan_id' not in data and 'plan' not in data:
        return jsonify({'error': '缺少plan_id或plan字段'}), 400
    
    # 创建用户旅行方案
    trip_id = UserTrip.create_user_trip(mongo, data)
    
    return jsonify({
        'message': '用户旅行方案创建成功',
        'trip_id': str(trip_id)
    }), 201

@api.route('/trips/user-trips/<trip_id>', methods=['PUT'])
def update_user_trip(trip_id):
    """更新用户旅行方案"""
    data = request.get_json()
    if not data:
        return jsonify({'error': '无效的数据'}), 400
    
    # 检查用户旅行方案是否存在
    if not UserTrip.get_user_trip_by_id(mongo, trip_id):
        return jsonify({'error': '未找到该旅行方案'}), 404
    
    # 更新用户旅行方案
    success = UserTrip.update_user_trip(mongo, trip_id, data)
    
    if success:
        return jsonify({'message': '用户旅行方案更新成功'})
    else:
        return jsonify({'error': '用户旅行方案更新失败'}), 500

@api.route('/trips/user-trips/<trip_id>/members', methods=['POST'])
def add_user_trip_member(trip_id):
    """添加旅行团队成员"""
    data = request.get_json()
    if not data:
        return jsonify({'error': '无效的数据'}), 400
    
    # 验证必需字段
    required_fields = ['userId', 'name']
    for field in required_fields:
        if field not in data:
            return jsonify({'error': f'缺少必需字段: {field}'}), 400
    
    # 检查用户旅行方案是否存在
    if not UserTrip.get_user_trip_by_id(mongo, trip_id):
        return jsonify({'error': '未找到该旅行方案'}), 404
    
    # 添加团队成员
    success = UserTrip.add_member(mongo, trip_id, data)
    
    if success:
        return jsonify({'message': '团队成员添加成功'})
    else:
        return jsonify({'error': '团队成员添加失败'}), 500

@api.route('/trips/user-trips/<trip_id>/messages', methods=['POST'])
def add_user_trip_message(trip_id):
    """添加旅行消息"""
    data = request.get_json()
    if not data:
        return jsonify({'error': '无效的数据'}), 400
    
    # 验证必需字段
    required_fields = ['content', 'type']
    for field in required_fields:
        if field not in data:
            return jsonify({'error': f'缺少必需字段: {field}'}), 400
    
    # 检查用户旅行方案是否存在
    if not UserTrip.get_user_trip_by_id(mongo, trip_id):
        return jsonify({'error': '未找到该旅行方案'}), 404
    
    # 添加消息
    data['timestamp'] = datetime.datetime.now()
    success = UserTrip.add_message(mongo, trip_id, data)
    
    if success:
        return jsonify({'message': '消息添加成功'})
    else:
        return jsonify({'error': '消息添加失败'}), 500

@api.route('/trips/user-trips/<trip_id>/tickets', methods=['POST'])
def add_user_trip_ticket(trip_id):
    """添加旅行票务"""
    data = request.get_json()
    if not data:
        return jsonify({'error': '无效的数据'}), 400
    
    # 验证必需字段
    required_fields = ['type', 'title']
    for field in required_fields:
        if field not in data:
            return jsonify({'error': f'缺少必需字段: {field}'}), 400
    
    # 检查用户旅行方案是否存在
    if not UserTrip.get_user_trip_by_id(mongo, trip_id):
        return jsonify({'error': '未找到该旅行方案'}), 404
    
    # 添加票务
    success = UserTrip.add_ticket(mongo, trip_id, data)
    
    if success:
        return jsonify({'message': '票务添加成功'})
    else:
        return jsonify({'error': '票务添加失败'}), 500

@api.route('/trips/user-trips/<trip_id>/notes', methods=['POST'])
def add_user_trip_note(trip_id):
    """添加旅行笔记"""
    data = request.get_json()
    if not data:
        return jsonify({'error': '无效的数据'}), 400
    
    # 验证必需字段
    if 'content' not in data:
        return jsonify({'error': '缺少content字段'}), 400
    
    # 检查用户旅行方案是否存在
    if not UserTrip.get_user_trip_by_id(mongo, trip_id):
        return jsonify({'error': '未找到该旅行方案'}), 404
    
    # 添加笔记
    data['timestamp'] = datetime.datetime.now()
    success = UserTrip.add_note(mongo, trip_id, data)
    
    if success:
        return jsonify({'message': '笔记添加成功'})
    else:
        return jsonify({'error': '笔记添加失败'}), 500 