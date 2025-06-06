#!/bin/bash
echo "重启后端服务器..."
echo "停止当前运行的服务器进程..."
pkill -f "python run.py" || echo "没有找到运行中的服务器进程"
echo "启动新服务器..."
cd "$(dirname "$0")" # 切换到脚本所在目录
nohup python run.py > server.log 2>&1 &
echo "服务器已在后台启动，查看日志请使用: tail -f server.log"
echo "完成！" 