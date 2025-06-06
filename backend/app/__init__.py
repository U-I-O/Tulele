from flask import Flask
from flask_cors import CORS
from flask_pymongo import PyMongo
from flask_jwt_extended import JWTManager
from config.config import config

# 创建MongoDB连接实例
mongo = PyMongo()
# 创建JWT管理器
jwt = JWTManager()

def create_app(config_name='default'):
    """创建Flask应用"""
    app = Flask(__name__)
    app.config.from_object(config[config_name])
    config[config_name].init_app(app)
    
    # 初始化插件
    mongo.init_app(app)
    jwt.init_app(app)
    CORS(app)
    
    # 注册蓝图
    from .api import api as api_blueprint
    app.register_blueprint(api_blueprint, url_prefix='/api')
    
    # 处理邀请链接
    @app.route('/invite/<invitation_code>')
    def handle_invitation(invitation_code):
        """处理邀请链接，返回一个简单的HTML页面，引导用户打开APP"""
        html = f'''
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>途乐乐 - 行程邀请</title>
            <style>
                body {{
                    font-family: 'PingFang SC', 'Helvetica Neue', Arial, sans-serif;
                    margin: 0;
                    padding: 0;
                    display: flex;
                    justify-content: center;
                    align-items: center;
                    min-height: 100vh;
                    background-color: #f5f5f5;
                    color: #333;
                }}
                .container {{
                    text-align: center;
                    background: white;
                    border-radius: 16px;
                    padding: 30px;
                    box-shadow: 0 4px 12px rgba(0,0,0,0.1);
                    max-width: 90%;
                    width: 420px;
                }}
                .logo {{
                    font-size: 24px;
                    font-weight: bold;
                    margin-bottom: 20px;
                    color: #333;
                }}
                .title {{
                    font-size: 22px;
                    margin-bottom: 16px;
                }}
                .message {{
                    font-size: 16px;
                    margin-bottom: 30px;
                    color: #666;
                    line-height: 1.5;
                }}
                .button {{
                    background-color: #333;
                    color: white;
                    border: none;
                    padding: 12px 24px;
                    font-size: 16px;
                    border-radius: 24px;
                    cursor: pointer;
                    font-weight: 500;
                    text-decoration: none;
                    display: inline-block;
                }}
                .tip {{
                    margin-top: 20px;
                    font-size: 14px;
                    color: #999;
                }}
            </style>
        </head>
        <body>
            <div class="container">
                <div class="logo">途乐乐</div>
                <h1 class="title">您收到一个行程邀请</h1>
                <p class="message">请在途乐乐App中查看和接受邀请。<br>邀请码: <strong>{invitation_code}</strong></p>
                <a href="tulele://invite/{invitation_code}" class="button">打开APP</a>
                <p class="tip">如果按钮无效，请确保已安装途乐乐App</p>
            </div>
        </body>
        </html>
        '''
        return html
    
    # 初始化MongoDB索引
    with app.app_context():
        from .utils.mongo_utils import init_mongo_indexes
        init_mongo_indexes(mongo)
    
    return app