from flask import jsonify, request
from . import api # 从同级目录的 __init__.py 导入 api Blueprint
from ..models import TripPlan, UserTrip # 从父级目录的 models 导入
from .. import mongo # 从父级目录的 __init__.py 导入 mongo
import datetime
from bson.json_util import dumps # 用于更可靠的 MongoDB 到 JSON 转换
from bson import ObjectId # 用于处理 ObjectId

# --- TripPlan Endpoints (旅行规划模板) ---

@api.route('/trips/plans', methods=['GET'])
def get_trip_plans():
    """获取旅行规划模板列表"""
    limit = int(request.args.get('limit', 20))
    skip = int(request.args.get('skip', 0))
    sort_by = request.args.get('sort_by', None) # 例如 'rating', 'updated_at'
    
    filters = {}
    if 'destination' in request.args:
        filters['destination'] = {'$regex': request.args['destination'], '$options': 'i'}
    if 'tag' in request.args:
        filters['tags'] = {'$in': [request.args['tag']]} # 假设前端传单个tag
    elif 'tags' in request.args: # 如果前端可能传多个tag，用 getlist
        filters['tags'] = {'$in': request.args.getlist('tag')}
    
    trip_plans_cursor = TripPlan.get_trip_plans(mongo, filters=filters, limit=limit, skip=skip, sort_by=sort_by)
    
    # 如果需要获取总数用于分页
    # total_plans = mongo.db[TripPlan.COLLECTION].count_documents(filters)

    trip_plans_list = [TripPlan.to_json(plan) for plan in trip_plans_cursor]
    
    return jsonify({
        # 'total': total_plans, # 如果实现了总数获取
        'total': len(trip_plans_list), # 当前列表的长度，并非总数
        'plans': trip_plans_list
    })

@api.route('/trips/plans/<plan_id>', methods=['GET'])
def get_trip_plan(plan_id):
    """获取特定旅行规划模板的详情"""
    trip_plan_doc = TripPlan.get_trip_plan_by_id(mongo, plan_id)
    if not trip_plan_doc:
        return jsonify({'error': '未找到该旅行规划模板'}), 404
    return jsonify(TripPlan.to_json(trip_plan_doc))

@api.route('/trips/plans', methods=['POST'])
def create_trip_plan():
    """创建新的旅行规划模板"""
    data = request.get_json()
    if not data:
        return jsonify({'error': '无效的数据'}), 400
    
    required_fields = ['name', 'origin', 'destination', 'startDate', 'endDate'] # 模板的必填字段
    for field in required_fields:
        if field not in data:
            return jsonify({'error': f'缺少必需字段: {field}'}), 400
    
    try:
        plan_id = TripPlan.create_trip_plan(mongo, data)
        created_plan = TripPlan.get_trip_plan_by_id(mongo, plan_id) # 获取创建后的完整文档
        return jsonify({
            'message': '旅行规划模板创建成功',
            'plan': TripPlan.to_json(created_plan) # 返回创建的文档
        }), 201
    except Exception as e:
        return jsonify({'error': f'创建失败: {str(e)}'}), 500


@api.route('/trips/plans/<plan_id>', methods=['PUT'])
def update_trip_plan_route(plan_id): # 重命名函数避免与导入的 update_trip_plan 冲突
    """更新旅行规划模板"""
    data = request.get_json()
    if not data:
        return jsonify({'error': '无效的数据'}), 400
    
    if not TripPlan.get_trip_plan_by_id(mongo, plan_id): # 使用模型方法检查是否存在
        return jsonify({'error': '未找到该旅行规划模板'}), 404
    
    success = TripPlan.update_trip_plan(mongo, plan_id, data)
    if success:
        updated_plan = TripPlan.get_trip_plan_by_id(mongo, plan_id)
        return jsonify({
            'message': '旅行规划模板更新成功',
            'plan': TripPlan.to_json(updated_plan)
        })
    else:
        # 可能未找到或数据无变化也算更新不成功（取决于 modified_count）
        # 如果 modified_count 为 0 但文档存在，可以返回 200 OK 但提示无内容修改
        return jsonify({'error': '旅行规划模板更新失败或无内容修改'}), 500


@api.route('/trips/plans/<plan_id>', methods=['DELETE'])
def delete_trip_plan_route(plan_id): # 重命名函数
    """删除旅行规划模板"""
    if not TripPlan.get_trip_plan_by_id(mongo, plan_id):
        return jsonify({'error': '未找到该旅行规划模板'}), 404
    
    success = TripPlan.delete_trip_plan(mongo, plan_id)
    if success:
        return jsonify({'message': '旅行规划模板删除成功'}), 200 # 200 或 204 No Content
    else:
        return jsonify({'error': '旅行规划模板删除失败'}), 500

# --- UserTrip Endpoints (用户具体行程实例) ---

@api.route('/trips/user-trips', methods=['GET'])
def get_user_trips():
    """获取用户相关的旅行方案列表 (自己创建的或作为成员的)"""
    limit = int(request.args.get('limit', 20))
    skip = int(request.args.get('skip', 0))
    user_id = request.args.get('user_id')

    if not user_id:
        return jsonify({'error': '缺少user_id参数'}), 400
    
    # **处理 populate_plan 参数**
    populate_plan_arg = request.args.get('populate_plan', 'false').lower() == 'true'
    
    user_trips_cursor = UserTrip.get_user_trips_by_user(
        mongo, 
        user_id, 
        limit=limit, 
        skip=skip, 
        populate_plan=populate_plan_arg # **传递给模型方法**
    )
    user_trips_list = [UserTrip.to_json(trip) for trip in user_trips_cursor]
    
    # 如果需要总数
    # query_filters_for_count = {'$or': [{'creator_id': user_id}, {'members.userId': user_id}]}
    # total_user_trips = mongo.db[UserTrip.COLLECTION].count_documents(query_filters_for_count)

    return jsonify({
        # 'total': total_user_trips,
        'total': len(user_trips_list),
        'trips': user_trips_list
    })

# **新增的端点，用于获取方案市场中所有已发布的 UserTrip**
@api.route('/trips/market-user-trips', methods=['GET'])
def get_market_user_trips():
    """获取方案市场上所有已发布的旅行方案列表 (UserTrip instances)"""
    limit = int(request.args.get('limit', 10))
    skip = int(request.args.get('skip', 0))
    sort_by = request.args.get('sort_by', None) # 例如 'rating', 'popularity'
    
    filters = {}
    if 'destination' in request.args:
        filters['destination'] = {'$regex': request.args['destination'], '$options': 'i'}
    if 'tag' in request.args:
        filters['tags'] = {'$in': [request.args['tag']]}
    elif 'tags' in request.args:
        filters['tags'] = {'$in': request.args.getlist('tag')}
    
    # populate_plan 默认为 True 在 UserTrip.get_published_user_trips 中
    # 但前端可以显式传递，这里可以解析并传递，或者依赖模型的默认值
    populate_plan_arg = request.args.get('populate_plan', 'true').lower() == 'true'

    published_trips_cursor = UserTrip.get_published_user_trips(
        mongo, 
        filters=filters, 
        limit=limit, 
        skip=skip, 
        sort_by=sort_by,
        populate_plan=populate_plan_arg # **传递给模型方法**
    )
    published_trips_list = [UserTrip.to_json(trip) for trip in published_trips_cursor]

    # 如果需要总数
    # query_filters_for_count = {'publish_status': 'published'}
    # if filters: query_filters_for_count.update(filters)
    # total_published_trips = mongo.db[UserTrip.COLLECTION].count_documents(query_filters_for_count)
    
    return jsonify({
        # 'total': total_published_trips,
        'total': len(published_trips_list),
        'trips': published_trips_list
    })


@api.route('/trips/user-trips/<trip_id>', methods=['GET'])
def get_user_trip(trip_id):
    """获取特定用户旅行方案的详情"""
    populate_plan_arg = request.args.get('populate_plan', 'true').lower() == 'true' # 默认为true，让前端获取更完整信息
    
    user_trip_doc = UserTrip.get_user_trip_by_id(mongo, trip_id, populate_plan=populate_plan_arg)
    if not user_trip_doc:
        return jsonify({'error': '未找到该用户旅行方案'}), 404
    return jsonify(UserTrip.to_json(user_trip_doc))


@api.route('/trips/user-trips', methods=['POST'])
def create_user_trip():
    """创建新的用户旅行方案"""
    data = request.get_json()
    if not data:
        return jsonify({'error': '无效的数据'}), 400
    
    # UserTrip 模型内部会校验 creator_id
    # 前端应确保在调用此API时，已认证用户的信息(如user_id作为creator_id)被包含在 data 中
    # 例如，从 token 中解析出 user_id 并添加到 data['creator_id']
    # 这里假设前端或某个中间件已经处理了认证并将 creator_id 放入 data
    if 'creator_id' not in data: # 基本校验
        return jsonify({'error': '缺少创建者ID (creator_id)'}), 400
    
    # 验证其他必需字段
    # if 'plan_id' not in data and 'plan' not in data: # 'plan' 是旧的逻辑，UserTrip模型似乎不直接处理嵌套plan创建
    if 'plan_id' not in data and not ('name' in data and 'days' in data): # 要么基于模板，要么提供足够信息创建独立行程
         return jsonify({'error': "缺少 plan_id 或行程核心信息 (如 name, days)"}), 400

    try:
        trip_id = UserTrip.create_user_trip(mongo, data)
        created_trip = UserTrip.get_user_trip_by_id(mongo, trip_id, populate_plan=True) # 获取创建后的完整文档
        return jsonify({
            'message': '用户旅行方案创建成功',
            'trip': UserTrip.to_json(created_trip) # 返回创建的文档
        }), 201
    except ValueError as ve: # UserTrip 模型可能因缺少 creator_id 抛出 ValueError
        return jsonify({'error': str(ve)}), 400
    except Exception as e:
        return jsonify({'error': f'创建失败: {str(e)}'}), 500


@api.route('/trips/user-trips/<trip_id>', methods=['PUT'])
def update_user_trip_route(trip_id): # 重命名函数
    """更新用户旅行方案"""
    data = request.get_json()
    if not data:
        return jsonify({'error': '无效的数据'}), 400
    
    if not UserTrip.get_user_trip_by_id(mongo, trip_id): # 检查是否存在
        return jsonify({'error': '未找到该用户旅行方案'}), 404
    
    success = UserTrip.update_user_trip(mongo, trip_id, data)
    if success:
        updated_trip = UserTrip.get_user_trip_by_id(mongo, trip_id, populate_plan=True)
        return jsonify({
            'message': '用户旅行方案更新成功',
            'trip': UserTrip.to_json(updated_trip)
        })
    else:
        return jsonify({'error': '用户旅行方案更新失败或无内容修改'}), 500

@api.route('/trips/user-trips/<trip_id>', methods=['DELETE'])
def delete_user_trip_route(trip_id): # 重命名函数
    """删除用户旅行方案"""
    if not UserTrip.get_user_trip_by_id(mongo, trip_id):
        return jsonify({'error': '未找到该用户旅行方案'}), 404
        
    success = UserTrip.delete_user_trip(mongo, trip_id)
    if success:
        return jsonify({'message': '用户旅行方案删除成功'}), 200
    else:
        return jsonify({'error': '用户旅行方案删除失败'}), 500

# --- UserTrip 子资源操作 ---
@api.route('/trips/user-trips/<trip_id>/members', methods=['POST'])
def add_user_trip_member(trip_id):
    """添加旅行团队成员"""
    data = request.get_json()
    if not data: return jsonify({'error': '无效的数据'}), 400
    required_fields = ['userId', 'name'] # 假设成员数据至少需要userId和name
    for field in required_fields:
        if field not in data: return jsonify({'error': f'缺少必需字段: {field}'}), 400
    if not UserTrip.get_user_trip_by_id(mongo, trip_id): return jsonify({'error': '未找到该旅行方案'}), 404
    
    # 可以在此添加逻辑，如检查用户是否已经是成员等
    if UserTrip.add_member(mongo, trip_id, data):
        return jsonify({'message': '团队成员添加成功'}), 200
    return jsonify({'error': '团队成员添加失败'}), 500

@api.route('/trips/user-trips/<trip_id>/messages', methods=['POST'])
def add_user_trip_message(trip_id):
    """添加旅行消息"""
    data = request.get_json()
    if not data: return jsonify({'error': '无效的数据'}), 400
    required_fields = ['content'] # 假设消息至少需要content, senderId应由后端根据认证用户添加
    # 实际应用中，senderId, senderName, senderAvatar 等应从当前认证用户获取，不由前端传递
    # data['senderId'] = current_user.id 
    for field in required_fields:
        if field not in data: return jsonify({'error': f'缺少必需字段: {field}'}), 400
    if not UserTrip.get_user_trip_by_id(mongo, trip_id): return jsonify({'error': '未找到该旅行方案'}), 404
    
    if UserTrip.add_message(mongo, trip_id, data):
        return jsonify({'message': '消息添加成功'}), 200 # 也可以是201 Created，并返回创建的消息
    return jsonify({'error': '消息添加失败'}), 500

@api.route('/trips/user-trips/<trip_id>/tickets', methods=['POST'])
def add_user_trip_ticket(trip_id):
    """添加旅行票务"""
    data = request.get_json()
    if not data: return jsonify({'error': '无效的数据'}), 400
    required_fields = ['type', 'title']
    for field in required_fields:
        if field not in data: return jsonify({'error': f'缺少必需字段: {field}'}), 400
    if not UserTrip.get_user_trip_by_id(mongo, trip_id): return jsonify({'error': '未找到该旅行方案'}), 404
    
    if UserTrip.add_ticket(mongo, trip_id, data):
        return jsonify({'message': '票务添加成功'}), 200
    return jsonify({'error': '票务添加失败'}), 500

@api.route('/trips/user-trips/<trip_id>/notes', methods=['POST'])
def add_user_trip_note(trip_id):
    """添加行程级旅行笔记"""
    data = request.get_json()
    if not data: return jsonify({'error': '无效的数据'}), 400
    if 'content' not in data: return jsonify({'error': '缺少content字段'}), 400
    if not UserTrip.get_user_trip_by_id(mongo, trip_id): return jsonify({'error': '未找到该旅行方案'}), 404
        
    if UserTrip.add_note(mongo, trip_id, data):
        return jsonify({'message': '笔记添加成功'}), 200
    return jsonify({'error': '笔记添加失败'}), 500

# 如果有 Feeds 功能，也类似添加
@api.route('/trips/user-trips/<trip_id>/feeds', methods=['POST'])
def add_user_trip_feed(trip_id):
    """添加旅行动态 (Feed)"""
    data = request.get_json()
    if not data: return jsonify({'error': '无效的数据'}), 400
    # 根据 Feed 模型的实际字段进行校验
    if 'content' not in data: return jsonify({'error': '缺少content字段'}), 400
    if not UserTrip.get_user_trip_by_id(mongo, trip_id): return jsonify({'error': '未找到该旅行方案'}), 404
        
    if UserTrip.add_feed(mongo, trip_id, data): # 假设 UserTrip 模型有 add_feed 方法
        return jsonify({'message': '动态添加成功'}), 200
    return jsonify({'error': '动态添加失败'}), 500

# --- 行程分享功能 API端点 ---

@api.route('/trips/sharing/invitations', methods=['POST'])
def create_sharing_invitation():
    """创建新的行程分享邀请"""
    try:
        data = request.get_json()
        if not data:
            return jsonify({'error': '无效的数据'}), 400
        
        print(f"收到的邀请数据: {data}") # 调试日志
        
        required_fields = ['trip_id', 'sender_user_id', 'sender_name']
        for field in required_fields:
            if field not in data:
                return jsonify({'error': f'缺少必要字段: {field}'}), 400
        
        # 处理日期时间字段
        if 'expires_at' in data and isinstance(data['expires_at'], str):
            try:
                import datetime
                # 尝试解析日期时间字符串（移除Z并添加UTC标识）
                data['expires_at'] = datetime.datetime.fromisoformat(
                    data['expires_at'].replace('Z', '+00:00')
                )
            except ValueError as e:
                print(f"日期解析错误: {e}")
                # 默认设置为7天后过期
                data['expires_at'] = datetime.datetime.now(datetime.timezone.utc) + datetime.timedelta(days=7)
        
        from ..models import ShareInvitation
        
        # 验证行程是否存在
        trip_id = data['trip_id']
        from ..models import UserTrip
        trip = UserTrip.get_user_trip_by_id(mongo, trip_id)
        if not trip:
            return jsonify({'error': '行程不存在或已被删除'}), 404
            
        # 验证发送者是否有权限邀请（应是行程创建者或管理员）
        if trip['creator_id'] != data['sender_user_id']:
            # 检查是否是管理员成员
            is_admin = False
            for member in trip.get('members', []):
                if member.get('userId') == data['sender_user_id'] and member.get('role') in ['owner', 'admin']:
                    is_admin = True
                    break
            
            if not is_admin:
                return jsonify({'error': '您没有权限邀请其他人加入此行程'}), 403
        
        invitation_id = ShareInvitation.create_invitation(mongo, data)
        invitation = ShareInvitation.get_invitation_by_id(mongo, invitation_id)
        
        invitation_json = ShareInvitation.to_json(invitation)
        print(f"创建的邀请: {invitation_json}")  # 调试日志
        
        return jsonify({
            'message': '邀请创建成功',
            'invitation': invitation_json
        }), 201
    except ValueError as e:
        print(f"创建邀请时发生值错误: {e}")
        return jsonify({'error': str(e)}), 400
    except Exception as e:
        print(f"创建邀请时出错: {e}")
        return jsonify({'error': f'创建邀请失败: {str(e)}'}), 500


@api.route('/trips/sharing/invitations', methods=['GET'])
def get_sharing_invitations():
    """获取行程的所有分享邀请"""
    trip_id = request.args.get('trip_id')
    if not trip_id:
        return jsonify({'error': '缺少trip_id参数'}), 400
    
    try:
        from ..models import ShareInvitation
        invitations = ShareInvitation.get_invitations_by_trip(mongo, trip_id)
        return jsonify({
            'invitations': [ShareInvitation.to_json(invitation) for invitation in invitations]
        })
    except Exception as e:
        print(f"获取邀请列表时出错: {e}")
        return jsonify({'error': f'获取邀请列表失败: {str(e)}'}), 500


@api.route('/trips/sharing/invitations/<invitation_code>', methods=['GET'])
def get_invitation_by_code(invitation_code):
    """通过邀请码获取邀请详情"""
    try:
        from ..models import ShareInvitation
        invitation = ShareInvitation.get_invitation_by_code(mongo, invitation_code)
        
        if not invitation:
            return jsonify({'error': '邀请不存在或已失效'}), 404
        
        # 如果邀请已过期，返回特定消息
        now = datetime.datetime.now(datetime.timezone.utc)
        expires_at = invitation.get('expires_at')
        
        # 确保expires_at有时区信息
        if expires_at:
            if isinstance(expires_at, str):
                try:
                    expires_at = datetime.datetime.fromisoformat(expires_at.replace('Z', '+00:00'))
                except ValueError:
                    # 无法解析则假设未过期
                    expires_at = now + datetime.timedelta(days=1)
            
            # 确保时区信息存在
            if expires_at.tzinfo is None:
                expires_at = expires_at.replace(tzinfo=datetime.timezone.utc)
                
            if expires_at < now:
                return jsonify({'error': '邀请已过期', 'invitation': ShareInvitation.to_json(invitation)}), 410
        
        # 如果邀请已经接受或拒绝
        if invitation.get('status') != 'pending':
            status_message = '已接受' if invitation.get('status') == 'accepted' else '已拒绝'
            return jsonify({'message': f'邀请{status_message}', 'invitation': ShareInvitation.to_json(invitation)})
        
        # 获取行程信息，用于显示
        from ..models import UserTrip
        trip = UserTrip.get_user_trip_by_id(mongo, invitation['trip_id'])
        trip_info = {
            'id': str(trip['_id']),
            'name': trip.get('userTripNameOverride') or trip.get('displayName') or '未命名行程',
            'creator_name': None
        }
        
        # 尝试获取创建者信息
        for member in trip.get('members', []):
            if member.get('userId') == trip.get('creator_id'):
                trip_info['creator_name'] = member.get('name')
                break
        
        invitation_json = ShareInvitation.to_json(invitation)
        invitation_json['trip_info'] = trip_info
        
        return jsonify({'invitation': invitation_json})
    except Exception as e:
        print(f"获取邀请详情时出错: {e}")
        return jsonify({'error': f'获取邀请详情失败: {str(e)}'}), 500


@api.route('/trips/sharing/invitations/<invitation_code>/accept', methods=['POST'])
def accept_sharing_invitation(invitation_code):
    """接受分享邀请"""
    data = request.get_json() or {}
    user_id = data.get('user_id')
    user_name = data.get('user_name')
    avatar_url = data.get('avatar_url')
    
    if not user_id or not user_name:
        return jsonify({'error': '缺少用户信息'}), 400
    
    try:
        from ..models import ShareInvitation
        success, message = ShareInvitation.accept_invitation(
            mongo, invitation_code, user_id, user_name, avatar_url)
        
        if success:
            return jsonify({'message': message})
        else:
            return jsonify({'error': message}), 400
    except Exception as e:
        print(f"接受邀请时出错: {e}")
        return jsonify({'error': f'接受邀请失败: {str(e)}'}), 500


@api.route('/trips/sharing/invitations/<invitation_code>/reject', methods=['POST'])
def reject_sharing_invitation(invitation_code):
    """拒绝分享邀请"""
    try:
        from ..models import ShareInvitation
        success = ShareInvitation.reject_invitation(mongo, invitation_code)
        
        if success:
            return jsonify({'message': '已拒绝邀请'})
        else:
            return jsonify({'error': '邀请不存在或已失效'}), 404
    except Exception as e:
        print(f"拒绝邀请时出错: {e}")
        return jsonify({'error': f'拒绝邀请失败: {str(e)}'}), 500


@api.route('/trips/sharing/invitations/<invitation_id>', methods=['DELETE'])
def cancel_sharing_invitation(invitation_id):
    """取消（删除）分享邀请"""
    try:
        from ..models import ShareInvitation
        success = ShareInvitation.delete_invitation(mongo, invitation_id)
        
        if success:
            return jsonify({'message': '邀请已取消'})
        else:
            return jsonify({'error': '邀请不存在或已删除'}), 404
    except Exception as e:
        print(f"取消邀请时出错: {e}")
        return jsonify({'error': f'取消邀请失败: {str(e)}'}), 500