# seed_database.py
import pymongo
from datetime import datetime, timezone
from bson import ObjectId

MONGO_URI = "mongodb://localhost:27017/"
DATABASE_NAME = "flutter_dev"
TRIP_PLANS_COLLECTION = 'tripPlans'
USER_TRIPS_COLLECTION = 'userTrips'

def seed_trip_plans(db):
    print(f"Seeding {TRIP_PLANS_COLLECTION}...")
    
    trip_plans_data = [
        {
            "_id": ObjectId("60c72b928f1b2b001c8e4b1a"), # 固定ID
            "name": "三亚海岛度假计划模板",
            "origin": "上海",
            "destination": "海南三亚",
            "startDate": datetime(2025, 6, 1, 0, 0, 0, tzinfo=timezone.utc),
            "endDate": datetime(2025, 6, 5, 0, 0, 0, tzinfo=timezone.utc),
            "tags": ["亲子", "海岛", "休闲"],
            "description": "一个标准的三亚5日亲子游行程计划，包含主要景点和活动建议。",
            "coverImage": "https://images.unsplash.com/photo-1507525428034-b723cf961d3e?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8Mnx8YmVhY2h8ZW58MHx8MHx8fDA%3D&auto=format&fit=crop&w=800&q=60",
            "days": [
                {
                    "day_number": 1,
                    "date": datetime(2025, 6, 1, 0, 0, 0, tzinfo=timezone.utc),
                    "activities": [
                        {"id": str(ObjectId()), "title": "抵达三亚，入住酒店", "location": "亚龙湾度假酒店", "startTime": "14:00", "endTime": "15:00", "note": "办理入住"},
                        {"id": str(ObjectId()), "title": "亚龙湾沙滩玩耍", "location": "亚龙湾沙滩", "startTime": "16:00", "endTime": "18:00"}
                    ],
                    "notes": "第一天轻松适应。"
                },
                {
                    "day_number": 2,
                    "date": datetime(2025, 6, 2, 0, 0, 0, tzinfo=timezone.utc),
                    "activities": [ {"id": str(ObjectId()), "title": "蜈支洲岛一日游", "location": "蜈支洲岛", "startTime": "09:00", "endTime": "17:00"}],
                     "notes": ""
                }
            ],
            # 可以有 rating, reviewCount, isFeatured 等字段，如果这个 plan 是一个热门/公共模板
            "rating": 4.9,
            "reviewCount": 150,
            "isPublicTemplate": True, # 标记为公共模板
            "price_if_published_by_creator": 39.90, # 模板的建议售价（如果创建者发布）
            "created_at": datetime.now(timezone.utc),
            "updated_at": datetime.now(timezone.utc)
        },
        {
            "_id": ObjectId("60c72b928f1b2b001c8e4b1b"),
            "name": "北京文化探索计划",
            "origin": "广州",
            "destination": "中国北京",
            "startDate": datetime(2025, 7, 15, 0, 0, 0, tzinfo=timezone.utc),
            "endDate": datetime(2025, 7, 18, 0, 0, 0, tzinfo=timezone.utc),
            "tags": ["文化", "历史", "古迹"],
            "description": "深度探索北京的历史文化。",
            "coverImage": "https://images.unsplash.com/photo-1547981609-4b6bfe67ca0b?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8NHx8YmVpamluZ3xlbnwwfHwwfHx8MA%3D%3D&auto=format&fit=crop&w=800&q=60",
            "days": [], # 可以后续添加
            "isPublicTemplate": True,
            "rating": 4.7,
            "reviewCount": 95,
            "price_if_published_by_creator": 29.90,
            "created_at": datetime.now(timezone.utc),
            "updated_at": datetime.now(timezone.utc)
        },
    ]
    
    db[TRIP_PLANS_COLLECTION].delete_many({}) # 清空
    if trip_plans_data:
        result = db[TRIP_PLANS_COLLECTION].insert_many(trip_plans_data)
        print(f"成功插入 {len(result.inserted_ids)} 条文档到 {TRIP_PLANS_COLLECTION}")

def seed_user_trips(db):
    print(f"Seeding {USER_TRIPS_COLLECTION}...")
    
    user_trips_data = [
        {
            "_id": ObjectId("70c72b928f1b2b001c8e4c1a"), # UserTrip ID
            "plan_id": ObjectId("60c72b928f1b2b001c8e4b1a"), # 关联到上面的三亚计划模板
            "creator_id": "user_alpha_id",
            "creator_name": "Alpha行者",
            "creator_avatar": "https://example.com/avatars/alpha.jpg",
            "user_trip_name_override": "我的三亚亲子欢乐时光", # 用户可以给自己的行程实例起个别名
            "members": [
                {"userId": "user_alpha_id", "name": "Alpha行者", "avatarUrl": "https://example.com/avatars/alpha.jpg", "role": "owner"},
                {"userId": "user_beta_id", "name": "Beta伴侣", "avatarUrl": "https://example.com/avatars/beta.jpg", "role": "member"}
            ],
            "messages": [{"id": str(ObjectId()), "senderId": "system", "content": "行程已启动！", "timestamp": datetime.now(timezone.utc), "type": "system"}],
            "tickets": [
                {"id": str(ObjectId()), "type": "机票", "title": "沪-琼往返", "code": "CA123", "date": "2025-06-01", "details": "T1航站楼"},
                {"id": str(ObjectId()), "type": "酒店", "title": "亚龙湾豪华度假村", "date": "2025-06-01", "details": "海景套房3晚"}
            ],
            "publish_status": "published", # 这个UserTrip被发布到了市场
            "travel_status": "planning", # 当前还在计划中
            "user_rating_for_plan": 4.5, # 用户对这个计划的个人评分（如果需要）
            "user_review_for_plan": "很棒的计划，适合带娃！",
            "price_when_published": 19.90, # 发布到市场时，用户自己定的价格
            "feeds": [],
            "notes": [{"id": str(ObjectId()), "content": "记得带宝宝的防晒霜和帽子。", "timestamp": datetime.now(timezone.utc)}],
            "created_at": datetime.now(timezone.utc),
            "updated_at": datetime.now(timezone.utc)
        },
        {
            "_id": ObjectId("70c72b928f1b2b001c8e4c1b"),
            "plan_id": ObjectId("60c72b928f1b2b001c8e4b1b"), # 关联到北京计划
            "creator_id": "user_gamma_id",
            "creator_name": "Gamma游客",
            "user_trip_name_override": "我的私密北京文化探索",
            "members": [{"userId": "user_gamma_id", "name": "Gamma游客", "role": "owner"}],
            "messages": [], "tickets": [], "feeds": [], "notes": [],
            "publish_status": "draft", # 未发布，仅自己可见
            "travel_status": "completed", # 这个行程已经完成了
            "created_at": datetime.now(timezone.utc),
            "updated_at": datetime.now(timezone.utc)
        },
    ]
    db[USER_TRIPS_COLLECTION].delete_many({}) # 清空
    if user_trips_data:
        result = db[USER_TRIPS_COLLECTION].insert_many(user_trips_data)
        print(f"成功插入 {len(result.inserted_ids)} 条文档到 {USER_TRIPS_COLLECTION}")

if __name__ == "__main__":
    try:
        client = pymongo.MongoClient(MONGO_URI)
        db = client[DATABASE_NAME]
        print(f"已连接到 MongoDB - {MONGO_URI}, 使用数据库 {DATABASE_NAME}")

        seed_trip_plans(db)    # 先填充 TripPlan
        seed_user_trips(db)    # 再填充 UserTrip (它依赖 TripPlan 的 ID)

        # 初始化索引 (确保 UserTrip 和 TripPlan 类已定义或可以被 mongo_utils.py 访问)
        # 通常索引初始化会在应用启动时由 Flask app 完成，但这里也可以手动触发检查
        # from app.utils.mongo_utils import init_mongo_indexes # 假设可以这样导入
        # init_mongo_indexes(client) # 注意: init_mongo_indexes 通常接收 PyMongo 实例或 Flask-PyMongo 实例

        print("数据库填充完成。")
        client.close()
    except pymongo.errors.ConnectionFailure as e:
        print(f"无法连接到 MongoDB: {e}")
    except Exception as e:
        print(f"发生错误: {e}")