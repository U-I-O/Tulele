import requests

# 替换为你的新API密钥
api_key = "sk-5ed287ed4abc4f9d86bd4c8d4251b7dd"
url = "https://api.deepseek.com/v1/chat/completions"

headers = {
    'Content-Type': 'application/json',
    'Authorization': f'Bearer {api_key}',
}

# 使用正确的模型名称和最小参数
payload = {
    'model': 'deepseek-chat',
    'messages': [
        {'role': 'user', 'content': 'Hello'}
    ],
    'stream': False
}

response = requests.post(url, headers=headers, json=payload)
print(f"状态码: {response.status_code}")
print(f"响应: {response.text}")