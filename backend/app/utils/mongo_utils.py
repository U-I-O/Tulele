# app/utils/mongo_utils.py
from bson import ObjectId
import datetime

# 确保导入 UserTrip 和 TripPlan 以便访问 COLLECTION 名称
from ..models.trips.user_trip import UserTrip
from ..models.trips.trip_plan import TripPlan # 现在需要导入 TripPlan


# parse_mongo_doc 函数已移至 type_parsers.py (假设你已采纳方案二)
# 如果未采纳方案二，则 parse_mongo_doc 定义仍在此处，
# 并且 user_trip.py 和 trip_plan.py 中的导入路径需要指向这里

def create_mongo_index(mongo, collection_name, fields, index_options=None):
    """创建MongoDB索引"""
    if index_options is None:
        index_options = {}
    
    try:
        mongo.db[collection_name].create_index(fields, **index_options)
        print(f"索引创建成功: {collection_name} -> {fields}")
        return True
    except Exception as e:
        print(f"创建索引失败: {collection_name} -> {fields}, 错误: {e}")
        return False

def init_mongo_indexes(mongo):
    """初始化MongoDB索引"""
    print("开始初始化MongoDB索引...")
    # 用户集合索引 (保持不变)
    create_mongo_index(mongo, 'users', [('username', 1)], {'unique': True})
    create_mongo_index(mongo, 'users', [('email', 1)], {'unique': True})
    
    # TripPlan 集合索引 (核心行程计划)
    create_mongo_index(mongo, TripPlan.COLLECTION, [('name', 1)])
    create_mongo_index(mongo, TripPlan.COLLECTION, [('destination', 1)])
    create_mongo_index(mongo, TripPlan.COLLECTION, [('tags', 1)])
    create_mongo_index(mongo, TripPlan.COLLECTION, [('updated_at', -1)])
    create_mongo_index(mongo, TripPlan.COLLECTION, [('created_at', -1)])
    # 可以为 TripPlan 添加 creator_id (如果模板有创建者) 和可能的公开/热门标志索引
    # create_mongo_index(mongo, TripPlan.COLLECTION, [('is_public_template', 1), ('rating', -1)])


    # UserTrip 集合索引 (用户特定的行程实例)
    create_mongo_index(mongo, UserTrip.COLLECTION, [('plan_id', 1)]) # 核心关联字段
    create_mongo_index(mongo, UserTrip.COLLECTION, [('creator_id', 1)])
    create_mongo_index(mongo, UserTrip.COLLECTION, [('members.userId', 1)])
    create_mongo_index(mongo, UserTrip.COLLECTION, [('publish_status', 1)])
    create_mongo_index(mongo, UserTrip.COLLECTION, [('travel_status', 1)])
    create_mongo_index(mongo, UserTrip.COLLECTION, [('updated_at', -1)])
    create_mongo_index(mongo, UserTrip.COLLECTION, [('created_at', -1)])
    
    # 用于方案市场查询 UserTrip (如果 UserTrip 也有评分等属性)
    # create_mongo_index(mongo, UserTrip.COLLECTION, [('rating', -1), ('publish_status', 1)])
    # create_mongo_index(mongo, UserTrip.COLLECTION, [('price_display', 1), ('publish_status', 1)])
    
    # 验证码集合索引
    create_mongo_index(mongo, 'verification_codes', [('email', 1), ('purpose', 1)])
    create_mongo_index(mongo, 'verification_codes', [('code', 1)])
    create_mongo_index(mongo, 'verification_codes', [('expires_at', 1)])
    create_mongo_index(mongo, 'verification_codes', [('used', 1)])
        
    print("MongoDB索引初始化完成。")