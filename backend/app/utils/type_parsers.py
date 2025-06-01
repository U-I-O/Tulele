# backend/app/utils/type_parsers.py
from bson import ObjectId
import datetime

def parse_mongo_doc(doc):
    """将MongoDB文档转换为JSON可序列化的格式
    
    主要处理ObjectId和日期时间类型
    """
    if not doc:
        return None
        
    if isinstance(doc, list):
        return [parse_mongo_doc(item) for item in doc]
    
    parsed_doc = {}
    if isinstance(doc, dict):
        for key, value in doc.items():
            if isinstance(value, ObjectId):
                parsed_doc[key] = str(value)
            elif isinstance(value, datetime.datetime): # 将 datetime 对象转为 ISO 格式字符串
                parsed_doc[key] = value.isoformat()
            elif isinstance(value, (dict, list)): # 递归处理嵌套的字典和列表
                parsed_doc[key] = parse_mongo_doc(value)
            else:
                parsed_doc[key] = value
        return parsed_doc
    
    # 对于非字典、列表、ObjectId、datetime 的其他类型直接返回
    # 例如，如果 doc 本身就是一个字符串、数字或布尔值
    return doc