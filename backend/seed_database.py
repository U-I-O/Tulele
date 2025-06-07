# seed_database.py
import pymongo
from datetime import datetime, timezone, timedelta
from bson import ObjectId
import random # 用于生成一些随机数据

MONGO_URI = "mongodb://localhost:27017/"
DATABASE_NAME = "flutter_dev" # 使用新的数据库名或清空旧的
TRIP_PLANS_COLLECTION = 'tripPlans'
USER_TRIPS_COLLECTION = 'userTrips'

# 当前登录用户ID (用于测试)
CURRENT_USER_ID_FOR_TESTING = "user1"

def get_random_object_id_str():
    return str(ObjectId())

def seed_trip_plans(db):
    print(f"Seeding {TRIP_PLANS_COLLECTION}...")
    
    trip_plans_data = [
        {
            "_id": ObjectId("60c72b928f1b2b001c8e4b1a"), # 固定ID，方便 UserTrip 关联
            "name": "三亚经典5日亲子游模板",
            "creator_id": "admin_user_id", # 假设由管理员创建
            "creator_name": "途乐乐官方",
            "origin": "任意城市",
            "destination": "海南三亚",
            "startDate": datetime(2025, 7, 1, 0, 0, 0, tzinfo=timezone.utc), # 参考日期
            "endDate": datetime(2025, 7, 5, 0, 0, 0, tzinfo=timezone.utc),
            "duration_days": 5,
            "tags": ["亲子", "海岛", "热门推荐", "官方认证"],
            "description": "途乐乐官方推荐，完美结合亲子乐趣与海岛休闲的三亚5日行程模板。",
            "coverImage": "https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=800&q=60", # 替换为高质量图片
            "days": [
                {
                    "day_number": 1, "title": "抵达与适应", "description": "轻松抵达，享受酒店设施。",
                    "activities": [
                        {"activity_id": get_random_object_id_str(), "title": "抵达三亚凤凰机场，专车接机", "location": "三亚凤凰国际机场", "start_time": "14:00", "type": "transportation"},
                        {"activity_id": get_random_object_id_str(), "title": "入住亚龙湾豪华度假酒店", "location": "亚龙湾区域酒店", "start_time": "15:30", "type": "hotel", "activity_notes": "选择海景房体验更佳"},
                        {"activity_id": get_random_object_id_str(), "title": "酒店内自由活动与晚餐", "location": "酒店内", "start_time": "17:00", "type": "dining"}
                    ],
                    "daily_notes": "首日以适应为主，不安排紧张行程。"
                },
                {
                    "day_number": 2, "title": "沙滩与海洋", "description": "尽情享受阳光沙滩。",
                    "activities": [
                        {"activity_id": get_random_object_id_str(), "title": "亚龙湾热带天堂森林公园", "location": "亚龙湾热带天堂森林公园", "start_time": "09:00", "duration_minutes": 240, "type": "sightseeing"},
                        {"activity_id": get_random_object_id_str(), "title": "亚龙湾中心广场海底世界（可选）", "location": "亚龙湾中心广场", "start_time": "14:30", "type": "sightseeing", "estimated_cost": 150},
                        {"activity_id": get_random_object_id_str(), "title": "沙滩晚餐BBQ", "location": "酒店沙滩区域", "start_time": "18:30", "type": "dining"}
                    ],
                    "daily_notes": "注意防晒，携带泳具。"
                },
                # 可以继续添加更多天的详细活动...
            ],
            "platform_price": 99.00,
            "average_rating": 4.8,
            "review_count": 215,
            "sales_volume": 500,
            "usage_count": 1200,
            "created_at": datetime(2024, 1, 10, 10, 0, 0, tzinfo=timezone.utc),
            "updated_at": datetime(2024, 5, 20, 14, 30, 0, tzinfo=timezone.utc),
            "version": 2,
            "estimated_cost_range": "3000-8000元/人 (不含往返大交通)",
            "suitability": ["家庭亲子", "情侣度假", "休闲放松"],
            "highlights": ["经典景点全覆盖", "五星酒店体验", "行程松弛有度"],
            "is_featured_on_market": True
        },
        {
            "_id": ObjectId("60c72b928f1b2b001c8e4b1b"), # 固定ID
            "name": "成都美食探索3日模板",
            "creator_id": "foodie_blogger_id",
            "creator_name": "食神小当家",
            "destination": "四川成都",
            "duration_days": 3,
            "tags": ["美食", "网红打卡", "文化体验"],
            "description": "为期三天的成都美食之旅，带你尝遍地道川菜与小吃。",
            "coverImage": "https://images.unsplash.com/photo-1581974085329-37f9934d7a14?auto=format&fit=crop&w=800&q=60", # 成都美食相关图片
            "days": [
                 {
                    "day_number": 1, "title": "火锅与宽窄巷子",
                    "activities": [
                        {"activity_id": get_random_object_id_str(), "title": "品尝地道成都火锅", "location": "小龙坎火锅", "start_time": "12:00", "type": "dining"},
                        {"activity_id": get_random_object_id_str(), "title": "漫步宽窄巷子", "location": "宽窄巷子", "start_time": "15:00", "type": "sightseeing"},
                    ],
                }
                # ... 更多天数
            ],
            "platform_price": 49.90,
            "average_rating": 4.9,
            "review_count": 302,
            "sales_volume": 800,
            "usage_count": 1500,
            "created_at": datetime(2024, 2, 15, tzinfo=timezone.utc),
            "updated_at": datetime(2024, 5, 1, tzinfo=timezone.utc),
            "is_featured_on_market": True
        },
        {
            "_id": ObjectId("60c72b928f1b2b001c8e4b1c"), # 固定ID
            "name": "日本东京动漫圣地巡礼7日",
            "creator_id": "anime_fan_id",
            "creator_name": "ACG爱好者",
            "destination": "日本东京",
            "duration_days": 7,
            "tags": ["动漫", "二次元", "购物", "主题公园"],
            "description": "深入东京的动漫文化，巡礼经典场景，包含秋叶原、吉卜力等。",
            "coverImage": "https://images.unsplash.com/photo-1540959733332-eab4deabeeaf?auto=format&fit=crop&w=800&q=60", # 东京相关
            "days": [], # 示例，简化days
            "platform_price": 129.00,
            "average_rating": 4.7,
            "review_count": 180,
            "created_at": datetime(2024, 3, 1, tzinfo=timezone.utc),
            "updated_at": datetime(2024, 4, 25, tzinfo=timezone.utc),
            "is_featured_on_market": False # 可能不是首页精选，但仍在市场
        }
    ]
    
    try:
        db[TRIP_PLANS_COLLECTION].delete_many({})
        if trip_plans_data:
            result = db[TRIP_PLANS_COLLECTION].insert_many(trip_plans_data)
            print(f"成功插入 {len(result.inserted_ids)} 条文档到 {TRIP_PLANS_COLLECTION}")
    except Exception as e:
        print(f"填充 {TRIP_PLANS_COLLECTION} 出错: {e}")

def seed_user_trips(db):
    print(f"Seeding {USER_TRIPS_COLLECTION}...")
    
    # 获取已存在的 plan_ids 用于关联
    plan_ids = [p["_id"] for p in db[TRIP_PLANS_COLLECTION].find({}, {"_id": 1})]
    if not plan_ids:
        print("警告: tripPlans 集合为空，无法关联 UserTrip。请先填充 TripPlan。")
        return

    sanya_plan_id = ObjectId("60c72b928f1b2b001c8e4b1a")
    chengdu_plan_id = ObjectId("60c72b928f1b2b001c8e4b1b")
    tokyo_plan_id = ObjectId("60c72b928f1b2b001c8e4b1c")

    user_trips_data = [
        # === 当前用户 (user1_id) 的行程 ===
        { # 1. user1 创建的，基于三亚模板，已发布，计划中
            "_id": ObjectId(),
            "plan_id": sanya_plan_id,
            "user_trip_name_override": "我的三亚夏日全家总动员",
            "creator_id": CURRENT_USER_ID_FOR_TESTING, "creator_name": "测试用户一号", "creator_avatar": "https://i.pravatar.cc/150?u=user1",
            "coverImage": "https://images.unsplash.com/photo-1567605691489-ec099253ac53?auto=format&fit=crop&w=800&q=60", # 用户自定义封面
            "destination": "海南三亚市", # 用户可能微调了目的地
            "startDate": datetime(2025, 8, 1, tzinfo=timezone.utc), # 用户自定义了日期
            "endDate": datetime(2025, 8, 6, tzinfo=timezone.utc),
            "tags": ["亲子", "海滨", "豪华游"], # 用户自定义了标签
            "description": "带爸妈和小朋友一起去三亚，享受一个难忘的暑假！",
            "days": [ # 用户可能会修改或增加活动
                 {
                    "day_number": 1, "date": datetime(2025,8,1,tzinfo=timezone.utc), "user_daily_notes": "第一天到，别太累",
                    "activities": [
                        {"user_activity_id": get_random_object_id_str(), "original_plan_activity_id": "从三亚模板中某活动的activity_id复制过来（如果适用）", "title": "抵达，入住豪华酒店", "location": "亚龙湾瑞吉酒店", "start_time": "14:30"},
                        {"user_activity_id": get_random_object_id_str(), "title": "酒店私人沙滩休闲", "location": "瑞吉酒店私人沙滩", "start_time": "16:00", "user_activity_notes": "给孩子带上挖沙工具"}
                    ]
                },
                # ... 更多天的用户自定义安排
            ],
            "members": [{"userId": CURRENT_USER_ID_FOR_TESTING, "name": "测试用户一号", "role": "owner"}],
            "messages": [],
            "tickets": [{"ticket_id": get_random_object_id_str(), "type": "机票", "title": "北京-三亚", "date": "2025-08-01"}],
            "user_notes": [{"note_id": get_random_object_id_str(), "content": "整体预算控制在2万内", "created_at": datetime.now(timezone.utc)}],
            "publish_status": "published",
            "travel_status": "planning",
            "user_personal_rating": None, "user_personal_review": None,
            "created_at": datetime.now(timezone.utc) - timedelta(days=30),
            "updated_at": datetime.now(timezone.utc) - timedelta(days=2)
        },
        { # 2. user1 创建的，基于成都模板，待审核，旅行中
            "_id": ObjectId(),
            "plan_id": chengdu_plan_id,
            "user_trip_name_override": "和朋友的成都吃货之旅",
            "creator_id": CURRENT_USER_ID_FOR_TESTING, "creator_name": "测试用户一号",
            "startDate": datetime.now(timezone.utc) - timedelta(days=1), # 假设昨天开始
            "endDate": datetime.now(timezone.utc) + timedelta(days=1),   # 明天结束
            "tags": ["美食探店", "朋友出游"],
            "days": [], # 简化
            "members": [
                {"userId": CURRENT_USER_ID_FOR_TESTING, "name": "测试用户一号", "role": "owner"},
                {"userId": "friend_user_id_1", "name": "好友小张", "role": "member"}
            ],
            "publish_status": "pending_review",
            "submission_notes_to_admin": "希望尽快审核通过，这个美食路线超赞！",
            "travel_status": "traveling",
            "created_at": datetime.now(timezone.utc) - timedelta(days=10),
            "updated_at": datetime.now(timezone.utc) - timedelta(hours=5)
        },
        { # 3. user1 创建的，完全自定义，草稿，已完成
            "_id": ObjectId(),
            "plan_id": None, # 完全自定义，不关联模板
            "user_trip_name_override": "周末上海CityWalk",
            "creator_id": CURRENT_USER_ID_FOR_TESTING, "creator_name": "测试用户一号",
            "destination": "上海",
            "startDate": datetime.now(timezone.utc) - timedelta(days=7),
            "endDate": datetime.now(timezone.utc) - timedelta(days=6),
            "tags": ["CityWalk", "周末"],
            "days": [
                 {
                    "day_number": 1, "date": datetime.now(timezone.utc) - timedelta(days=7),
                    "activities": [
                        {"user_activity_id": get_random_object_id_str(), "title": "漫步武康路", "location": "武康路", "start_time": "10:00"},
                        {"user_activity_id": get_random_object_id_str(), "title": "咖啡小憩", "location": "武康路某咖啡馆", "start_time": "12:00"}
                    ]
                }
            ],
            "members": [{"userId": CURRENT_USER_ID_FOR_TESTING, "name": "测试用户一号", "role": "owner"}],
            "publish_status": "draft",
            "travel_status": "completed",
            "user_personal_rating": 5, "user_personal_review": "非常棒的周末体验！",
            "created_at": datetime.now(timezone.utc) - timedelta(days=15),
            "updated_at": datetime.now(timezone.utc) - timedelta(days=5)
        },

        # === 其他用户的行程 ===
        { # 4. 其他用户 (user2) 创建的，基于东京模板，已发布，计划中 (用于市场展示)
            "_id": ObjectId(),
            "plan_id": tokyo_plan_id,
            "user_trip_name_override": "二次元东京探索小分队",
            "creator_id": "user2_id_jane", "creator_name": "Jane动漫迷", "creator_avatar": "https://i.pravatar.cc/150?u=user2",
            "coverImage": "https://images.unsplash.com/photo-1513407030348-c983a97b98d8?auto=format&fit=crop&w=800&q=60",
            "destination": "日本东京",
            "startDate": datetime(2025, 9, 10, tzinfo=timezone.utc),
            "endDate": datetime(2025, 9, 17, tzinfo=timezone.utc),
            "tags": ["动漫", "圣地巡礼", "秋叶原"],
            "days": [], # 简化
            "members": [{"userId": "user2_id_jane", "name": "Jane动漫迷", "role": "owner"}],
            "publish_status": "published",
            "travel_status": "planning",
            "created_at": datetime.now(timezone.utc) - timedelta(days=45),
            "updated_at": datetime.now(timezone.utc) - timedelta(days=10)
        },
        { # 5. 其他用户 (user3) 创建的，基于三亚模板，被驳回，计划中
            "_id": ObjectId(),
            "plan_id": sanya_plan_id,
            "user_trip_name_override": "我的三亚婚纱拍摄之旅",
            "creator_id": "user3_id_mike", "creator_name": "摄影师Mike", "creator_avatar": "https://i.pravatar.cc/150?u=user3",
            "destination": "海南三亚及周边",
            "startDate": datetime(2025, 10, 1, tzinfo=timezone.utc),
            "endDate": datetime(2025, 10, 5, tzinfo=timezone.utc),
            "tags": ["摄影", "婚纱照", "旅拍"],
            "days": [], # 简化
            "members": [{"userId": "user3_id_mike", "name": "摄影师Mike", "role": "owner"}],
            "publish_status": "rejected",
            "admin_feedback_on_review": "方案描述过于简单，请补充详细的每日安排和特色说明后再提交。",
            "travel_status": "planning",
            "created_at": datetime.now(timezone.utc) - timedelta(days=20),
            "updated_at": datetime.now(timezone.utc) - timedelta(days=3)
        },
    ]
    
    # 确保 UserTrip 必需字段的填充
    for ut_data in user_trips_data:
        if 'messages' not in ut_data: ut_data['messages'] = []
        if 'tickets' not in ut_data: ut_data['tickets'] = []
        if 'user_notes' not in ut_data: ut_data['user_notes'] = []
        # 从关联的 TripPlan 填充一些 UserTrip 的基础信息 (如果 plan_id 存在且 UserTrip 对应字段为空)
        if ut_data.get("plan_id"):
            plan_doc = db[TRIP_PLANS_COLLECTION].find_one({"_id": ut_data["plan_id"]})
            if plan_doc:
                ut_data.setdefault("destination", plan_doc.get("destination"))
                ut_data.setdefault("origin", plan_doc.get("origin"))
                ut_data.setdefault("startDate", plan_doc.get("startDate"))
                ut_data.setdefault("endDate", plan_doc.get("endDate"))
                ut_data.setdefault("tags", plan_doc.get("tags", []))
                ut_data.setdefault("description", plan_doc.get("description"))
                # days 比较复杂，如果用户没有自定义days，理论上应该深拷贝plan的days过来
                # 为简化seed脚本，如果ut_data["days"]已提供则用它，否则保持为空或需要更复杂的填充逻辑
                if not ut_data.get("days") and plan_doc.get("days"): # 简单的浅拷贝示例，实际应深拷贝并转换活动ID
                    ut_data["days"] = [] # plan_doc.get("days") # 这里需要转换结构！
                    # 实际填充 days 时，需要将 plan_doc['days'] 下的 activities
                    # 转换为 userTrips.days.activities 的结构，并处理 activity_id -> user_activity_id, original_plan_activity_id
                    print(f"警告: UserTrip ID {ut_data.get('_id')} 的 days 未从 plan ID {ut_data.get('plan_id')} 详细填充，请在应用逻辑中处理或完善seed脚本。")


    try:
        db[USER_TRIPS_COLLECTION].delete_many({})
        if user_trips_data:
            result = db[USER_TRIPS_COLLECTION].insert_many(user_trips_data)
            print(f"成功插入 {len(result.inserted_ids)} 条文档到 {USER_TRIPS_COLLECTION}")
    except Exception as e:
        print(f"填充 {USER_TRIPS_COLLECTION} 出错: {e}")


if __name__ == "__main__":
    try:
        client = pymongo.MongoClient(MONGO_URI)
        # client.admin.command('ping') # 测试连接
        db = client[DATABASE_NAME]
        print(f"已连接到 MongoDB - {MONGO_URI}, 使用数据库 {DATABASE_NAME}")

        seed_trip_plans(db)
        seed_user_trips(db)

        print("数据库填充完成。")
        client.close()
    except pymongo.errors.ConnectionFailure as e:
        print(f"无法连接到 MongoDB: {e}")
    except Exception as e:
        print(f"发生错误: {e}")