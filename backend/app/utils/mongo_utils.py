from bson import ObjectId
from flask import jsonify

def parse_mongo_doc(doc):
    """将MongoDB文档转换为JSON可序列化的格式
    
    主要处理ObjectId和日期时间类型
    """
    if not doc:
        return None
        
    if isinstance(doc, list):
        return [parse_mongo_doc(item) for item in doc]
    
    if isinstance(doc, dict):
        for key, value in doc.items():
            if isinstance(value, ObjectId):
                doc[key] = str(value)
            elif isinstance(value, (dict, list)):
                doc[key] = parse_mongo_doc(value)
        return doc
    
    return doc

def create_mongo_index(mongo, collection_name, fields, index_options=None):
    """创建MongoDB索引
    
    Args:
        mongo: PyMongo实例
        collection_name: 集合名称
        fields: 索引字段，例如 [('username', 1), ('email', 1)]
        index_options: 索引选项，例如 {'unique': True}
    """
    if index_options is None:
        index_options = {}
    
    try:
        mongo.db[collection_name].create_index(fields, **index_options)
        return True
    except Exception as e:
        print(f"创建索引失败: {e}")
        return False

def init_mongo_indexes(mongo):
    """初始化MongoDB索引"""
    # 用户集合索引
    create_mongo_index(mongo, 'users', [('username', 1)], {'unique': True})
    create_mongo_index(mongo, 'users', [('email', 1)], {'unique': True})
    
    # 旅行规划索引
    create_mongo_index(mongo, 'tripPlans', [('name', 1)])
    create_mongo_index(mongo, 'tripPlans', [('destination', 1)])
    create_mongo_index(mongo, 'tripPlans', [('tags', 1)])
    create_mongo_index(mongo, 'tripPlans', [('created_at', -1)])
    
    # 用户旅行方案索引
    create_mongo_index(mongo, 'userTrips', [('plan_id', 1)])
    create_mongo_index(mongo, 'userTrips', [('members.userId', 1)])
    create_mongo_index(mongo, 'userTrips', [('status', 1)])
    create_mongo_index(mongo, 'userTrips', [('created_at', -1)])