# app/models/trips/user_trip.py
import datetime
from bson import ObjectId
from ...utils.type_parsers import parse_mongo_doc # 从 type_parsers 导入

class UserTrip:
    """用户旅行方案模型
    
    代表用户的一个具体行程实例，关联一个TripPlan，并包含用户特定的信息。
    """
    
    COLLECTION = 'userTrips'
    
    @staticmethod
    def create_user_trip(mongo, user_trip_data):
        """创建新用户旅行方案"""
        now = datetime.datetime.now(datetime.timezone.utc)
        
        # 确保 plan_id 是 ObjectId 类型
        if 'plan_id' in user_trip_data and isinstance(user_trip_data['plan_id'], str):
            try:
                user_trip_data['plan_id'] = ObjectId(user_trip_data['plan_id'])
            except Exception as e:
                # 处理无效的 plan_id 字符串，可能抛出错误或返回None
                print(f"Error converting plan_id to ObjectId: {e}")
                # return None # 或者根据业务逻辑处理
                pass # 暂时允许，但理想情况下应校验plan_id有效性

        user_trip_data['created_at'] = now
        user_trip_data['updated_at'] = now
        
        # 发布状态: draft, pending_review, published, rejected, archived
        if 'publish_status' not in user_trip_data:
            user_trip_data['publish_status'] = 'draft'
            
        # 旅行执行状态: planning, traveling, completed
        if 'travel_status' not in user_trip_data:
            user_trip_data['travel_status'] = 'planning'

        # 创建者信息 (必须)
        if 'creator_id' not in user_trip_data:
            # 应该从认证用户获取，这里作为示例可以抛错或设置默认
            raise ValueError("creator_id is required to create a UserTrip")
            
        # 初始化空列表字段
        for field in ['members', 'messages', 'tickets', 'feeds', 'notes']:
            if field not in user_trip_data or user_trip_data[field] is None:
                user_trip_data[field] = []
        
        # 确保创建者是成员之一 (如果业务逻辑需要)
        is_creator_member = False
        if 'creator_id' in user_trip_data:
            for member in user_trip_data.get('members', []):
                if member.get('userId') == user_trip_data['creator_id']:
                    is_creator_member = True
                    break
            if not is_creator_member: # 如果创建者不在成员列表中，自动添加
                user_trip_data['members'].append({
                    "userId": user_trip_data['creator_id'],
                    "name": user_trip_data.get('creator_name', '创建者'), # 最好从用户服务获取
                    "avatarUrl": user_trip_data.get('creator_avatar', ''),
                    "role": "owner" # 或 'leader'
                })
        
        result = mongo.db[UserTrip.COLLECTION].insert_one(user_trip_data)
        return result.inserted_id
    
    @staticmethod
    def get_user_trip_by_id(mongo, trip_id, populate_plan=False):
        """通过ID获取用户旅行方案。
        如果 populate_plan 为 True，则尝试聚合关联的 TripPlan 数据。
        """
        try:
            user_trip_doc = mongo.db[UserTrip.COLLECTION].find_one({'_id': ObjectId(trip_id)})
            if user_trip_doc and populate_plan and 'plan_id' in user_trip_doc:
                from .trip_plan import TripPlan # 局部导入避免循环
                plan_doc = mongo.db[TripPlan.COLLECTION].find_one({'_id': user_trip_doc['plan_id']})
                if plan_doc:
                    # 将 TripPlan 的字段（除_id外）合并到 UserTrip 文档中返回
                    # 注意：这是一种反规范化，在读取时进行。另一种方式是前端分别请求。
                    plan_details = {k: v for k, v in plan_doc.items() if k != '_id'}
                    user_trip_doc['plan_details'] = plan_details 
            return user_trip_doc
        except Exception:
            return None
            
    @staticmethod
    def get_user_trips_by_user(mongo, user_id, limit=20, skip=0, populate_plan=False):
        """获取用户相关的旅行方案 (自己创建的或作为成员的)"""
        query_filters = {
            '$or': [
                {'creator_id': user_id},
                {'members.userId': user_id}
            ]
        }
        
        if populate_plan:
            # 使用聚合操作来联接 TripPlan 数据
            pipeline = [
                {'$match': query_filters},
                {'$sort': {'updated_at': -1}},
                {'$skip': skip},
                {'$limit': limit},
                {
                    '$lookup': {
                        'from': 'tripPlans',  # TripPlan 集合的名称
                        'localField': 'plan_id',
                        'foreignField': '_id',
                        'as': 'plan_details_array' # 结果会是一个数组
                    }
                },
                { # 将 plan_details_array (通常只有一个元素) 转换为对象或保留数组
                    '$addFields': {
                        'plan_details': {'$arrayElemAt': ['$plan_details_array', 0]}
                    }
                },
                {'$project': {'plan_details_array': 0}} # 移除临时的数组字段
            ]
            cursor = mongo.db[UserTrip.COLLECTION].aggregate(pipeline)
        else:
            cursor = mongo.db[UserTrip.COLLECTION].find(query_filters).sort('updated_at', -1).skip(skip).limit(limit)
        
        return list(cursor)

    @staticmethod
    def get_published_user_trips(mongo, filters=None, limit=20, skip=0, sort_by=None, populate_plan=True):
        """获取已发布的旅行方案 (用于方案市场)，并默认填充计划详情"""
        query_filters = {'publish_status': 'published'}
        if filters:
            query_filters.update(filters)
        
        sort_criteria = [('updated_at', -1)]
        if sort_by == 'rating':
            sort_criteria = [('rating', -1), ('updated_at', -1)] # 假设 UserTrip 有 rating
        elif sort_by == 'popularity':
             sort_criteria = [('reviewCount', -1), ('updated_at', -1)] # 假设 UserTrip 有 reviewCount

        if populate_plan:
            pipeline = [
                {'$match': query_filters},
                {'$sort': dict(sort_criteria)}, # sort 需要字典
                {'$skip': skip},
                {'$limit': limit},
                {
                    '$lookup': {
                        'from': 'tripPlans',
                        'localField': 'plan_id',
                        'foreignField': '_id',
                        'as': 'plan_details_array'
                    }
                },
                {'$addFields': {'plan_details': {'$arrayElemAt': ['$plan_details_array', 0]}}},
                {'$project': {'plan_details_array': 0}}
            ]
            cursor = mongo.db[UserTrip.COLLECTION].aggregate(pipeline)
        else:
            cursor = mongo.db[UserTrip.COLLECTION].find(query_filters).sort(sort_criteria).skip(skip).limit(limit)
        return list(cursor)
    
    @staticmethod
    def update_user_trip(mongo, trip_id, update_data):
        """更新用户旅行方案的特定字段（如状态、成员、笔记等）"""
        if '_id' in update_data:
            del update_data['_id']
        if 'plan_id' in update_data: # 通常不应更新plan_id，除非是特殊操作
            del update_data['plan_id'] 
            
        update_data['updated_at'] = datetime.datetime.now(datetime.timezone.utc)
        
        result = mongo.db[UserTrip.COLLECTION].update_one(
            {'_id': ObjectId(trip_id)},
            {'$set': update_data}
        )
        return result.modified_count > 0
    
    @staticmethod
    def delete_user_trip(mongo, trip_id):
        """删除用户旅行方案"""
        result = mongo.db[UserTrip.COLLECTION].delete_one({'_id': ObjectId(trip_id)})
        return result.deleted_count > 0
        
    # --- 子文档操作方法 (add_member, add_message, etc.) ---
    # 这些方法现在直接操作 UserTrip 中的数组字段，与之前类似
    @staticmethod
    def add_member(mongo, trip_id, member_data):
        result = mongo.db[UserTrip.COLLECTION].update_one(
            {'_id': ObjectId(trip_id)},
            {'$push': {'members': member_data}, '$set': {'updated_at': datetime.datetime.now(datetime.timezone.utc)}}
        )
        return result.modified_count > 0
    
    @staticmethod
    def add_message(mongo, trip_id, message_data):
        if 'timestamp' not in message_data: message_data['timestamp'] = datetime.datetime.now(datetime.timezone.utc)
        if 'id' not in message_data: message_data['id'] = str(ObjectId())
        result = mongo.db[UserTrip.COLLECTION].update_one(
            {'_id': ObjectId(trip_id)},
            {'$push': {'messages': message_data}, '$set': {'updated_at': datetime.datetime.now(datetime.timezone.utc)}}
        )
        return result.modified_count > 0

    @staticmethod
    def add_ticket(mongo, trip_id, ticket_data):
        if 'id' not in ticket_data: ticket_data['id'] = str(ObjectId())
        result = mongo.db[UserTrip.COLLECTION].update_one(
            {'_id': ObjectId(trip_id)},
            {'$push': {'tickets': ticket_data}, '$set': {'updated_at': datetime.datetime.now(datetime.timezone.utc)}}
        )
        return result.modified_count > 0

    @staticmethod
    def add_note(mongo, trip_id, note_data): # 行程级笔记
        if 'timestamp' not in note_data: note_data['timestamp'] = datetime.datetime.now(datetime.timezone.utc)
        if 'id' not in note_data: note_data['id'] = str(ObjectId())
        result = mongo.db[UserTrip.COLLECTION].update_one(
            {'_id': ObjectId(trip_id)},
            {'$push': {'notes': note_data}, '$set': {'updated_at': datetime.datetime.now(datetime.timezone.utc)}}
        )
        return result.modified_count > 0
    
    @staticmethod
    def add_feed(mongo, trip_id, feed_data):
        if 'timestamp' not in feed_data: feed_data['timestamp'] = datetime.datetime.now(datetime.timezone.utc)
        if 'id' not in feed_data: feed_data['id'] = str(ObjectId())
        result = mongo.db[UserTrip.COLLECTION].update_one(
            {'_id': ObjectId(trip_id)},
            {'$push': {'feeds': feed_data}, '$set': {'updated_at': datetime.datetime.now(datetime.timezone.utc)}}
        )
        return result.modified_count > 0

    @staticmethod
    def to_json(user_trip_doc):
        """将UserTrip文档转换为JSON友好的格式"""
        if not user_trip_doc:
            return None
        return parse_mongo_doc(user_trip_doc)