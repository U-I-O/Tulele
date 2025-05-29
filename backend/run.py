import os
from app import create_app

# 从环境变量中获取配置名称，默认为development
config_name = os.environ.get('FLASK_ENV') or 'development'
app = create_app(config_name)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000) 