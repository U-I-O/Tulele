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
    
    # 初始化MongoDB索引
    with app.app_context():
        from .utils.mongo_utils import init_mongo_indexes
        init_mongo_indexes(mongo)
    
    return app
