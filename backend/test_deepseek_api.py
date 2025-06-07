import os
import requests
import json

# DeepSeek API配置
api_key = "sk-5ed287ed4abc4f9d86bd4c8d4251b7dd"  # 替换为你的有效API密钥
api_url = "https://api.deepseek.com/v1/chat/completions"
model = "deepseek-chat"

def call_deepseek_api(messages):
    """调用DeepSeek API进行聊天"""
    headers = {
        'Content-Type': 'application/json',
        'Authorization': f'Bearer {api_key}',
    }
    
    payload = {
        'model': model,
        'messages': messages,
        'stream': False
    }
    
    print(f"\n正在调用DeepSeek API: {api_url}")
    print(f"使用模型: {model}")
    print(f"请求头: {headers}")
    print(f"请求内容: {json.dumps(payload, ensure_ascii=False)}")
    
    try:
        response = requests.post(
            api_url,
            headers=headers,
            json=payload,
            timeout=60  # 60秒超时
        )
        
        print(f"状态码: {response.status_code}")
        
        if response.status_code == 200:
            print("API调用成功!")
            result = response.json()
            content = result['choices'][0]['message']['content']
            print(f"\n回复内容: {content}\n")
            return True
        else:
            print(f"API请求失败: {response.status_code}")
            print(f"错误信息: {response.text}")
            return False
            
    except Exception as e:
        print(f"API调用时发生错误: {str(e)}")
        return False

def test_chat():
    """测试简单聊天"""
    messages = [
        {'role': 'user', 'content': '你好，请简单介绍一下三亚的旅游景点。'}
    ]
    
    print("\n===== 测试聊天 =====")
    success = call_deepseek_api(messages)
    print("测试结果:", "成功" if success else "失败")

def test_trip_planning():
    """测试行程规划"""
    messages = [
        {'role': 'system', 'content': '你是一个专业的旅游助理，擅长为用户提供旅游规划和建议。'},
        {'role': 'user', 'content': '请为我规划一个北京两日游，以文化景点为主。'}
    ]
    
    print("\n===== 测试行程规划 =====")
    success = call_deepseek_api(messages)
    print("测试结果:", "成功" if success else "失败")

if __name__ == "__main__":
    print("===== DeepSeek API 测试脚本 =====")
    test_chat()
    test_trip_planning() 