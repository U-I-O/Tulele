import datetime
from bson import ObjectId
from ...utils.mongo_utils import parse_mongo_doc

class UserTrip:
    """用户旅行方案模型
    
    基于TripPlan，包含用户个性化内容，如团队成员、消息流、票夹、笔记等。
    """
    
    COLLECTION = 'userTrips'
    
    @staticmethod
    def create_user_trip(mongo, user_trip_data):
        """创建新用户旅行方案"""
        now = datetime.datetime.now()
        
        # 转换plan_id为ObjectId如果是字符串
        if 'plan_id' in user_trip_data and isinstance(user_trip_data['plan_id'], str):
            try:
                user_trip_data['plan_id'] = ObjectId(user_trip_data['plan_id'])
            except Exception:
                pass
        
        # 添加创建和更新时间戳
        user_trip_data['created_at'] = now
        user_trip_data['updated_at'] = now
        
        # 设置默认状态
        if 'status' not in user_trip_data:
            user_trip_data['status'] = 'planning'  # 默认为计划中状态
        
        # 初始化空列表字段
        for field in ['members', 'messages', 'tickets', 'feeds', 'notes']:
            if field not in user_trip_data:
                user_trip_data[field] = []
        
        result = mongo.db[UserTrip.COLLECTION].insert_one(user_trip_data)
        return result.inserted_id
    
    @staticmethod
    def get_user_trip_by_id(mongo, trip_id):
        """通过ID获取用户旅行方案"""
        try:
            return mongo.db[UserTrip.COLLECTION].find_one({'_id': ObjectId(trip_id)})
        except Exception:
            return None
    
    @staticmethod
    def get_user_trips_by_user(mongo, user_id, limit=20, skip=0):
        """获取用户的所有旅行方案"""
        cursor = mongo.db[UserTrip.COLLECTION].find(
            {'members.userId': user_id}
        ).sort('created_at', -1).skip(skip).limit(limit)
        return list(cursor)
    
    @staticmethod
    def update_user_trip(mongo, trip_id, update_data):
        """更新用户旅行方案"""
        # 不允许更新_id字段
        if '_id' in update_data:
            del update_data['_id']
            
        # 添加更新时间
        update_data['updated_at'] = datetime.datetime.now()
        
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
    
    @staticmethod
    def add_member(mongo, trip_id, member_data):
        """添加团队成员"""
        result = mongo.db[UserTrip.COLLECTION].update_one(
            {'_id': ObjectId(trip_id)},
            {
                '$push': {'members': member_data},
                '$set': {'updated_at': datetime.datetime.now()}
            }
        )
        return result.modified_count > 0
    
    @staticmethod
    def add_message(mongo, trip_id, message_data):
        """添加消息"""
        # 确保消息有时间戳
        if 'timestamp' not in message_data:
            message_data['timestamp'] = datetime.datetime.now()
            
        result = mongo.db[UserTrip.COLLECTION].update_one(
            {'_id': ObjectId(trip_id)},
            {
                '$push': {'messages': message_data},
                '$set': {'updated_at': datetime.datetime.now()}
            }
        )
        return result.modified_count > 0
    
    @staticmethod
    def add_ticket(mongo, trip_id, ticket_data):
        """添加票务凭证"""
        result = mongo.db[UserTrip.COLLECTION].update_one(
            {'_id': ObjectId(trip_id)},
            {
                '$push': {'tickets': ticket_data},
                '$set': {'updated_at': datetime.datetime.now()}
            }
        )
        return result.modified_count > 0
    
    @staticmethod
    def add_feed(mongo, trip_id, feed_data):
        """添加信息流"""
        # 确保信息有时间戳
        if 'timestamp' not in feed_data:
            feed_data['timestamp'] = datetime.datetime.now()
            
        result = mongo.db[UserTrip.COLLECTION].update_one(
            {'_id': ObjectId(trip_id)},
            {
                '$push': {'feeds': feed_data},
                '$set': {'updated_at': datetime.datetime.now()}
            }
        )
        return result.modified_count > 0
    
    @staticmethod
    def add_note(mongo, trip_id, note_data):
        """添加笔记"""
        # 确保笔记有时间戳
        if 'timestamp' not in note_data:
            note_data['timestamp'] = datetime.datetime.now()
            
        result = mongo.db[UserTrip.COLLECTION].update_one(
            {'_id': ObjectId(trip_id)},
            {
                '$push': {'notes': note_data},
                '$set': {'updated_at': datetime.datetime.now()}
            }
        )
        return result.modified_count > 0
    
    @staticmethod
    def to_json(user_trip):
        """将用户旅行方案数据转换为JSON格式"""
        if not user_trip:
            return None
            
        # 使用通用文档转换工具处理ObjectId等特殊类型
        return parse_mongo_doc(user_trip) 