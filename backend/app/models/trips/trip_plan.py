import datetime
from bson import ObjectId
from ...utils.mongo_utils import parse_mongo_doc

class TripPlan:
    """旅行规划模型
    
    用于描述一个可被复用的旅行方案，包含基础信息、标签、每日活动等。
    字段包括：
    - _id: ObjectId，MongoDB自动生成的唯一标识
    - name: 行程名称
    - origin: 出发地
    - destination: 目的地
    - startDate: 开始日期
    - endDate: 结束日期
    - tags: 特征标签数组
    - description: 行程简介
    - coverImage: 行程封面图片URL
    - days: 每日行程安排数组
    - created_at: 创建时间
    - updated_at: 更新时间
    """
    
    COLLECTION = 'tripPlans'
    
    @staticmethod
    def create_trip_plan(mongo, plan_data):
        """创建新旅行规划"""
        now = datetime.datetime.now()
        
        # 转换日期字符串为日期对象
        if 'startDate' in plan_data and isinstance(plan_data['startDate'], str):
            try:
                plan_data['startDate'] = datetime.datetime.strptime(plan_data['startDate'], '%Y-%m-%d')
            except ValueError:
                pass
                
        if 'endDate' in plan_data and isinstance(plan_data['endDate'], str):
            try:
                plan_data['endDate'] = datetime.datetime.strptime(plan_data['endDate'], '%Y-%m-%d')
            except ValueError:
                pass
        
        # 处理每日行程中的日期
        if 'days' in plan_data and isinstance(plan_data['days'], list):
            for day in plan_data['days']:
                if 'date' in day and isinstance(day['date'], str):
                    try:
                        day['date'] = datetime.datetime.strptime(day['date'], '%Y-%m-%d')
                    except ValueError:
                        pass
        
        # 设置默认封面图片，如果未提供
        if 'coverImage' not in plan_data:
            plan_data['coverImage'] = ""
        
        # 添加创建和更新时间戳
        plan_data['created_at'] = now
        plan_data['updated_at'] = now
        
        result = mongo.db[TripPlan.COLLECTION].insert_one(plan_data)
        return result.inserted_id
    
    @staticmethod
    def get_trip_plan_by_id(mongo, plan_id):
        """通过ID获取旅行规划"""
        try:
            return mongo.db[TripPlan.COLLECTION].find_one({'_id': ObjectId(plan_id)})
        except Exception:
            return None
    
    @staticmethod
    def get_trip_plans(mongo, filters=None, limit=20, skip=0):
        """获取旅行规划列表"""
        if filters is None:
            filters = {}
            
        cursor = mongo.db[TripPlan.COLLECTION].find(filters).sort('created_at', -1).skip(skip).limit(limit)
        return list(cursor)
    
    @staticmethod
    def update_trip_plan(mongo, plan_id, update_data):
        """更新旅行规划"""
        # 不允许更新_id字段
        if '_id' in update_data:
            del update_data['_id']
            
        # 添加更新时间
        update_data['updated_at'] = datetime.datetime.now()
        
        result = mongo.db[TripPlan.COLLECTION].update_one(
            {'_id': ObjectId(plan_id)},
            {'$set': update_data}
        )
        return result.modified_count > 0
    
    @staticmethod
    def delete_trip_plan(mongo, plan_id):
        """删除旅行规划"""
        result = mongo.db[TripPlan.COLLECTION].delete_one({'_id': ObjectId(plan_id)})
        return result.deleted_count > 0
    
    @staticmethod
    def to_json(trip_plan):
        """将旅行规划数据转换为JSON格式"""
        if not trip_plan:
            return None
            
        # 使用通用文档转换工具处理ObjectId等特殊类型
        return parse_mongo_doc(trip_plan) 