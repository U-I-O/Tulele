# app/models/trips/trip_plan.py
import datetime
from bson import ObjectId
# 假设 utils 文件夹与 models 文件夹同级，都在 app 目录下
from ...utils.type_parsers import parse_mongo_doc # 从 type_parsers 导入

class TripPlan:
    """旅行规划模型
    
    用于描述一个可被复用的旅行方案模板或核心计划内容。
    """
    
    COLLECTION = 'tripPlans' # 集合名称
    
    @staticmethod
    def create_trip_plan(mongo, plan_data):
        """创建新旅行规划"""
        now = datetime.datetime.now(datetime.timezone.utc) # 使用带时区的时间
        
        # 日期字符串转换为 datetime 对象
        for date_field in ['startDate', 'endDate']:
            if date_field in plan_data and isinstance(plan_data[date_field], str):
                try:
                    plan_data[date_field] = datetime.datetime.strptime(plan_data[date_field], '%Y-%m-%d').replace(tzinfo=datetime.timezone.utc)
                except ValueError:
                    # 可以选择记录日志或抛出更具体的错误
                    plan_data[date_field] = None # 或者保持原样让 MongoDB 存储字符串，但不推荐
        
        if 'days' in plan_data and isinstance(plan_data['days'], list):
            for day in plan_data['days']:
                if 'date' in day and isinstance(day['date'], str):
                    try:
                        day['date'] = datetime.datetime.strptime(day['date'], '%Y-%m-%d').replace(tzinfo=datetime.timezone.utc)
                    except ValueError:
                        day['date'] = None
        
        plan_data['created_at'] = now
        plan_data['updated_at'] = now
        
        # 可以添加创建者信息，如果一个计划模板也有创建者
        # plan_data['creator_id'] = 'some_user_id_who_created_template'

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
    def get_trip_plans(mongo, filters=None, limit=20, skip=0, sort_by=None):
        """获取旅行规划列表 (例如用于模板市场或热门推荐)"""
        query_filters = filters if filters else {}
        
        sort_criteria = [('updated_at', -1)] # 默认排序
        if sort_by == 'rating': # 假设 TripPlan 也有评分，如果作为模板被评级
            sort_criteria = [('rating', -1), ('updated_at', -1)]
        # 可以添加更多排序选项

        cursor = mongo.db[TripPlan.COLLECTION].find(query_filters).sort(sort_criteria).skip(skip).limit(limit)
        return list(cursor)
    
    @staticmethod
    def update_trip_plan(mongo, plan_id, update_data):
        """更新旅行规划"""
        if '_id' in update_data:
            del update_data['_id']
            
        update_data['updated_at'] = datetime.datetime.now(datetime.timezone.utc)

        # 同样处理日期转换
        for date_field in ['startDate', 'endDate']:
            if date_field in update_data and isinstance(update_data[date_field], str):
                try:
                    update_data[date_field] = datetime.datetime.strptime(update_data[date_field], '%Y-%m-%d').replace(tzinfo=datetime.timezone.utc)
                except ValueError:
                    update_data[date_field] = None
        
        if 'days' in update_data and isinstance(update_data['days'], list):
            for day in update_data['days']:
                if 'date' in day and isinstance(day['date'], str):
                    try:
                        day['date'] = datetime.datetime.strptime(day['date'], '%Y-%m-%d').replace(tzinfo=datetime.timezone.utc)
                    except ValueError:
                        day['date'] = None
                        
        result = mongo.db[TripPlan.COLLECTION].update_one(
            {'_id': ObjectId(plan_id)},
            {'$set': update_data}
        )
        return result.modified_count > 0
    
    @staticmethod
    def delete_trip_plan(mongo, plan_id):
        """删除旅行规划"""
        result = mongo.db[TripPlan.COLLECTION].delete_one({'_id': ObjectId(plan_id)})
        # 注意：如果 UserTrip 正在引用此 plan_id，删除策略需要考虑
        # 可能是软删除，或者不允许删除被引用的计划
        return result.deleted_count > 0
    
    @staticmethod
    def to_json(trip_plan_doc):
        """将TripPlan文档转换为JSON友好的格式"""
        if not trip_plan_doc:
            return None
        return parse_mongo_doc(trip_plan_doc)