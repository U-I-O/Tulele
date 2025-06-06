from flask import jsonify, request
import requests
import os
import json
from . import api
from flask_jwt_extended import jwt_required, get_jwt_identity
import logging

# 日志配置
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Deepseek API配置 - 确保从环境变量获取
DEEPSEEK_API_URL = os.environ.get('DEEPSEEK_API_URL', 'https://api.deepseek.com/v1/chat/completions')
# ⚠️ 重要：请替换为你的有效API密钥！
DEEPSEEK_API_KEY = os.environ.get('DEEPSEEK_API_KEY', 'sk-5ed287ed4abc4f9d86bd4c8d4251b7dd')  # 生产环境请设置环境变量
if not DEEPSEEK_API_KEY:
    logger.warning("⚠️ DEEPSEEK_API_KEY未设置，请在环境变量中设置有效的API密钥")

# 备用API配置 (OpenAI兼容格式)
BACKUP_API_URL = os.environ.get('BACKUP_API_URL', 'https://api.deepseek.com/v1/chat/completions')  # 修改为DeepSeek API
BACKUP_API_KEY = os.environ.get('BACKUP_API_KEY', DEEPSEEK_API_KEY)  # 使用DeepSeek API密钥
if not BACKUP_API_KEY:
    logger.warning("⚠️ BACKUP_API_KEY未设置，将使用DeepSeek API密钥")

# 正确的模型名称
PRIMARY_MODEL = 'deepseek-chat'  # 正确的DeepSeek模型名称
BACKUP_MODEL = 'deepseek-chat'    # 备用模型也使用DeepSeek

# 旅游系统提示词
TRAVEL_SYSTEM_PROMPT = '''
你是一个专业的旅游助理，名叫"途乐乐"。你擅长为用户提供旅游规划和建议。
请记住以下几点：
1. 你的回答必须与旅游相关，如果用户询问非旅游相关的问题，请礼貌地将话题引导回旅游领域
2. 你的建议应当详尽并提供实用信息，包括具体的景点推荐、交通建议、餐饮选择和住宿推荐等
3. 所有日期必须是真实有效的，每天安排2-4个活动，每个活动必须包含具体地点、时间、描述
4. 保持友好、专业的语气，避免过于冗长的回答
5. 如果用户提供的信息不足以做出完整规划，可以询问更多细节

对于行程规划，请确保包含以下信息：
- 行程名称要具体，例如"北京4日文化探索之旅"
- 目的地必须明确，例如"北京"
- 为行程添加合适的标签，例如"文化"、"美食"、"亲子"等
- 每日清晰的行程安排，包括早中晚的活动
- 每个活动都有具体时间(例如"09:00")、详细描述和具体地点
- 提供实用的交通建议、餐饮和住宿推荐
- 合理的预算分配建议
'''

@api.route('/ai/chat', methods=['POST'])
@jwt_required(optional=True)
def ai_chat():
    """AI聊天接口"""
    try:
        data = request.json
        if not data or 'message' not in data:
            return jsonify({'error': '无效的请求数据'}), 400
        
        user_message = data['message']
        history = data.get('history', [])
        
        # 确保历史记录格式正确
        formatted_history = []
        for msg in history:
            if 'role' in msg and 'content' in msg:
                # 已经是正确格式
                formatted_history.append(msg)
            elif 'isUserMessage' in msg and 'content' in msg:
                # 需要转换格式
                role = 'user' if msg['isUserMessage'] else 'assistant'
                formatted_history.append({'role': role, 'content': msg['content']})
            elif 'isUserMessage' in msg and 'text' in msg:
                # 需要转换格式 - 使用text字段
                role = 'user' if msg['isUserMessage'] else 'assistant'
                formatted_history.append({'role': role, 'content': msg['text']})
        
        # 添加系统提示和当前用户消息
        messages = [
            {'role': 'system', 'content': TRAVEL_SYSTEM_PROMPT},
            *formatted_history,
            {'role': 'user', 'content': user_message},
        ]
        
        # 记录完整请求消息
        logger.info(f"AI聊天请求消息: {json.dumps(messages, ensure_ascii=False)}")
        
        # 尝试调用主API
        try:
            logger.info("调用Deepseek API进行聊天")
            response = call_api(
                api_url=DEEPSEEK_API_URL,
                api_key=DEEPSEEK_API_KEY,
                model=PRIMARY_MODEL,
                messages=messages
            )
            content = response['choices'][0]['message']['content']
            
            # 生成建议回复选项
            suggestions = generate_chat_suggestions(user_message, content)
            
            return jsonify({
                'content': content,
                'suggestions': suggestions,
            })
            
        except Exception as e:
            logger.error(f"Deepseek API调用失败: {str(e)}")
            return jsonify({
                'content': '抱歉，我暂时无法连接到AI服务。请问有什么其他旅游相关的问题我可以帮您解决吗？',
                'suggestions': ['推荐热门旅游目的地', '国内旅游', '出国旅游'],
                'error': str(e)
            })
    
    except Exception as e:
        logger.error(f"AI聊天接口错误: {str(e)}")
        return jsonify({'error': f'处理请求时出错: {str(e)}'}), 500


@api.route('/ai/generate-trip', methods=['POST'])
@jwt_required(optional=True)
def generate_trip_plan():
    """生成AI旅游行程规划"""
    try:
        data = request.json
        if not data or 'prompt' not in data:
            return jsonify({'error': '无效的请求数据'}), 400
        
        prompt = data['prompt']
        history = data.get('history', [])
        
        # 确保历史记录格式正确
        formatted_history = []
        for msg in history:
            if 'role' in msg and 'content' in msg:
                # 已经是正确格式
                formatted_history.append(msg)
            elif 'isUserMessage' in msg and 'content' in msg:
                # 需要转换格式
                role = 'user' if msg['isUserMessage'] else 'assistant'
                formatted_history.append({'role': role, 'content': msg['content']})
            elif 'isUserMessage' in msg and 'text' in msg:
                # 需要转换格式 - 使用text字段
                role = 'user' if msg['isUserMessage'] else 'assistant'
                formatted_history.append({'role': role, 'content': msg['text']})
        
        # 解析目的地和天数
        destination = extract_destination(prompt)
        days = extract_days(prompt)
        tags = extract_tags(prompt)
        
        # 构建行程生成提示词
        planning_prompt = f'''
请为用户生成一个详细且具体的{destination}{' '+str(days)+'天' if days > 0 else ''}行程规划。请确保包含真实景点、餐厅和活动。

行程必须符合以下格式要求：
1. 行程名称必须具体明确，例如"{destination}{' '+str(days)+'天' if days > 0 else ''} {tags[0] if tags else ''}之旅"
2. 目的地必须是"{destination}"
3. 每天必须有明确的主题，例如"文化探索"或"美食品尝"等
4. 每个活动必须有具体时间（例如"09:00"）、详细描述和实际存在的地点名称
5. 每天安排2-5个活动，合理分配在上午、下午和晚上
6. 确保行程在现实中可行，考虑交通时间和景点开放时间

请严格按照以下JSON格式返回数据，确保字段名与格式完全匹配，不要省略任何字段：

```json
{{
  "name": "行程名称（具体明确）",
  "destination": "{destination}",
  "tags": ["标签1", "标签2"],
  "description": "整个行程的详细描述",
  "days": [
    {{
      "dayNumber": 1,
      "title": "第一天主题（具体）",
      "description": "当天活动的整体描述",
      "date": "YYYY-MM-DD",
      "activities": [
        {{
          "id": "act1_1",
          "title": "活动标题（必填）",
          "description": "详细活动描述（必填）",
          "location": "具体地点名称（必填）",
          "address": "详细地址",
          "startTime": "09:00",
          "endTime": "11:00",
          "transportation": "步行/公交/地铁/出租车",
          "durationMinutes": 120,
          "type": "景点/餐饮/购物/休闲",
          "estimatedCost": 100,
          "bookingInfo": "预订信息",
          "note": "活动备注信息",
          "icon": "景点"
        }}
      ],
      "notes": "当天建议和提示"
    }}
  ]
}}
```

请务必遵循以下规则：
1. 每个活动的ID格式必须为"act日期_序号"，例如"act1_1"表示第1天第1个活动
2. 每个活动的title, description, location字段必须有内容
3. 每个活动的startTime和endTime必须填写，格式为"HH:MM"
4. 每个活动的estimatedCost必须是数字，不要包含货币符号
5. 所有文本内容必须是中文
6. 行程天数必须与用户要求匹配，或默认为3天
7. 不要添加任何额外的字段或改变字段名称

用户原始请求: {prompt}
'''
        
        messages = [
            {'role': 'system', 'content': TRAVEL_SYSTEM_PROMPT},
            {'role': 'user', 'content': planning_prompt},
        ]
        
        # 记录完整请求消息
        logger.info(f"生成行程请求消息: {json.dumps(messages, ensure_ascii=False)}")
        
        try:
            # 调用主API生成行程
            logger.info("调用Deepseek API生成行程")
            response = call_api(
                api_url=DEEPSEEK_API_URL,
                api_key=DEEPSEEK_API_KEY,
                model=PRIMARY_MODEL,
                messages=messages,
                max_tokens=2048
            )
            
            content = response['choices'][0]['message']['content']
            trip_data = extract_json_from_content(content)
            
            if trip_data:
                logger.info("成功生成行程数据")
                return jsonify(trip_data)
            else:
                logger.error("无法从API响应中提取有效JSON")
                # 生成默认行程作为备用
                default_trip = generate_default_trip(destination, days, tags)
                logger.info("返回默认行程")
                return jsonify(default_trip)
                
        except Exception as e:
            logger.error(f"主API生成行程失败: {str(e)}")
            return jsonify({
                'error': '抱歉，我暂时无法生成行程规划。请问有什么其他旅游相关的问题我可以帮您解决吗？',
                'suggestions': ['推荐热门旅游目的地', '国内旅游', '出国旅游'],
                'error': str(e)
            }), 400
    
    except Exception as e:
        logger.error(f"生成行程接口错误: {str(e)}")
        return jsonify({'error': f'处理请求时出错: {str(e)}'}), 500


@api.route('/ai/modify-trip', methods=['POST'])
@jwt_required(optional=True)
def modify_trip_plan():
    """修改AI旅游行程规划"""
    try:
        data = request.json
        if not data or 'prompt' not in data or 'currentPlan' not in data:
            return jsonify({'error': '无效的请求数据'}), 400
        
        prompt = data['prompt']
        current_plan = data['currentPlan']
        history = data.get('history', [])
        
        # 确保历史记录格式正确
        formatted_history = []
        for msg in history:
            if 'role' in msg and 'content' in msg:
                # 已经是正确格式
                formatted_history.append(msg)
            elif 'isUserMessage' in msg and 'content' in msg:
                # 需要转换格式
                role = 'user' if msg['isUserMessage'] else 'assistant'
                formatted_history.append({'role': role, 'content': msg['content']})
            elif 'isUserMessage' in msg and 'text' in msg:
                # 需要转换格式 - 使用text字段
                role = 'user' if msg['isUserMessage'] else 'assistant'
                formatted_history.append({'role': role, 'content': msg['text']})
        
        # 将当前行程转换为JSON字符串
        current_plan_str = json.dumps(current_plan, ensure_ascii=False)
        
        # 构建修改行程的提示词
        modification_prompt = f'''
请根据用户的要求，对以下旅游行程进行修改：

当前行程：
{current_plan_str}

用户修改要求：
{prompt}

请遵循以下原则：
1. 保留行程的基本结构，仅按照用户要求进行修改
2. 确保修改后的行程仍然合理可行
3. 返回完整修改后的行程，格式与输入格式保持一致
4. 确保每个活动都有具体时间、详细描述和地点

请直接返回修改后的完整JSON格式行程，无需额外解释。
'''
        
        messages = [
            {'role': 'system', 'content': TRAVEL_SYSTEM_PROMPT},
            {'role': 'user', 'content': modification_prompt},
        ]
        
        # 记录完整请求消息
        logger.info(f"修改行程请求消息: {json.dumps(messages, ensure_ascii=False)}")
        
        try:
            # 调用主API修改行程
            logger.info("调用Deepseek API修改行程")
            response = call_api(
                api_url=DEEPSEEK_API_URL,
                api_key=DEEPSEEK_API_KEY,
                model=PRIMARY_MODEL,
                messages=messages,
                max_tokens=2048
            )
            
            content = response['choices'][0]['message']['content']
            modified_plan = extract_json_from_content(content)
            
            if modified_plan:
                logger.info("成功修改行程数据")
                return jsonify(modified_plan)
            else:
                logger.error("无法从API响应中提取有效JSON")
                return jsonify({
                    "error": "无法修改行程，请重新尝试或提供更明确的修改指令"
                }), 400
                
        except Exception as e:
            logger.error(f"主API修改行程失败: {str(e)}")
            return jsonify({
                'error': '抱歉，我暂时无法修改行程规划。请问有什么其他旅游相关的问题我可以帮您解决吗？',
                'suggestions': ['推荐热门旅游目的地', '国内旅游', '出国旅游'],
                'error': str(e)
            }), 400
    
    except Exception as e:
        logger.error(f"修改行程接口错误: {str(e)}")
        return jsonify({'error': f'处理请求时出错: {str(e)}'}), 500


# 工具函数

def call_api(api_url, api_key, model, messages, max_tokens=1024, use_extended_params=False):
    """调用AI API - 仅DeepSeek版本"""
    if not api_key or api_key.strip() == '':
        error_msg = f"API密钥未设置或为空，无法调用API: {api_url}"
        logger.error(error_msg)
        raise Exception(error_msg)
    
    # 检查消息格式
    if not messages or not isinstance(messages, list) or len(messages) == 0:
        error_msg = "消息列表为空或格式错误"
        logger.error(error_msg)
        raise Exception(error_msg)
    
    # 检查每条消息的格式
    for msg in messages:
        if not isinstance(msg, dict) or 'role' not in msg or 'content' not in msg:
            error_msg = f"消息格式错误: {msg}"
            logger.error(error_msg)
            raise Exception(error_msg)
        
    headers = {
        'Content-Type': 'application/json',
        'Authorization': f'Bearer {api_key}',
    }
    
    # 基础请求格式 - 只使用DeepSeek API所需的格式
    payload = {
        'model': model,
        'messages': messages,
        'stream': False  # 明确指定非流式响应
    }
    
    # 仅在需要更多token时添加max_tokens
    if max_tokens > 1024:
        payload['max_tokens'] = int(max_tokens)
    
    # 调试输出
    logger.info(f"正在调用DeepSeek API: {api_url}，模型: {model}")
    logger.info(f"请求头: {headers}")
    logger.info(f"请求体: {json.dumps(payload, ensure_ascii=False)}")
    
    try:
        response = requests.post(
            api_url,
            headers=headers,
            json=payload,
            timeout=120  # 60秒超时
        )
        
        # 详细记录响应
        logger.info(f"API响应状态码: {response.status_code}")
        logger.info(f"API响应内容: {response.text[:500]}...")  # 截取前500个字符避免日志过长
        
        if response.status_code == 200:
            logger.info("API调用成功")
            return response.json()
        elif response.status_code == 401:
            error_message = f"API认证失败: 无效的API密钥或未授权。请检查DeepSeek API密钥是否正确和有效。"
            logger.error(error_message)
            raise Exception(error_message)
        elif response.status_code == 400:
            error_message = f"API请求参数错误: {response.text}"
            logger.error(error_message)
            raise Exception(error_message)
        elif response.status_code == 422:
            error_message = f"API请求格式错误或签名验证失败: {response.text}。请检查DeepSeek API密钥和请求参数。"
            logger.error(error_message)
            raise Exception(error_message)
        elif response.status_code == 429:
            error_message = f"API请求频率超限: {response.text}"
            logger.error(error_message)
            raise Exception(error_message)
        else:
            error_message = f"API请求失败: {response.status_code} - {response.text}"
            logger.error(error_message)
            raise Exception(error_message)
            
    except requests.RequestException as e:
        logger.error(f"请求异常: {str(e)}")
        raise Exception(f"API请求异常: {str(e)}")
    except Exception as e:
        logger.error(f"未知错误: {str(e)}")
        raise Exception(f"API调用时发生未知错误: {str(e)}")


def extract_json_from_content(content):
    """从内容中提取JSON"""
    try:
        # 尝试直接解析整个内容
        return json.loads(content)
    except:
        pass
    
    # 尝试从Markdown代码块中提取JSON
    json_pattern = r'```(?:json)?\s*([\s\S]*?)\s*```'
    import re
    matches = re.findall(json_pattern, content)
    
    if matches:
        for match in matches:
            try:
                return json.loads(match)
            except:
                continue
    
    # 尝试提取任意花括号包围的JSON
    json_pattern = r'(\{[\s\S]*\})'
    matches = re.findall(json_pattern, content)
    
    if matches:
        for match in matches:
            try:
                return json.loads(match)
            except:
                continue
    
    return None


def generate_chat_suggestions(user_message, ai_response):
    """生成聊天建议选项"""
    user_message = user_message.lower()
    
    # 基于用户消息和AI回复的内容生成建议
    if "旅游" in user_message or "旅行" in user_message or "行程" in user_message:
        return ["帮我规划详细行程", "有什么美食推荐？", "当地有什么特色景点？"]
    
    if "北京" in user_message:
        return ["北京长城怎么去？", "北京有什么美食？", "故宫一日游攻略"]
    
    if "上海" in user_message:
        return ["上海迪士尼攻略", "上海外滩附近住宿", "上海必吃美食"]
    
    if "规划" in ai_response or "行程" in ai_response:
        return ["这个行程可以再详细点吗？", "有什么特别推荐的景点？", "如何安排交通？"]
    
    # 默认建议
    return ["推荐热门旅游目的地", "国内旅游路线", "亲子游推荐"]


def extract_destination(prompt):
    """从提示中提取目的地"""
    # 简单实现：常见城市匹配
    common_cities = ["北京", "上海", "广州", "深圳", "成都", "重庆", "西安", "杭州", "南京", 
                    "武汉", "长沙", "厦门", "青岛", "大连", "三亚", "丽江", "桂林", "昆明",
                    "兰州", "西宁", "拉萨", "呼和浩特", "乌鲁木齐"]
    
    for city in common_cities:
        if city in prompt:
            return city
    
    # 模式匹配
    destination_patterns = [
        r'去([\u4e00-\u9fa5]{2,4})旅游',
        r'去([\u4e00-\u9fa5]{2,4})玩',
        r'([\u4e00-\u9fa5]{2,4})之旅',
        r'([\u4e00-\u9fa5]{2,4})游玩',
        r'([\u4e00-\u9fa5]{2,4})旅行'
    ]
    
    import re
    for pattern in destination_patterns:
        match = re.search(pattern, prompt)
        if match:
            return match.group(1)
    
    # 默认返回
    return "北京"


def extract_days(prompt):
    """从提示中提取天数"""
    # 模式匹配
    import re
    days_pattern = r'(\d+)\s*[天日]'
    match = re.search(days_pattern, prompt)
    if match:
        days = int(match.group(1))
        return days if 1 <= days <= 30 else 3  # 合理范围检查
    
    return 3  # 默认3天


def extract_tags(prompt):
    """从提示中提取标签"""
    common_tags = ["文化", "美食", "购物", "亲子", "自然", "历史", "古迹", "艺术", "休闲", 
                  "冒险", "户外", "摄影", "温泉", "海滩", "山川", "乡村", "城市"]
    
    tags = []
    for tag in common_tags:
        if tag in prompt:
            tags.append(tag)
    
    # 默认添加通用标签
    if not tags:
        tags = ["休闲", "美食"]
    
    return tags


def generate_default_trip(destination, days, tags):
    """生成默认行程"""
    days = max(1, min(days, 30))  # 保证天数在合理范围内
    
    # 创建行程名称
    trip_name = f"{destination}{days}天{tags[0] if tags else '休闲'}之旅"
    
    days_list = []
    attractions = [
        f"{destination}博物馆",
        f"{destination}公园",
        f"{destination}古街",
        f"{destination}著名景区",
        f"{destination}地标建筑",
        f"{destination}历史遗迹",
        f"{destination}文化中心",
        f"{destination}特色街区"
    ]
    
    import datetime
    start_date = datetime.datetime.now()
    
    for i in range(days):
        current_date = start_date + datetime.timedelta(days=i)
        date_str = current_date.strftime('%Y-%m-%d')
        
        # 每天景点安排逻辑
        attraction_index = i * 2 % len(attractions)
        
        # 安排活动
        activities = [
            {
                "id": f"act_{i+1}_1",
                "time": "09:00",
                "description": f"游览{attractions[attraction_index % len(attractions)]}",
                "location": f"{attractions[attraction_index % len(attractions)]}"
            },
            {
                "id": f"act_{i+1}_2",
                "time": "12:00",
                "description": "午餐",
                "location": f"{destination}特色餐厅"
            },
            {
                "id": f"act_{i+1}_3",
                "time": "14:00",
                "description": f"游览{attractions[(attraction_index+1) % len(attractions)]}",
                "location": f"{attractions[(attraction_index+1) % len(attractions)]}"
            },
            {
                "id": f"act_{i+1}_4",
                "time": "18:00",
                "description": "晚餐",
                "location": f"{destination}本地特色美食"
            }
        ]
        
        # 第一天添加抵达，最后一天添加离开
        if i == 0:
            activities.insert(0, {
                "id": f"act_{i+1}_0",
                "time": "08:00",
                "description": f"抵达{destination}",
                "location": f"{destination}机场/火车站"
            })
        elif i == days - 1:
            activities.append({
                "id": f"act_{i+1}_5",
                "time": "20:00",
                "description": "返程准备",
                "location": "酒店"
            })
        
        # 添加当天行程
        days_list.append({
            "dayNumber": i + 1,
            "date": date_str,
            "title": f"第{i+1}天：{destination}{get_day_theme(i+1, days)}",
            "activities": activities,
            "notes": "这是自动生成的基础行程，建议根据实际情况调整时间和活动安排。"
        })
    
    return {
        "name": trip_name,
        "destination": destination,
        "tags": tags,
        "days": days_list,
        "note": "由于API响应问题，这是系统生成的基础行程。您可以在APP中进一步编辑和完善。"
    }


def get_day_theme(day, total_days):
    """获取天数对应的主题"""
    if day == 1:
        return "初体验"
    elif day == total_days:
        return "精华探索与告别"
    elif day == 2 and total_days > 3:
        return "文化之旅"
    elif day == 3 and total_days > 3:
        return "自然风光"
    else:
        return "深度游"