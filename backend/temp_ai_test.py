import os
import logging
import requests
import json
from dotenv import load_dotenv

# 配置日志
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# 加载环境变量
load_dotenv()

# 获取API密钥
DEEPSEEK_API_URL = os.environ.get('DEEPSEEK_API_URL', 'https://api.deepseek.com/v1/chat/completions')
DEEPSEEK_API_KEY = os.environ.get('DEEPSEEK_API_KEY', '')

if not DEEPSEEK_API_KEY:
    # 如果环境变量中没有，提示用户输入
    print("⚠️ DEEPSEEK_API_KEY未在环境变量中设置")
    DEEPSEEK_API_KEY = input("请输入Deepseek API密钥进行测试: ").strip()
    if not DEEPSEEK_API_KEY:
        print("未提供API密钥，将无法进行测试")
        exit(1)

# 测试系统提示
SYSTEM_PROMPT = '''
你是一个专业的旅游助理，名叫"途乐乐"。你擅长为用户提供旅游规划和建议。
请保持友好、专业的语气，避免过于冗长的回答。
'''

def call_api(api_url, api_key, messages, model="deepseek-chat", max_tokens=1024, temperature=0.7):
    """调用API进行测试"""
    headers = {
        'Content-Type': 'application/json',
        'Authorization': f'Bearer {api_key}',
    }
    
    payload = {
        'model': model,
        'messages': messages,
        'temperature': temperature,
        'max_tokens': max_tokens,
    }
    
    print(f"正在调用AI API: {api_url}，模型: {model}")
    
    try:
        response = requests.post(
            api_url,
            headers=headers,
            json=payload,
            timeout=60  # 60秒超时
        )
        
        if response.status_code == 200:
            print("API调用成功!")
            return response.json()
        else:
            print(f"API请求失败: {response.status_code} - {response.text}")
            return None
            
    except Exception as e:
        print(f"API调用时发生错误: {str(e)}")
        return None

def test_chat_api():
    """测试聊天API"""
    messages = [
        {'role': 'system', 'content': SYSTEM_PROMPT},
        {'role': 'user', 'content': '你好，我想去三亚旅游，有什么建议？'}
    ]
    
    print("\n===== 测试聊天API =====")
    result = call_api(DEEPSEEK_API_URL, DEEPSEEK_API_KEY, messages)
    
    if result:
        print("\n回复内容:")
        print(result['choices'][0]['message']['content'])
        print("\n===== 测试成功! =====")
    else:
        print("\n===== 测试失败! =====")

if __name__ == "__main__":
    test_chat_api() 